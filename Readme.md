<p align="center">
  <img src="docs/app_icon.png" alt="InstaFree Icon" width="128">
</p>

<h1 align="center">InstaFree</h1>
<p align="center">Distraction-Free Instagram</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/Y0lan/instafree?style=for-the-badge&label=Download%20APK&color=10a37f" alt="Download APK">
  </a>
</p>

---

A patching toolkit that removes addictive features from Instagram while keeping essential functionality.

Based on [FeurStagram](https://github.com/jean-voila/FeurStagram) by [jean-voila](https://github.com/jean-voila).

## Installation

You have two options:

1. **Ready-to-install APK** - Grab the latest patched APK from the [Releases](../../releases) page and install it directly
2. **DIY Patching** - Use the toolkit below to patch any Instagram version yourself

## What Gets Disabled

| Feature | Status | How |
|---------|--------|-----|
| **Feed Posts** | Blocked | Network-level blocking |
| **Explore Content** | Blocked | Network-level blocking |
| **Reels Tab** | Redirected | Reels tab sends you to the DM page |
| **Reels Feed** | Blocked | Network-level blocking |
| **Stories Tray** | Blocked | Stories tray removed from the homepage |
| **Ads** | Blocked | Sponsored units in feed, stories, profile, DMs and Explore |
| **Suggested Accounts** | Blocked | "Suggested for you", chaining and friend recommendations |
| **Analytics & Telemetry** | Blocked | Client logging, "seen" receipts and usage stats |
| **Shopping** | Blocked | Commerce and shopping preloads |

## What Still Works

| Feature | Status |
|---------|--------|
| **Direct Messages** | All DM features work |
| **Stories from DMs** | Access friends' stories from the DM page |
| **Profile** | View your own stories and posts from your profile page |
| **Posting Stories** | You can post stories normally |
| **Reels in DMs** | Reels shared via DMs still play |
| **Search** | Searching for users works |
| **Notifications** | Works |
| **Deep Links** | Shared links open their post instead of dropping to the feed |
| **Share to Stories** | Other apps can still share straight into Stories |
| **Settings** | Separate `InstaFree Settings` launcher icon |

## Requirements

- Java 17 or newer, and Python 3
- `zipalign` and `apksigner` from the Android SDK build-tools
- apktool - a system package, or let the patcher fetch a pinned copy into `tools/`

### Linux
```bash
sudo apt install apktool zipalign apksigner openjdk-17-jdk python3
```

### macOS
```bash
brew install apktool android-commandlinetools openjdk python3
sdkmanager "build-tools;35.0.0"
```

## Quick Start

1. **Download an Instagram APK** from [APKMirror](https://www.apkmirror.com/apk/instagram/instagram-instagram/).

   Pick the **arm64-v8a** variant for your Android version. APKMirror now ships
   Instagram as a split **BUNDLE** (`.apkm`); the patcher merges those into a
   single universal APK for you, so download it as-is.

2. **Run the patcher:**
   ```bash
   ./patch.sh instagram.apkm
   ```
   The signed result is written to `instafree_<instagram-version>.apk`.

3. **Install the patched APK:**
   ```bash
   adb install -r instafree_*.apk
   ```

4. **Cleanup build artifacts:**
   ```bash
   ./cleanup.sh
   ```

### Options

| Flag | Effect |
|------|--------|
| `-o, --output FILE` | Write the patched APK somewhere specific |
| `--keep-work` | Keep the decoded sources for inspection |
| `--no-deeplinks` | Skip the signature check bypass |

Set `INSTAFREE_HEAP` (default `4g`) to change how much memory apktool gets.

## Patching in CI

The **Patch Instagram APK** workflow does the same thing on GitHub Actions, so a
new release does not need a local Android toolchain.

APKMirror blocks automated downloads, so hand the stock APK to the workflow one
of two ways:

- attach it to a release in this repo and pass that tag as `source_release`, or
- pass any direct download link as `apk_url`.

The patched APK is uploaded as a workflow artifact. Set `publish_tag` as well to
attach it to a release.

## File Structure

```
instafree/
├── patch.sh                    # Main patching script
├── cleanup.sh                  # Removes build artifacts
├── apply_network_patch.py      # Network hook injection
├── global_redirect.py          # Reels tab redirection
├── apply_signature_bypass.py   # Deep-link signature check bypass
├── patch_app_init.py           # Application.onCreate → InstaFreeConfig.init
├── patch_manifest.py           # Register InstaFree Settings
├── inject_settings_entry.py    # Settings entry / launcher shortcut
├── axml_patcher.py             # Binary AndroidManifest editor
├── instafree.keystore          # Signing keystore (password: android)
└── patches/
    ├── InstaFreeConfig.smali
    ├── InstaFreeHooks.smali
    ├── InstaFreeRedirect.smali
    └── InstaFreeSettings.smali
```

## Keystore

The patched APK needs to be signed before installation. The patcher uses a keystore file for signing.

### Generating a Keystore

If `instafree.keystore` doesn't exist, create one:

```bash
keytool -genkey -v -keystore instafree.keystore -alias instafree \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass android -keypass android \
  -dname "CN=InstaFree, OU=InstaFree, O=InstaFree, L=Unknown, ST=Unknown, C=XX"
```

### Keystore Details

| Property | Value |
|----------|-------|
| Filename | `instafree.keystore` |
| Alias | `instafree` |
| Password | `android` |
| Algorithm | RSA 2048-bit |
| Validity | 10,000 days |

> **Note:** If you reinstall the app, you must use the same keystore to preserve your data. Signing with a different keystore requires uninstalling the previous version first.

Override the defaults with `INSTAFREE_KEYSTORE`, `INSTAFREE_KEYSTORE_PASS`,
`INSTAFREE_KEY_ALIAS` and `INSTAFREE_KEY_PASS`.

## Debugging

View logs to see what's being blocked:
```bash
adb logcat -s "InstaFree:D"
```
Blocked requests also surface as `java.io.IOException: Blocked by InstaFree`.

## How It Works

### Network Blocking
Hooks into `TigonServiceLayer.startRequest` (a named, non-obfuscated class) right
where the request URI is loaded, inside a try block that already catches
`IOException`. Blocked requests throw, so Instagram treats the surface as a
failed network call and leaves it empty. The rules live in
`patches/InstaFreeHooks.smali`.

### Tab Redirect
Rewrites the `fragment_clips` (Reels) fragment name to `fragment_direct_tab`
(DMs), so every Reels entry point opens the DM inbox instead. Reels shared in
DMs are unaffected: they never go through the tab host.

### Deep-link Signature Bypass
Instagram checks that the running APK carries Meta's signing certificate before
following a link into its own content, so a re-signed build silently drops shared
links to the home feed. The key-hash class is located by the string
`Invalid SHA256 key hash`, and the allowlist checks that take key hashes are
forced to return true. This is a trust check on the app's own signature, not a
security boundary against anything else. Skip it with `--no-deeplinks`.

## Updating for a New Instagram Version

Run `./patch.sh` against the new APK - the patches locate their targets by
class, method and string rather than by obfuscated names, so they usually carry
over untouched. If Instagram restructures a targeted area the patcher stops with
a message naming which of the three patches lost its anchor.

## Upstream

FeurStagram has since moved to a different architecture, built on the
[Morphe](https://morphe.software) patcher with a runtime settings page. InstaFree
stays on this self-contained smali toolkit. See
[docs/UPSTREAM.md](docs/UPSTREAM.md) for what that means and what a move
upstream would cost.

## Credits

This project is a fork of [FeurStagram](https://github.com/jean-voila/FeurStagram) by [jean-voila](https://github.com/jean-voila), originally released under the [Unlicense](https://unlicense.org).

## License

This project is released under the Unlicense - you can do whatever you want with it. See [LICENSE](LICENSE) for details.
