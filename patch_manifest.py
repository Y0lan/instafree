#!/usr/bin/env python3
"""Register InstaFreeSettings activity in AndroidManifest.xml."""
import sys

def patch_manifest(manifest_path):
    with open(manifest_path, 'r') as f:
        content = f.read()

    if 'InstaFreeSettings' in content:
        print("  Already patched: AndroidManifest.xml")
        return True

    # Insert before closing </application> tag
    activity_tag = '''
        <activity
            android:name="com.instafree.InstaFreeSettings"
            android:label="InstaFree"
            android:exported="false"
            android:theme="@android:style/Theme.DeviceDefault" />'''

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

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: patch_manifest.py <AndroidManifest.xml>")
        sys.exit(1)
    if not patch_manifest(sys.argv[1]):
        sys.exit(1)
