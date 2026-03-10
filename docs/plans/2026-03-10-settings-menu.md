# Settings Menu Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an in-app settings menu to InstaFree that lets users toggle content blocking (feed/stories/reels) and configure tab navigation (default page, reels redirect, feed redirect) at runtime.

**Architecture:** Replace hardcoded smali booleans with SharedPreferences-backed config. Inject a PreferenceActivity into the APK accessible from Instagram's settings page. Replace the static `global_redirect.py` string replacement with runtime fragment resolution via `InstaFreeRedirect.resolveFragment()`.

**Tech Stack:** Smali (Dalvik bytecode), Python (patching scripts), Android PreferenceActivity API, SharedPreferences

---

### Task 1: Download dove icon

**Files:**
- Create: `patches/instafree_icon.png`

**Step 1:** Download the dove icon from flaticon (the PNG version, 128x128 or 64x64). Save it to `patches/instafree_icon.png`.

**Step 2:** Commit
```bash
git add patches/instafree_icon.png
git commit -m "feat: add dove icon for settings menu"
```

---

### Task 2: Rewrite InstaFreeConfig.smali with SharedPreferences

The current `InstaFreeConfig.smali` has a single hardcoded `isFeedDisabled()` method. Rewrite it to:
- Cache app Context via `init(Context)`
- Read all settings from SharedPreferences
- Provide getter methods for each configurable value

**Files:**
- Modify: `patches/InstaFreeConfig.smali`

**Step 1:** Replace `patches/InstaFreeConfig.smali` with:

```java
// JAVA REFERENCE (for understanding — actual file is smali below)
public class InstaFreeConfig {
    private static Context appContext;
    private static final String PREFS_NAME = "instafree_prefs";

    public static void init(Context ctx) {
        appContext = ctx.getApplicationContext();
    }

    private static SharedPreferences getPrefs() {
        return appContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public static boolean isFeedDisabled() {
        if (appContext == null) return true;
        return getPrefs().getBoolean("feed_disabled", true);
    }

    public static boolean isStoriesDisabled() {
        if (appContext == null) return true;
        return getPrefs().getBoolean("stories_disabled", true);
    }

    public static boolean isReelsDisabled() {
        if (appContext == null) return true;
        return getPrefs().getBoolean("reels_disabled", true);
    }

    public static String getDefaultPage() {
        if (appContext == null) return "fragment_profile";
        return getPrefs().getString("default_page", "fragment_profile");
    }

    public static String getReelsRedirect() {
        if (appContext == null) return "fragment_direct_tab";
        return getPrefs().getString("reels_redirect", "fragment_direct_tab");
    }

    public static String getFeedRedirect() {
        if (appContext == null) return "fragment_feed";
        return getPrefs().getString("feed_redirect", "fragment_feed");
    }
}
```

Write the full smali equivalent. Key patterns:
- `appContext` is a static field: `.field private static appContext:Landroid/content/Context;`
- `init()` stores context: `sput-object` to the static field
- Each getter: `sget-object` to check null, then `getSharedPreferences()` → `getBoolean()`/`getString()`
- Use `.locals 3` for most methods (result, key string, default value)

**Step 2:** Verify the smali compiles by running the full build (Task 10).

**Step 3:** Commit
```bash
git add patches/InstaFreeConfig.smali
git commit -m "feat: rewrite InstaFreeConfig with SharedPreferences"
```

---

### Task 3: Write InstaFreeRedirect.smali

New class that resolves fragment names at runtime based on user preferences.

**Files:**
- Create: `patches/InstaFreeRedirect.smali`

**Step 1:** Write `patches/InstaFreeRedirect.smali`:

```java
// JAVA REFERENCE
public class InstaFreeRedirect {
    public static String resolveFragment(String original) {
        if ("fragment_clips".equals(original)) {
            return InstaFreeConfig.getReelsRedirect();
        }
        if ("fragment_feed".equals(original)) {
            return InstaFreeConfig.getFeedRedirect();
        }
        return original;
    }

    public static String getDefaultFragment() {
        return InstaFreeConfig.getDefaultPage();
    }
}
```

