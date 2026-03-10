# InstaFree Settings Menu Design

## Summary

Add a configurable settings menu inside Instagram's Settings page, allowing users to toggle content blocking and customize tab navigation at runtime. Settings persist via SharedPreferences.

## Settings

### Content Blocking

| Setting | Default | Effect |
|---------|---------|--------|
| Feed posts | OFF | Blocks `/feed/timeline/` |
| Stories tray | OFF | Blocks `/feed/reels_tray/` |
| Reels content | OFF | Blocks `/clips/discover` |

### Navigation

| Setting | Default | Options |
|---------|---------|---------|
| Default page | Profile | Profile, DM, Search, Feed |
| Reels tab → | DM | DM, Search, Profile |
| Feed tab → | Feed (empty) | Feed, DM, Search, Profile |

## Architecture

### Files

**New smali classes:**
- `InstaFreeSettings.smali` — PreferenceActivity with toggles and list pickers
- `InstaFreeRedirect.smali` — Reads SharedPreferences to resolve fragment redirections at runtime

**Modified smali classes:**
- `InstaFreeConfig.smali` — Rewritten to read SharedPreferences instead of hardcoded booleans
- `InstaFreeHooks.smali` — `throwIfBlocked()` calls InstaFreeConfig which now checks prefs

**Modified scripts:**
- `global_redirect.py` — Replaced: instead of static string replacement, injects call to `InstaFreeRedirect.resolveFragment()` at each patch point
- `patch.sh` — Additional steps: register Activity in AndroidManifest.xml, inject settings entry, copy dove icon to drawable

### Settings Entry

A new item is injected into Instagram's settings list with:
- **Icon**: Dove (from flaticon, bundled as `res/drawable/instafree_icon.png`)
- **Label**: "InstaFree"
- **Action**: Launches `InstaFreeSettingsActivity`

### Runtime Flow

#### Network blocking
```
TigonServiceLayer → InstaFreeHooks.throwIfBlocked(uri)
  → InstaFreeConfig.isFeedDisabled(context)
    → SharedPreferences.getBoolean("feed_disabled", true)
  → if disabled, throw IOException
```

#### Tab redirection
```
Fragment load → InstaFreeRedirect.resolveFragment(context, originalFragment)
  → if "fragment_clips": return pref("reels_redirect", "fragment_direct_tab")
  → if "fragment_timeline": return pref("feed_redirect", "fragment_timeline")
  → else: return original
```

#### Default opening page
```
Main activity init → InstaFreeRedirect.getDefaultFragment(context)
  → return pref("default_page", "fragment_profile")
```

### Key Constraint: Context Access

SharedPreferences requires an Android `Context`. The current hooks are static methods with no Context parameter. Two options:

**Chosen approach**: Store application Context in a static field at app startup. Patch Instagram's `Application.onCreate()` to call `InstaFreeConfig.init(this)`, which stores the context. All subsequent reads use this cached context.

### Settings UI

Built using `PreferenceActivity` / `PreferenceScreen` API — creates toggle switches and list selectors from code without needing layout XML resources. This avoids the fragility of injecting XML resources into a `--no-res` decompiled APK.

### Manifest Registration

The patcher adds to AndroidManifest.xml:
```xml
<activity
    android:name="com.instafree.InstaFreeSettings"
    android:label="InstaFree"
    android:theme="@style/Theme.AppCompat.DayNight" />
```

## Defaults

Everything blocked out of the box. Profile page on launch. Reels tab goes to DM. Feed tab stays on feed (empty). User can enable features they want back.
