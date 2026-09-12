#!/usr/bin/env python3
"""Register InstaFreeSettings activity in AndroidManifest.xml.

Handles both text XML and binary AXML manifests.
- Text XML: modifies in place (inserts <activity> before </application>).
- Binary AXML: uses axml_patcher to inject into the binary directly.
"""
import sys
import os

from axml_patcher import patch_manifest as patch_binary_manifest


def _is_text_xml(data: bytes) -> bool:
    """Check if data is a text XML manifest (not binary AXML)."""
    try:
        text = data.decode('utf-8')
        return '<manifest' in text
    except (UnicodeDecodeError, ValueError):
        return False


def _patch_text_manifest(manifest_path: str, content: str) -> bool:
    """Patch a text XML manifest by inserting the activity tag."""
    if 'InstaFreeSettings' in content:
        print("  Already patched: AndroidManifest.xml")
        return True

    activity_tag = '''
        <activity
            android:name="com.instafree.InstaFreeSettings"
            android:label="InstaFree"
            android:exported="false"
            android:theme="@android:style/Theme.DeviceDefault" />
        <activity-alias
            android:name="com.instafree.InstaFreeSettingsLauncher"
            android:label="InstaFree Settings"
            android:targetActivity="com.instafree.InstaFreeSettings"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity-alias>'''

    if '</application>' not in content:
        print("  Error: </application> not found in manifest")
        return False

    content = content.replace(
        '</application>',
        activity_tag + '\n    </application>'
    )

    with open(manifest_path, 'w') as f:
        f.write(content)
    print("  Registered InstaFreeSettings in AndroidManifest.xml")
    return True


def _patch_binary_axml(manifest_path: str, data: bytes) -> bool:
    """Patch a binary AXML manifest using the binary patcher."""
    try:
        patched = patch_binary_manifest(data, add_launcher=True)
        with open(manifest_path, 'wb') as f:
            f.write(patched)
        print("  Registered InstaFreeSettings in AndroidManifest.xml (binary AXML)")
        return True
    except Exception as e:
        print(f"  Error patching binary manifest: {e}")
        return False


def patch_manifest(manifest_path: str) -> bool:
    with open(manifest_path, 'rb') as f:
        data = f.read()

    if _is_text_xml(data):
        return _patch_text_manifest(manifest_path, data.decode('utf-8'))
    else:
        return _patch_binary_axml(manifest_path, data)


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: patch_manifest.py <AndroidManifest.xml>")
        sys.exit(1)
    if not patch_manifest(sys.argv[1]):
        sys.exit(1)