Smali implementation:
- Class: `Lcom/instafree/InstaFreeRedirect;`
- `resolveFragment(Ljava/lang/String;)Ljava/lang/String;` — compares input with `"fragment_clips"` and `"fragment_feed"`, returns configured redirect or original
- `getDefaultFragment()Ljava/lang/String;` — delegates to `InstaFreeConfig.getDefaultPage()`
- Use `.locals 2` for resolveFragment (comparison string + result)

**Step 2:** Commit
```bash
git add patches/InstaFreeRedirect.smali
git commit -m "feat: add InstaFreeRedirect for runtime fragment resolution"
```

---

### Task 4: Update InstaFreeHooks.smali for conditional blocking

Modify `throwIfBlocked()` to check `InstaFreeConfig` before blocking each endpoint.

**Files:**
- Modify: `patches/InstaFreeHooks.smali`

**Step 1:** Update `throwIfBlocked()` logic:

```java
// JAVA REFERENCE
public static void throwIfBlocked(URI uri) {
    logRequest(uri);
    String path = uri.getPath();
    if (path == null) return;

    // Feed — conditional
    if (InstaFreeConfig.isFeedDisabled() && path.contains("/feed/timeline/")) {
        block();
    }
    // Explore — always blocked (no toggle)
    if (path.contains("/discover/topical_explore")) {
        block();
    }
    // Reels — conditional
    if (InstaFreeConfig.isReelsDisabled() && path.contains("/clips/discover")) {
        block();
    }
    // Stories tray — conditional
    if (InstaFreeConfig.isStoriesDisabled() && path.contains("/feed/reels_tray/")) {
        block();
    }
}
```

Smali changes to each blocking section:
- Before each `path.contains()` check (except explore), add:
  ```smali
  invoke-static {}, Lcom/instafree/InstaFreeConfig;->isFeedDisabled()Z
  move-result v2
  if-eqz v2, :skip_feed
  ```
- Add corresponding `:skip_feed`, `:skip_reels`, `:skip_stories` labels
- Explore block stays unconditional
- Update log tag to "InstaFree"
- Increase `.locals` as needed

**Step 2:** Commit
```bash
git add patches/InstaFreeHooks.smali
git commit -m "feat: make InstaFreeHooks conditional based on config"
```

---

### Task 5: Write InstaFreeSettings.smali

A `PreferenceActivity` with programmatically created preferences. No XML resources needed.

**Files:**
- Create: `patches/InstaFreeSettings.smali`

**Step 1:** Write `patches/InstaFreeSettings.smali`:

```java
// JAVA REFERENCE
public class InstaFreeSettings extends android.preference.PreferenceActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getPreferenceManager().setSharedPreferencesName("instafree_prefs");

        PreferenceScreen screen = getPreferenceManager().createPreferenceScreen(this);

        // -- Content Blocking --
        PreferenceCategory blocking = new PreferenceCategory(this);
        blocking.setTitle("Content Blocking");
        screen.addPreference(blocking);

        addSwitch(blocking, "feed_disabled", "Feed Posts",
                  "Block the homepage feed posts", true);
        addSwitch(blocking, "stories_disabled", "Stories Tray",
                  "Block the stories tray on homepage", true);
        addSwitch(blocking, "reels_disabled", "Reels Content",
                  "Block reels discovery content", true);

        // -- Navigation --
        PreferenceCategory nav = new PreferenceCategory(this);
        nav.setTitle("Navigation");
        screen.addPreference(nav);

        addList(nav, "default_page", "Default Page",
                "Page shown when opening Instagram",
                new String[]{"Profile", "DM", "Search", "Feed"},
                new String[]{"fragment_profile", "fragment_direct_tab",
                             "fragment_search", "fragment_feed"},
                "fragment_profile");

        addList(nav, "reels_redirect", "Reels Tab",
                "Where the Reels tab redirects to",
                new String[]{"DM", "Search", "Profile"},
                new String[]{"fragment_direct_tab", "fragment_search",
                             "fragment_profile"},
                "fragment_direct_tab");

        addList(nav, "feed_redirect", "Feed Tab",
                "Where the Feed tab redirects to",
                new String[]{"Feed (empty)", "DM", "Search", "Profile"},
                new String[]{"fragment_feed", "fragment_direct_tab",
                             "fragment_search", "fragment_profile"},
                "fragment_feed");

        setPreferenceScreen(screen);
    }

    private void addSwitch(PreferenceCategory cat, String key,
                           String title, String summary, boolean def) {
        SwitchPreference p = new SwitchPreference(this);
        p.setKey(key); p.setTitle(title); p.setSummary(summary);
        p.setDefaultValue(def);
        cat.addPreference(p);
    }

    private void addList(PreferenceCategory cat, String key,
                         String title, String summary,
                         String[] labels, String[] values, String def) {
        ListPreference p = new ListPreference(this);
        p.setKey(key); p.setTitle(title); p.setSummary(summary);
        p.setEntries(labels); p.setEntryValues(values);
        p.setDefaultValue(def);
        cat.addPreference(p);
    }
}
```

