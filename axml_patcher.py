#!/usr/bin/env python3
"""
Binary AXML manifest patcher.

Parses Android binary XML (AXML), injects new elements, and rebuilds the binary.
Used to add activity/activity-alias entries to the manifest when apktool's
--no-res mode keeps the manifest in binary form.
"""
import struct
import io

# Chunk types
CHUNK_AXML = 0x0003
CHUNK_STRING_POOL = 0x0001
CHUNK_RESOURCE_IDS = 0x0180
CHUNK_START_NAMESPACE = 0x0100
CHUNK_END_NAMESPACE = 0x0101
CHUNK_START_TAG = 0x0102
CHUNK_END_TAG = 0x0103

# Attribute value types
TYPE_NULL = 0x00
TYPE_REFERENCE = 0x01
TYPE_STRING = 0x03
TYPE_INT_DEC = 0x10
TYPE_INT_HEX = 0x11
TYPE_INT_BOOLEAN = 0x12

# Well-known android attribute resource IDs
ATTR_NAME = 0x01010003
ATTR_LABEL = 0x01010001
ATTR_EXPORTED = 0x01010010
ATTR_THEME = 0x01010000
ATTR_TARGET_ACTIVITY = 0x01010202

# Framework theme reference: @android:style/Theme.DeviceDefault
THEME_DEVICE_DEFAULT = 0x01030128

NO_COMMENT = 0xFFFFFFFF


