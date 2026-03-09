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
| **Reels Content** | Redirected | Redirects to DMs |

## What Still Works

| Feature | Status |
|---------|--------|
| **Stories** | Works |
| **Direct Messages** | Works |
| **Profile** | Works |
| **Reels in DMs** | Works |
| **Search** | Works |
| **Notifications** | Works |

## Requirements

### Linux
```bash
sudo apt install apktool android-sdk-build-tools openjdk-17-jdk python3
```

### macOS
```bash
brew install apktool android-commandlinetools openjdk python3
 sdkmanager "build-tools;34.0.0"
```

## Quick Start

1. **Download an Instagram APK** from [APKMirror](https://www.apkmirror.com/apk/instagram/instagram-instagram/) (arm64-v8a recommended)

2. **Run the patcher:**
   ```bash
   ./patch.sh instagram.apk
   ```

3. **Install the patched APK:**
   ```bash
   adb install -r instafree_patched.apk
   ```

4. **Cleanup build artifacts:**
   ```bash
   ./cleanup.sh
   ```

## File Structure

```
instafree/
├── patch.sh                    # Main patching script
├── cleanup.sh                  # Removes build artifacts
├── apply_network_patch.py      # Network hook patch logic
├── instafree.keystore          # Signing keystore (password: android)
└── patches/
    ├── InstaFreeConfig.smali   # Configuration class
    └── InstaFreeHooks.smali    # Network blocking hooks
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

## Debugging

View logs to see what's being blocked:
```bash
adb logcat -s "InstaFree:D"
```

## How It Works

### Tab Redirect
Intercepts fragment loading in the main tab host. When Instagram tries to load `fragment_clips` (Reels), it redirects to `fragment_direct_tab` (DMs).

### Network Blocking
Hooks into `TigonServiceLayer` (a named, non-obfuscated class) and blocks requests to `/feed/timeline/` and `/discover/topical_explore`.

## Credits

This project is a fork of [FeurStagram](https://github.com/jean-voila/FeurStagram) by [jean-voila](https://github.com/jean-voila), originally released under the [Unlicense](https://unlicense.org).

## License

This project is released under the Unlicense - you can do whatever you want with it. See [LICENSE](LICENSE) for details.