Smali implementation notes:
- Class extends `Landroid/preference/PreferenceActivity;`
- `onCreate`: ~200 lines — create PreferenceScreen, add categories, add 3 SwitchPreferences + 3 ListPreferences
- Helper methods `addSwitch` and `addList` reduce repetition
- For ListPreference: create `[Ljava/lang/CharSequence;` arrays with `new-array` + `aput-object` for entries/entryValues
- Use `SwitchPreference` from `android.preference` package (deprecated but functional)
- `.locals` count varies: onCreate needs ~8, helpers need ~3

**Step 2:** Commit
```bash
git add patches/InstaFreeSettings.smali
git commit -m "feat: add InstaFreeSettings PreferenceActivity"
```

---

### Task 6: Rewrite global_redirect.py for runtime redirects

Replace the static string substitution with runtime method injection.

**Files:**
- Modify: `global_redirect.py`

**Step 1:** Rewrite `global_redirect.py`:

```python
#!/usr/bin/env python3
"""
Inject InstaFreeRedirect.resolveFragment() calls after fragment string constants.

Instead of statically replacing "fragment_clips" with "fragment_direct_tab",
this injects a runtime method call that reads the user's configured redirect
from SharedPreferences.
"""
import os
import sys
import re

REDIRECT_FRAGMENTS = ['"fragment_clips"', '"fragment_feed"']

def inject_redirect(directory):
    """Find const-string lines loading redirect-able fragments and inject
    a call to InstaFreeRedirect.resolveFragment() after each one."""
    # Pattern matches: const-string or const-string/jumbo vN, "fragment_clips"
    pattern = re.compile(
        r'([ \t]*const-string(?:/jumbo)?\s+(v\d+),\s*'
        r'("fragment_clips"|"fragment_feed")\s*\n)'
    )
    count = 0
    for root, dirs, files in os.walk(directory):
        # Skip our own injected classes
        if 'com/instafree' in root:
            continue
        for fname in files:
            if not fname.endswith('.smali'):
                continue
            path = os.path.join(root, fname)
            with open(path, 'r') as f:
                content = f.read()

            if 'InstaFreeRedirect' in content:
                continue  # already patched

            new_content = content
            for match in reversed(list(pattern.finditer(content))):
                original_line = match.group(1)
                register = match.group(2)
                indent = re.match(r'([ \t]*)', original_line).group(1)
                inject = (
                    f'{indent}invoke-static {{{register}}}, '
                    f'Lcom/instafree/InstaFreeRedirect;->'
                    f'resolveFragment(Ljava/lang/String;)'
                    f'Ljava/lang/String;\n'
                    f'{indent}move-result-object {register}\n'
                )
                insert_pos = match.end()
                new_content = (new_content[:insert_pos]
                               + inject
                               + new_content[insert_pos:])
                count += 1

            if new_content != content:
                with open(path, 'w') as f:
                    f.write(new_content)

    print(f"Injected {count} runtime redirect calls.")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: global_redirect.py <decompiled_dir>")
        sys.exit(1)
    inject_redirect(sys.argv[1])
```

