#!/usr/bin/env python3
"""
Patch Instagram's Application.onCreate() to init InstaFreeConfig.

Searches for the main Application class and injects:
    invoke-static {p0}, Lcom/instafree/InstaFreeConfig;->init(Landroid/content/Context;)V
at the beginning of onCreate().
"""
import sys
import os
import re

def find_application_class(source_dir):
    """Find the Application subclass by checking AndroidManifest.xml."""
    manifest = os.path.join(source_dir, 'AndroidManifest.xml')
    with open(manifest, 'r') as f:
        content = f.read()

    # Find android:name in <application> tag
    match = re.search(r'<application[^>]*android:name="([^"]+)"', content)
    if match:
        class_name = match.group(1)
        # Convert com.instagram.app.InstagramApp to com/instagram/app/InstagramApp
        smali_path = class_name.replace('.', '/') + '.smali'
        # Search in all smali directories
        for root, dirs, files in os.walk(source_dir):
            for fname in files:
                full_path = os.path.join(root, fname)
                if full_path.endswith(smali_path):
                    return full_path
    return None

def patch_app_oncreate(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'InstaFreeConfig' in content:
        print(f"  Already patched: {filepath}")
        return True

    # Find onCreate method and inject after super.onCreate() call
    # Pattern: .method public onCreate()V ... invoke-super ... -> onCreate
    oncreate_pattern = re.compile(
        r'(\.method[^\n]*onCreate\(\)V.*?'
        r'invoke-\w+\s+\{[^}]*\},[^\n]*onCreate\(\)V\s*\n)',
        re.DOTALL
    )

    match = oncreate_pattern.search(content)
    if not match:
        print(f"  Error: Could not find onCreate in {filepath}")
        return False

    inject = (
        '\n    # InstaFree: Initialize config with app context\n'
        '    invoke-static {p0}, Lcom/instafree/InstaFreeConfig;->'
        'init(Landroid/content/Context;)V\n\n'
    )

    insert_pos = match.end()
    content = content[:insert_pos] + inject + content[insert_pos:]

    with open(filepath, 'w') as f:
        f.write(content)

    print(f"  Patched Application.onCreate: {filepath}")
    return True

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: patch_app_init.py <source_dir>")
        sys.exit(1)

    app_class = find_application_class(sys.argv[1])
    if not app_class:
        print("  Error: Could not find Application class")
        sys.exit(1)

    print(f"  Found Application class: {app_class}")
    if not patch_app_oncreate(app_class):
        sys.exit(1)