class AXMLPatcher:
    """Parse, modify, and rebuild binary AXML manifests."""

    def __init__(self, data: bytes):
        self.data = data
        self.strings = []
        self.string_flags = 0
        self.res_ids = []
        self.events = []  # list of (type, raw_bytes) before parsing
        self._parse()

    def _parse(self):
        r = io.BytesIO(self.data)

        # Main AXML header
        axml_type, axml_hdr_size, axml_size = struct.unpack('<HHI', r.read(8))
        assert axml_type == CHUNK_AXML, f"Not AXML: {axml_type:#x}"

        # Read chunks
        while r.tell() < axml_size:
            pos = r.tell()
            chunk_type, chunk_hdr_size, chunk_size = struct.unpack('<HHI', r.read(8))

            if chunk_type == CHUNK_STRING_POOL:
                self._parse_string_pool(r, pos, chunk_hdr_size, chunk_size)
            elif chunk_type == CHUNK_RESOURCE_IDS:
                count = (chunk_size - 8) // 4
                self.res_ids = list(struct.unpack(f'<{count}I', r.read(count * 4)))
            elif chunk_type in (CHUNK_START_NAMESPACE, CHUNK_END_NAMESPACE,
                                CHUNK_START_TAG, CHUNK_END_TAG):
                # Store raw event data (minus the 8-byte header we already read)
                event_data = r.read(chunk_size - 8)
                self.events.append((chunk_type, chunk_hdr_size, event_data))
            else:
                # Skip unknown chunks
                r.read(chunk_size - 8)

            r.seek(pos + chunk_size)

    def _parse_string_pool(self, r, pool_start, hdr_size, chunk_size):
        # String pool header (after the 8-byte chunk header we already read)
        string_count, style_count, flags, strings_start, styles_start = \
            struct.unpack('<IIIII', r.read(20))
        self.string_flags = flags

        is_utf8 = bool(flags & (1 << 8))

        # String offsets
        offsets = list(struct.unpack(f'<{string_count}I', r.read(string_count * 4)))
        # Skip style offsets
        if style_count:
            r.read(style_count * 4)

        # Absolute position where string data starts
        str_data_start = pool_start + strings_start

        self.strings = []
        for i in range(string_count):
            pos = str_data_start + offsets[i]
            r.seek(pos)
            if is_utf8:
                s = self._read_utf8_string(r)
            else:
                s = self._read_utf16_string(r)
            self.strings.append(s)

    def _read_utf8_string(self, r):
        # UTF-8 string: char_len (1 or 2 bytes), byte_len (1 or 2 bytes), data, null
        char_len = self._read_len8(r)
        byte_len = self._read_len8(r)
        data = r.read(byte_len)
        r.read(1)  # null terminator
        return data.decode('utf-8', errors='replace')

    def _read_len8(self, r):
        b = struct.unpack('B', r.read(1))[0]
        if b & 0x80:
            b2 = struct.unpack('B', r.read(1))[0]
            return ((b & 0x7F) << 8) | b2
        return b

    def _read_utf16_string(self, r):
        char_len = struct.unpack('<H', r.read(2))[0]
        if char_len & 0x8000:
            char_len2 = struct.unpack('<H', r.read(2))[0]
            char_len = ((char_len & 0x7FFF) << 16) | char_len2
        data = r.read(char_len * 2)
        r.read(2)  # null terminator
        return data.decode('utf-16-le', errors='replace')

    def _get_or_add_string(self, s):
        """Get existing string index or add new string to pool."""
        try:
            return self.strings.index(s)
        except ValueError:
            idx = len(self.strings)
            self.strings.append(s)
            return idx

    def _find_attr_string_idx(self, res_id):
        """Find the string index for an attribute by its resource ID."""
        try:
            idx = self.res_ids.index(res_id)
            return idx
        except ValueError:
            return None

    def _find_end_tag(self, tag_name, occurrence=-1):
        """Find the event index of an END_TAG for the given tag name.
        occurrence=-1 means last occurrence."""
        tag_idx = self._get_or_add_string(tag_name)
        matches = []
        for i, (etype, ehdr, edata) in enumerate(self.events):
            if etype == CHUNK_END_TAG:
                # End tag: line(4) + comment(4) + ns(4) + name(4)
                _, _, _, name = struct.unpack('<IIII', edata[:16])
                if name == tag_idx:
                    matches.append(i)
        if not matches:
            return None
        return matches[occurrence]

    def _make_start_tag(self, ns_idx, name_idx, attributes, line=999):
        """Build a START_TAG event.
        attributes: list of (ns_idx, name_idx, raw_value_idx, value_type, value_data)
        """
        attr_count = len(attributes)
        # Fixed part: line(4) + comment(4) + ns(4) + name(4) +
        #             attr_start(2) + attr_size(2) + attr_count(2) +
        #             id_idx(2) + class_idx(2) + style_idx(2)
        fixed = struct.pack('<IIII HHH HHH',
                            line, NO_COMMENT, ns_idx, name_idx,
                            0x0014, 0x0014, attr_count,
                            0, 0, 0)

        # Each attribute: ns(4) + name(4) + raw_value(4) + value_size(2) + res0(1) + type(1) + data(4)
        attr_bytes = b''
        for a_ns, a_name, a_raw, a_type, a_data in attributes:
            attr_bytes += struct.pack('<III HBB I',
                                     a_ns, a_name, a_raw,
                                     8, 0, a_type, a_data)

        return fixed + attr_bytes

    def _make_end_tag(self, ns_idx, name_idx, line=999):
        """Build an END_TAG event."""
        return struct.pack('<IIII', line, NO_COMMENT, ns_idx, name_idx)

    def inject_activity(self, class_name, label, exported=False,
                        theme_ref=THEME_DEVICE_DEFAULT):
        """Inject an <activity> element before </application>."""
        app_end = self._find_end_tag('application')
        if app_end is None:
            raise ValueError("Could not find </application> end tag")

        # Get/create string indices
        name_val_idx = self._get_or_add_string(class_name)
        label_val_idx = self._get_or_add_string(label)

        # Find attribute name string indices (these map to android: attributes)
        name_attr = self._find_attr_string_idx(ATTR_NAME)
        label_attr = self._find_attr_string_idx(ATTR_LABEL)
        exported_attr = self._find_attr_string_idx(ATTR_EXPORTED)
        theme_attr = self._find_attr_string_idx(ATTR_THEME)

        if None in (name_attr, label_attr, exported_attr, theme_attr):
            raise ValueError(
                f"Missing attribute in resource ID table: "
                f"name={name_attr} label={label_attr} "
                f"exported={exported_attr} theme={theme_attr}")

        # Get namespace index for android:
        android_ns = self._get_or_add_string(
            'http://schemas.android.com/apk/res/android')

        # Build activity element name
        activity_name_idx = self._get_or_add_string('activity')

        # Attributes: (ns, name, raw_value, type, data)
        attrs = [
            (android_ns, name_attr, name_val_idx, TYPE_STRING, name_val_idx),
            (android_ns, label_attr, label_val_idx, TYPE_STRING, label_val_idx),
            (android_ns, exported_attr, 0xFFFFFFFF, TYPE_INT_BOOLEAN,
             0xFFFFFFFF if exported else 0x00000000),
            (android_ns, theme_attr, 0xFFFFFFFF, TYPE_REFERENCE, theme_ref),
        ]
        # Sort attributes by resource ID (Android requires this)
        attrs.sort(key=lambda a: self.res_ids[a[1]] if a[1] < len(self.res_ids) else 0xFFFFFFFF)

        start_data = self._make_start_tag(0xFFFFFFFF, activity_name_idx, attrs)
        end_data = self._make_end_tag(0xFFFFFFFF, activity_name_idx)

        # Insert before </application>
        self.events.insert(app_end, (CHUNK_END_TAG, 16, end_data))
        self.events.insert(app_end, (CHUNK_START_TAG, 16, start_data))

    def inject_activity_alias(self, alias_name, label, target_activity,
                              exported=True):
        """Inject an <activity-alias> with MAIN/LAUNCHER intent-filter."""
        app_end = self._find_end_tag('application')
        if app_end is None:
            raise ValueError("Could not find </application> end tag")

        android_ns = self._get_or_add_string(
            'http://schemas.android.com/apk/res/android')

        # String indices
        alias_tag_idx = self._get_or_add_string('activity-alias')
        filter_tag_idx = self._get_or_add_string('intent-filter')
        action_tag_idx = self._get_or_add_string('action')
        category_tag_idx = self._get_or_add_string('category')

        alias_name_val = self._get_or_add_string(alias_name)
        label_val = self._get_or_add_string(label)
        target_val = self._get_or_add_string(target_activity)
        action_val = self._get_or_add_string('android.intent.action.MAIN')
        category_val = self._get_or_add_string(
            'android.intent.category.LAUNCHER')

        # Attribute name indices
        name_attr = self._find_attr_string_idx(ATTR_NAME)
        label_attr = self._find_attr_string_idx(ATTR_LABEL)
        target_attr = self._find_attr_string_idx(ATTR_TARGET_ACTIVITY)
        exported_attr = self._find_attr_string_idx(ATTR_EXPORTED)

        if None in (name_attr, label_attr, target_attr, exported_attr):
            raise ValueError(
                f"Missing attribute in resource ID table: "
                f"name={name_attr} label={label_attr} "
                f"target={target_attr} exported={exported_attr}")

        # Build events in reverse order (we insert at the same position)
        events_to_insert = []

        # <activity-alias>
        alias_attrs = [
            (android_ns, name_attr, alias_name_val, TYPE_STRING, alias_name_val),
            (android_ns, label_attr, label_val, TYPE_STRING, label_val),
            (android_ns, target_attr, target_val, TYPE_STRING, target_val),
            (android_ns, exported_attr, 0xFFFFFFFF, TYPE_INT_BOOLEAN,
             0xFFFFFFFF if exported else 0x00000000),
        ]
        alias_attrs.sort(
            key=lambda a: self.res_ids[a[1]] if a[1] < len(self.res_ids) else 0xFFFFFFFF)
        events_to_insert.append(
            (CHUNK_START_TAG, 16,
             self._make_start_tag(0xFFFFFFFF, alias_tag_idx, alias_attrs)))

        #   <intent-filter>
        events_to_insert.append(
            (CHUNK_START_TAG, 16,
             self._make_start_tag(0xFFFFFFFF, filter_tag_idx, [])))

        #     <action android:name="android.intent.action.MAIN" />
        action_attrs = [
            (android_ns, name_attr, action_val, TYPE_STRING, action_val),
        ]
        events_to_insert.append(
            (CHUNK_START_TAG, 16,
             self._make_start_tag(0xFFFFFFFF, action_tag_idx, action_attrs)))
        events_to_insert.append(
            (CHUNK_END_TAG, 16,
             self._make_end_tag(0xFFFFFFFF, action_tag_idx)))

        #     <category android:name="android.intent.category.LAUNCHER" />
        cat_attrs = [
            (android_ns, name_attr, category_val, TYPE_STRING, category_val),
        ]
        events_to_insert.append(
            (CHUNK_START_TAG, 16,
             self._make_start_tag(0xFFFFFFFF, category_tag_idx, cat_attrs)))
        events_to_insert.append(
            (CHUNK_END_TAG, 16,
             self._make_end_tag(0xFFFFFFFF, category_tag_idx)))

        #   </intent-filter>
        events_to_insert.append(
            (CHUNK_END_TAG, 16,
             self._make_end_tag(0xFFFFFFFF, filter_tag_idx)))

        # </activity-alias>
        events_to_insert.append(
            (CHUNK_END_TAG, 16,
             self._make_end_tag(0xFFFFFFFF, alias_tag_idx)))

        # Insert all events before </application>
        for i, evt in enumerate(events_to_insert):
            self.events.insert(app_end + i, evt)

    def has_string(self, s):
        """Check if a string exists in the string pool."""
        return s in self.strings

    def build(self) -> bytes:
        """Rebuild the complete binary AXML."""
        # Build string pool
        string_pool = self._build_string_pool()
        # Build resource ID table
        res_id_chunk = self._build_res_ids()
        # Build XML events
        events_data = self._build_events()

        total_size = 8 + len(string_pool) + len(res_id_chunk) + len(events_data)

        # Main AXML header
        header = struct.pack('<HHI', CHUNK_AXML, 8, total_size)
        return header + string_pool + res_id_chunk + events_data

    def _build_string_pool(self) -> bytes:
        is_utf8 = bool(self.string_flags & (1 << 8))

        # Encode all strings
        encoded = []
        for s in self.strings:
            if is_utf8:
                encoded.append(self._encode_utf8_string(s))
            else:
                encoded.append(self._encode_utf16_string(s))

        string_count = len(self.strings)
        style_count = 0

        # Calculate offsets
        offsets = []
        offset = 0
        for enc in encoded:
            offsets.append(offset)
            offset += len(enc)

        # String data
        string_data = b''.join(encoded)

        # Pad string data to 4-byte boundary
        while len(string_data) % 4 != 0:
            string_data += b'\x00'

        # Header: type(2) + header_size(2) + chunk_size(4) +
        #         string_count(4) + style_count(4) + flags(4) +
        #         strings_start(4) + styles_start(4)
        header_size = 28
        offsets_size = string_count * 4
        strings_start = header_size + offsets_size
        chunk_size = strings_start + len(string_data)

        header = struct.pack('<HHI IIIII',
                             CHUNK_STRING_POOL, header_size, chunk_size,
                             string_count, style_count, self.string_flags,
                             strings_start, 0)

        offsets_data = struct.pack(f'<{string_count}I', *offsets)

        return header + offsets_data + string_data

    def _encode_utf8_string(self, s):
        utf8_bytes = s.encode('utf-8')
        char_len = len(s)
        byte_len = len(utf8_bytes)

        result = bytearray()
        # Char length (1 or 2 bytes)
        if char_len > 127:
            result.append(0x80 | (char_len >> 8))
            result.append(char_len & 0xFF)
        else:
            result.append(char_len)
        # Byte length (1 or 2 bytes)
        if byte_len > 127:
            result.append(0x80 | (byte_len >> 8))
            result.append(byte_len & 0xFF)
        else:
            result.append(byte_len)
        result.extend(utf8_bytes)
        result.append(0)  # null terminator
        return bytes(result)

    def _encode_utf16_string(self, s):
        utf16_bytes = s.encode('utf-16-le')
        char_len = len(s)

        result = bytearray()
        if char_len > 0x7FFF:
            result.extend(struct.pack('<H', 0x8000 | (char_len >> 16)))
            result.extend(struct.pack('<H', char_len & 0xFFFF))
        else:
            result.extend(struct.pack('<H', char_len))
        result.extend(utf16_bytes)
        result.extend(b'\x00\x00')  # null terminator
        return bytes(result)

    def _build_res_ids(self) -> bytes:
        if not self.res_ids:
            return b''
        count = len(self.res_ids)
        data = struct.pack(f'<{count}I', *self.res_ids)
        header = struct.pack('<HHI', CHUNK_RESOURCE_IDS, 8, 8 + len(data))
        return header + data

    def _build_events(self) -> bytes:
        result = bytearray()
        for etype, ehdr_size, edata in self.events:
            chunk_size = 8 + len(edata)
            result.extend(struct.pack('<HHI', etype, ehdr_size, chunk_size))
            result.extend(edata)
        return bytes(result)