**Step 2:** Verify by running `python3 global_redirect.py instagram_source` on a fresh decompile and checking the output count matches (should be ~10 injections for fragment_clips, plus any fragment_feed occurrences).

**Step 3:** Commit
```bash
git add global_redirect.py
git commit -m "feat: rewrite global_redirect for runtime fragment resolution"
```

---

### Task 7: Write patch_manifest.py

Register `InstaFreeSettings` activity in AndroidManifest.xml.

**Files:**
- Create: `patch_manifest.py`

**Step 1:** Write `patch_manifest.py`:

```python
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
            android:exported="true"
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
```

**Step 2:** Commit
```bash
git add patch_manifest.py
git commit -m "feat: add manifest patcher for InstaFreeSettings activity"
```

---

### Task 8: Write patch_app_init.py

Patch Instagram's Application class to call `InstaFreeConfig.init(this)` on startup, so SharedPreferences can be accessed from static hooks.

**Files:**
- Create: `patch_app_init.py`

**Step 1:** Write `patch_app_init.py`:

```python
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
```

**Step 2:** Commit
```bash
git add patch_app_init.py
git commit -m "feat: add Application.onCreate patcher for config init"
```

---

### Task 9: Write inject_settings_entry.py

Inject an "InstaFree" entry into Instagram's settings page that launches InstaFreeSettings.

**Files:**
- Create: `inject_settings_entry.py`

**Step 1:** Write `inject_settings_entry.py`:

This is the most fragile part — Instagram's settings are obfuscated. The script uses heuristics:

1. Search AndroidManifest.xml for settings-related activities
2. Find the smali class that builds the settings list
3. Look for patterns like `addPreference` or list adapter `add` calls
4. Inject a new item that launches `com.instafree.InstaFreeSettings`

If automatic injection fails, provide a fallback: add a launcher shortcut via `<activity-alias>` in the manifest, so users can access settings from their home screen app drawer.

```python
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

    if 'instafree_launcher' in content:
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

    # Strategy: Find files that reference known settings-like patterns
    # Instagram's settings items typically reference intent actions or
    # activity class names as strings

    # Look for the settings fragment/activity by searching for files
    # that contain multiple settings-related class references
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
            # Look for files that set up a list/group of preference items
            # These typically have multiple addPreference or add() calls
            # along with Intent creation for launching activities
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

    # Sort by score descending
    candidates.sort(key=lambda x: -x[0])

    # Try the top candidate
    best_score, best_path, best_content = candidates[0]
    print(f"  Settings candidate: {best_path} (score={best_score})")

    # Find the last addPreference call and inject ours after it
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

    # We need to inject code that:
    # 1. Creates a new Preference
    # 2. Sets title to "InstaFree"
    # 3. Sets an intent to launch InstaFreeSettings
    # 4. Adds it to the screen

    # Find the PreferenceScreen/PreferenceGroup register from context
    # Look at the addPreference call to find which register holds the group
    add_match = re.search(
        r'invoke-virtual\s+\{(v\d+),\s*(v\d+)\},\s*'
        r'L([^;]+);->addPreference',
        best_content[last_add-200:last_add]
    )

    if not add_match:
        print("  Could not parse addPreference registers")
        return False

    group_reg = add_match.group(1)

    # Find a free register (use a high number)
    # Also need to find the context register (usually p0)
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
    invoke-virtual {{v1, v2}}, Landroid/content/Intent;->setClassName(Ljava/lang/String;)Landroid/content/Intent;

    invoke-virtual {{v0, v1}}, Landroid/preference/Preference;->setIntent(Landroid/content/Intent;)V

    invoke-virtual {{{group_reg}, v0}}, Landroid/preference/PreferenceGroup;->addPreference(Landroid/preference/Preference;)Z
'''

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
```

