<p align="center">
  <img src="docs/app_icon.png" alt="FeurStagram Icon" width="128">
</p>

<h1 align="center">FeurStagram</h1>
<p align="center">Distraction-Free Instagram</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/jean-voila/FeurStagram?style=for-the-badge&label=Download%20APK&color=10a37f" alt="Download APK">
  </a>
</p>

<p align="center">
  <img src="https://komarev.com/ghpvc/?username=jean-voila-feurstagram&label=Views&color=gray&style=flat" alt="Views">
</p>

---


<p align="center">
  <img src="docs/screen_1.png" alt="FeurStagram screenshot 1" width="240" />
  <img src="docs/screen_2.png" alt="FeurStagram screenshot 2" width="240" />
  <img src="docs/screen_3.png" alt="FeurStagram screenshot 3" width="240" />
</p>

A patching toolkit that removes addictive features from Instagram while keeping essential functionality.

I built this project for myself as an alternative to [DFInstagram](https://www.distractionfreeapps.com/) which hasn't been maintained for a long time and was difficult to update. I'm sharing it so others can do the same for themselves.

**This project is entirely free and open-source.** Feel free to fork, copy, enhance, or submit pull requests - do whatever you want with it!

## Installation

You have two options:

1. **Ready-to-install APK** - Grab the latest patched APK from the [Releases](../../releases) page and install it directly
2. **DIY Patching** - Use the toolkit below to patch any Instagram version yourself

## What Gets Disabled

| Feature | Status | How |
|---------|--------|-----|
| **Feed Posts** | ❌ Blocked | Network-level blocking |
| **Explore Content** | ❌ Blocked | Network-level blocking |
| **Reels Content** | ❌ Redirected | Redirects to DMs |

## What Still Works

| Feature | Status |
|---------|--------|--------|
| **Stories** | ✅ Works |
| **Direct Messages** | ✅ Works |
| **Profile** | ✅ Works |
| **Reels in DMs** | ✅ Works |
| **Search** | ✅ Works |
| **Notifications** | ✅ Works |

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
   adb install -r feurstagram_patched.apk
   ```

4. **Cleanup build artifacts:**
   ```bash
   ./cleanup.sh
   ```

## File Structure

```
Feurstagram/
├── patch.sh                 # Main patching script
├── cleanup.sh               # Removes build artifacts
├── apply_network_patch.py   # Network hook patch logic
├── feurstagram.keystore     # Signing keystore (password: android)
└── patches/
    ├── FeurConfig.smali     # Configuration class
    └── FeurHooks.smali      # Network blocking hooks
```

## Keystore

The patched APK needs to be signed before installation. The patcher uses a keystore file for signing.

### Generating a Keystore

If `feurstagram.keystore` doesn't exist, create one:

```bash
keytool -genkey -v -keystore feurstagram.keystore -alias feurstagram \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass android -keypass android \
  -dname "CN=Feurstagram, OU=Feurstagram, O=Feurstagram, L=Unknown, ST=Unknown, C=XX"
```

### Keystore Details

| Property | Value |
|----------|-------|
| Filename | `feurstagram.keystore` |
| Alias | `feurstagram` |
| Password | `android` |
| Algorithm | RSA 2048-bit |
| Validity | 10,000 days |

> **Note:** If you reinstall the app, you must use the same keystore to preserve your data. Signing with a different keystore requires uninstalling the previous version first.

## Debugging

View logs to see what's being blocked:
```bash
adb logcat -s "Feurstagram:D"
```

## How It Works

### Tab Redirect
Intercepts fragment loading in the main tab host. When Instagram tries to load `fragment_clips` (Reels), it redirects to `fragment_direct_tab` (DMs).

### Network Blocking
Hooks into `TigonServiceLayer` (a named, non-obfuscated class) and blocks requests to `/feed/timeline/` and `/discover/topical_explore`.

## Updating for New Instagram Versions

I'll update this project to support new Instagram versions as they are released. When a new version comes out, I'll apply the necessary patches and release an updated APK.

1. TigonServiceLayer is a named class (doesn't change).

2. Apply the same patches.


## Contributing

This is a personal project I'm sharing with the community. Contributions are welcome!

- 🍴 **Fork it** - Make your own version
- 🔧 **Pull requests** - Improvements and fixes are appreciated
- 📋 **Copy it** - Use the code however you want
- ✨ **Enhance it** - Build something even better

## Donations

If you find this project useful and want to support its development, you can send a donation via Bitcoin:

**BTC:** `bc1qa0xyd9n0fy0hhk2mzg5g5zy8l7lc0t728f0jnq`

Your support is greatly appreciated! 🙏

## License

This project is released under the Unlicense - you can do whatever you want with it. See [LICENSE](LICENSE) for details.