def patch_manifest(manifest_data: bytes,
                   activity_class: str = 'com.instafree.InstaFreeSettings',
                   activity_label: str = 'InstaFree',
                   add_launcher: bool = True) -> bytes:
    """Patch a binary AXML manifest to add InstaFree activity entries.

    Args:
        manifest_data: Raw binary AXML manifest bytes
        activity_class: Fully qualified activity class name
        activity_label: Human-readable label
        add_launcher: Also add a launcher shortcut (activity-alias)

    Returns:
        Modified binary AXML manifest bytes
    """
    patcher = AXMLPatcher(manifest_data)

    alias_name = 'com.instafree.InstaFreeSettingsLauncher'
    has_activity = patcher.has_string(activity_class)
    has_alias = patcher.has_string(alias_name)

    if has_activity and (has_alias or not add_launcher):
        print("  Already patched: manifest contains InstaFreeSettings")
        return manifest_data

    # Add the activity (if not already present)
    if not has_activity:
        patcher.inject_activity(
            class_name=activity_class,
            label=activity_label,
            exported=False,
            theme_ref=THEME_DEVICE_DEFAULT,
        )

    # Add launcher alias (if requested and not already present)
    if add_launcher and not has_alias:
        patcher.inject_activity_alias(
            alias_name=alias_name,
            label='InstaFree Settings',
            target_activity=activity_class,
            exported=True,
        )

    return patcher.build()


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 2:
        print("Usage: axml_patcher.py <AndroidManifest.xml>")
        sys.exit(1)

    with open(sys.argv[1], 'rb') as f:
        data = f.read()

    patched = patch_manifest(data)

    with open(sys.argv[1], 'wb') as f:
        f.write(patched)

    print(f"  Patched binary manifest: {sys.argv[1]}")
    print(f"    Original size: {len(data)} bytes")
    print(f"    Patched size: {len(patched)} bytes")
