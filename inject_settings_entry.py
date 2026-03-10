#!/usr/bin/env python3
"""
Inject InstaFree settings entry into Instagram's settings page.

Falls back to adding a launcher shortcut if settings injection fails.
"""
import sys
import os
import re

def add_launcher_shortcut(manifest_path):
    """Fallback: add a launcher activity-alias for InstaFreeSettings."""
    with open(manifest_path, 'r') as f:
        content = f.read()

    if 'InstaFreeSettings' not in content:
        print("  Warning: InstaFreeSettings not in manifest, skipping shortcut")
        return False

    if 'InstaFreeSettingsLauncher' in content:
        print("  Launcher shortcut already exists")
        return True

    alias = '''
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

    content = content.replace(
        '</application>',
        alias + '\n    </application>'
    )

    with open(manifest_path, 'w') as f:
        f.write(content)

    print("  Added InstaFree Settings launcher shortcut (fallback)")
    return True


def inject_into_settings(source_dir):
    """Try to inject a settings entry into Instagram's settings page.
    Returns True if successful, False if fallback is needed."""

    candidates = []
    for root, dirs, files in os.walk(source_dir):
        if 'com/instafree' in root:
            continue
        for fname in files:
            if not fname.endswith('.smali'):
                continue
            path = os.path.join(root, fname)
            with open(path, 'r') as f:
                content = f.read()
            score = 0
            if 'Landroid/preference/Preference' in content:
                score += 3
            if 'addPreference' in content:
                score += 3
            if 'Landroid/content/Intent' in content and score > 0:
                score += 2
            if 'setTitle' in content and score > 0:
                score += 1
            if score >= 6:
                candidates.append((score, path, content))

    if not candidates:
        print("  Could not find settings preference construction code")
        return False

    candidates.sort(key=lambda x: -x[0])

    best_score, best_path, best_content = candidates[0]
    print(f"  Settings candidate: {best_path} (score={best_score})")

    last_add = -1
    for match in re.finditer(
        r'invoke-virtual\s+\{[^}]+\},\s*'
        r'L[^;]+;->addPreference\(Landroid/preference/Preference;\)Z',
        best_content
    ):
        last_add = match.end()

    if last_add == -1:
        print("  Could not find addPreference call in candidate")
        return False

    add_match = re.search(
        r'invoke-virtual\s+\{(v\d+),\s*(v\d+)\},\s*'
        r'L([^;]+);->addPreference',
        best_content[last_add-200:last_add]
    )

    if not add_match:
        print("  Could not parse addPreference registers")
        return False

    group_reg = add_match.group(1)

    inject_code = f'''
    # InstaFree: Add settings entry
    new-instance v0, Landroid/preference/Preference;
    invoke-direct {{v0, p0}}, Landroid/preference/Preference;-><init>(Landroid/content/Context;)V

    const-string v1, "InstaFree"
    invoke-virtual {{v0, v1}}, Landroid/preference/Preference;->setTitle(Ljava/lang/CharSequence;)V

    const-string v1, "Distraction-free settings"
    invoke-virtual {{v0, v1}}, Landroid/preference/Preference;->setSummary(Ljava/lang/CharSequence;)V

    new-instance v1, Landroid/content/Intent;
    invoke-direct {{v1}}, Landroid/content/Intent;-><init>()V
    const-string v2, "com.instafree.InstaFreeSettings"
    invoke-virtual {{v1, p0, v2}}, Landroid/content/Intent;->setClassName(Landroid/content/Context;Ljava/lang/String;)Landroid/content/Intent;

    invoke-virtual {{v0, v1}}, Landroid/preference/Preference;->setIntent(Landroid/content/Intent;)V

    invoke-virtual {{{group_reg}, v0}}, Landroid/preference/PreferenceGroup;->addPreference(Landroid/preference/Preference;)Z
'''

    # Ensure target method has enough registers for our injected code (v0, v1, v2)
    # Find the enclosing method's .locals declaration and bump it if needed
    method_start = best_content.rfind('.method', 0, last_add)
    if method_start != -1:
        locals_match = re.search(r'\.locals\s+(\d+)', best_content[method_start:last_add])
        if locals_match:
            current_locals = int(locals_match.group(1))
            if current_locals < 3:
                locals_pos = method_start + locals_match.start()
                locals_end = method_start + locals_match.end()
                best_content = (best_content[:locals_pos]
                               + f'.locals 3'
                               + best_content[locals_end:])
                print(f"  Bumped .locals from {current_locals} to 3")

    new_content = best_content[:last_add] + '\n' + inject_code + '\n' + best_content[last_add:]

    with open(best_path, 'w') as f:
        f.write(new_content)

    print(f"  Injected InstaFree settings entry into {best_path}")
    return True


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: inject_settings_entry.py <source_dir>")
        sys.exit(1)

    source_dir = sys.argv[1]
    manifest = os.path.join(source_dir, 'AndroidManifest.xml')

    success = inject_into_settings(source_dir)

    if not success:
        print("  Settings injection failed, adding launcher shortcut fallback")
        add_launcher_shortcut(manifest)