**Step 2:** Commit
```bash
git add inject_settings_entry.py
git commit -m "feat: add settings entry injector with launcher fallback"
```

---

### Task 10: Update patch.sh with new steps

Add the new patching steps to the build pipeline.

**Files:**
- Modify: `patch.sh`

**Step 1:** Update `patch.sh` to include:

After step 2 (adding InstaFree classes), add the new smali files:
```bash
cp "$PATCHES_DIR/InstaFreeRedirect.smali" "$WORK_DIR/smali_classes17/com/instafree/"
cp "$PATCHES_DIR/InstaFreeSettings.smali" "$WORK_DIR/smali_classes17/com/instafree/"
```

After step 2, copy dove icon to assets:
```bash
mkdir -p "$WORK_DIR/assets"
cp "$PATCHES_DIR/instafree_icon.png" "$WORK_DIR/assets/"
```

Add new steps (renumber existing 3→4, 4→5, etc.):

**Step 3.5: Patch Application.onCreate for config init**
```bash
python3 "$SCRIPT_DIR/patch_app_init.py" "$WORK_DIR"
```

**Step 4.5: Register activity in manifest**
```bash
python3 "$SCRIPT_DIR/patch_manifest.py" "$WORK_DIR/AndroidManifest.xml"
```

**Step 4.6: Inject settings entry**
```bash
python3 "$SCRIPT_DIR/inject_settings_entry.py" "$WORK_DIR"
```

Update step numbers and total count in the echo messages (now 9 steps instead of 6).

**Step 2:** Commit
```bash
git add patch.sh
git commit -m "feat: update patch.sh with settings menu steps"
```

---

### Task 11: Build, test, and verify

**Step 1:** Clean previous build
```bash
./cleanup.sh
```

**Step 2:** Run full patch
```bash
./patch.sh instagram.apk
```

Expected output: All steps pass, APK is built and signed.

**Step 3:** Install on device
```bash
adb install -r instafree_patched.apk
```

**Step 4:** Manual verification checklist:
- [ ] App opens to Profile page (default)
- [ ] Feed tab shows empty feed (no posts, no stories)
- [ ] Reels tab redirects to DMs
- [ ] Instagram Settings → "InstaFree" entry appears (or launcher shortcut exists)
- [ ] InstaFree settings page opens with all 6 options
- [ ] Toggle "Feed Posts" ON → feed posts appear after app restart
- [ ] Toggle "Stories Tray" ON → stories tray appears after app restart
- [ ] Change "Reels Tab" to "Profile" → reels button goes to profile after app restart
- [ ] Change "Default Page" to "DM" → app opens to DMs after restart

**Step 5:** Commit all remaining changes
```bash
git add -A
git commit -m "feat: complete settings menu implementation"
```

---

## File Summary

| File | Action | Purpose |
|------|--------|---------|
| `patches/InstaFreeConfig.smali` | Rewrite | SharedPreferences-backed config reader |
| `patches/InstaFreeHooks.smali` | Modify | Conditional blocking based on config |
| `patches/InstaFreeRedirect.smali` | Create | Runtime fragment name resolution |
| `patches/InstaFreeSettings.smali` | Create | PreferenceActivity for settings UI |
| `patches/instafree_icon.png` | Create | Dove icon for settings menu entry |
| `global_redirect.py` | Rewrite | Inject runtime redirect calls instead of static replacement |
| `patch_manifest.py` | Create | Register settings Activity in manifest |
| `patch_app_init.py` | Create | Patch Application.onCreate for config init |
| `inject_settings_entry.py` | Create | Inject settings entry into Instagram's settings |
| `patch.sh` | Modify | Add new patching steps |

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Settings injection fails (obfuscated code) | Launcher shortcut fallback auto-added |
| Application class not found | Script searches manifest for `android:name` |
| `global_redirect.py` regex misses edge cases | Test on fresh decompile, compare injection count |
| PreferenceActivity deprecated | Still functional on all Android versions Instagram supports |
| Settings changes need app restart | Add note in settings summary text |
