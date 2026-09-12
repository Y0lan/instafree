#!/usr/bin/env python3
"""
Patch Instagram's Application.onCreate() to init InstaFreeConfig.

Reads the application class from the binary (or text) manifest, then injects:

    invoke-static/range {p0 .. p0}, Lcom/instafree/InstaFreeConfig;->init(Landroid/content/Context;)V

right after super.onCreate(). invoke-static/range is required because
InstagramAppShell.onCreate uses a high register for p0.
"""
import os
import re
import sys

from axml_patcher import AXMLPatcher


FALLBACK_SMALI = ('InstagramAppShell.smali',)


def _application_from_manifest(source_dir):
    manifest = os.path.join(source_dir, 'AndroidManifest.xml')
    with open(manifest, 'rb') as f:
        data = f.read()

    try:
        text = data.decode('utf-8')
    except UnicodeDecodeError:
        text = None

    class_name = None
    package = None
    if text and '<manifest' in text:
        match = re.search(r'<application[^>]*android:name="([^"]+)"', text)
        if match:
            class_name = match.group(1)
        pkg = re.search(r'<manifest[^>]*package="([^"]+)"', text)
        if pkg:
            package = pkg.group(1)
    else:
        patcher = AXMLPatcher(data)
        class_name = patcher.get_application_name()
        package = patcher.get_package_name()

    if not class_name:
        return None
    if class_name.startswith('.') and package:
        class_name = package + class_name
    return class_name.replace('.', '/') + '.smali'


def find_application_class(source_dir):
    """Find the Application subclass smali file."""
    smali_path = _application_from_manifest(source_dir)
    if smali_path:
        for root, _dirs, files in os.walk(source_dir):
            for fname in files:
                full = os.path.join(root, fname)
                if full.endswith(smali_path):
                    return full

    for wanted in FALLBACK_SMALI:
        for root, _dirs, files in os.walk(source_dir):
            if wanted in files:
                return os.path.join(root, wanted)
    return None


def patch_app_oncreate(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='surrogateescape') as f:
        content = f.read()

    if 'InstaFreeConfig' in content:
        print(f'  Already patched: {filepath}')
        return True

    oncreate_pattern = re.compile(
        r'(\.method\s+public\s+(?:final\s+)?onCreate\(\)V.*?'
        r'invoke-\w+(?:/range)?\s+\{[^}]*\},[^\n]*onCreate\(\)V\s*\n)',
        re.DOTALL,
    )

    match = oncreate_pattern.search(content)
    if not match:
        print(f'  Error: Could not find onCreate in {filepath}')
        return False

    inject = (
        '\n    # InstaFree: Initialize config with app context\n'
        '    invoke-static/range {p0 .. p0}, Lcom/instafree/InstaFreeConfig;->'
        'init(Landroid/content/Context;)V\n\n'
    )

    insert_pos = match.end()
    content = content[:insert_pos] + inject + content[insert_pos:]

    with open(filepath, 'w', encoding='utf-8', errors='surrogateescape') as f:
        f.write(content)

    print(f'  Patched Application.onCreate: {filepath}')
    return True


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('Usage: patch_app_init.py <source_dir>')
        sys.exit(1)

    app_class = find_application_class(sys.argv[1])
    if not app_class:
        print('  Error: Could not find Application class')
        sys.exit(1)

    print(f'  Found Application class: {app_class}')
    if not patch_app_oncreate(app_class):
        sys.exit(1)
