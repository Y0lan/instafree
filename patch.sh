#!/bin/bash

# InstaFree Patcher
# Patches an Instagram APK to create a distraction-free version
#
# Usage: ./patch.sh <instagram.apk>
#
# Requirements:
#   - apktool
#   - Android SDK build-tools (for zipalign and apksigner)
#   - Java runtime
#   - Python 3

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
KEYSTORE="$SCRIPT_DIR/instafree.keystore"
KEYSTORE_PASS="android"

# Find Android build-tools
find_build_tools() {
    local paths=(
        # Linux paths
        "$ANDROID_HOME/build-tools"
        "$ANDROID_SDK_ROOT/build-tools"
        "$HOME/Android/Sdk/build-tools"
        "/usr/lib/android-sdk/build-tools"
        # macOS paths
        "/opt/homebrew/share/android-commandlinetools/build-tools"
        "$HOME/Library/Android/sdk/build-tools"
        "/usr/local/share/android-commandlinetools/build-tools"
    )

    for base in "${paths[@]}"; do
        if [ -d "$base" ]; then
            local latest=$(ls -1 "$base" 2>/dev/null | sort -V | tail -n1)
            if [ -n "$latest" ] && [ -f "$base/$latest/zipalign" ]; then
                echo "$base/$latest"
                return 0
            fi
        fi
    done

    return 1
}

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"

    if ! command -v apktool &> /dev/null; then
        echo -e "${RED}Error: apktool not found.${NC}"
        echo "  Linux: sudo apt install apktool"
        echo "  macOS: brew install apktool"
        exit 1
    fi

    if ! command -v java &> /dev/null; then
        echo -e "${RED}Error: java not found. Please install Java runtime.${NC}"
        exit 1
    fi

    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 not found. Please install Python 3.${NC}"
        exit 1
    fi

    BUILD_TOOLS=$(find_build_tools || true)
    if [ -n "$BUILD_TOOLS" ]; then
        ZIPALIGN="$BUILD_TOOLS/zipalign"
        APKSIGNER="$BUILD_TOOLS/apksigner"
    elif command -v zipalign &> /dev/null && command -v apksigner &> /dev/null; then
        ZIPALIGN="$(command -v zipalign)"
        APKSIGNER="$(command -v apksigner)"
        BUILD_TOOLS="(system PATH)"
    else
        echo -e "${RED}Error: Android build-tools not found.${NC}"
        echo "  Linux: sudo apt install android-sdk-build-tools"
        echo "  macOS: brew install android-commandlinetools && sdkmanager 'build-tools;34.0.0'"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies found${NC}"
    echo "  apktool: $(which apktool)"
    echo "  build-tools: $BUILD_TOOLS"
}

# Main patching function
patch_apk() {
    local INPUT_APK="$1"
    local WORK_DIR="$SCRIPT_DIR/instagram_source"
    local OUTPUT_APK="$SCRIPT_DIR/instafree_patched.apk"

    # Step 1: Decompile
    echo -e "\n${YELLOW}[1/9] Decompiling APK...${NC}"
    rm -rf "$WORK_DIR"
    apktool d --no-res "$INPUT_APK" -o "$WORK_DIR"
    echo -e "${GREEN}✓ Decompiled${NC}"

    # Step 2: Copy InstaFree helper classes
    echo -e "\n${YELLOW}[2/9] Adding InstaFree classes...${NC}"
    mkdir -p "$WORK_DIR/smali_classes17/com/instafree"
    cp "$PATCHES_DIR/InstaFreeConfig.smali" "$WORK_DIR/smali_classes17/com/instafree/"
    cp "$PATCHES_DIR/InstaFreeHooks.smali" "$WORK_DIR/smali_classes17/com/instafree/"
    cp "$PATCHES_DIR/InstaFreeRedirect.smali" "$WORK_DIR/smali_classes17/com/instafree/"
    cp "$PATCHES_DIR/InstaFreeSettings.smali" "$WORK_DIR/smali_classes17/com/instafree/"
    mkdir -p "$WORK_DIR/assets"
    cp "$PATCHES_DIR/instafree_icon.png" "$WORK_DIR/assets/"
    echo -e "${GREEN}✓ Added InstaFreeConfig.smali, InstaFreeHooks.smali, InstaFreeRedirect.smali, InstaFreeSettings.smali${NC}"

    # Step 3: Patch network layer...
    echo -e "\n${YELLOW}[3/9] Patching network layer...${NC}"
    local TIGON_FILE="$WORK_DIR/smali/com/instagram/api/tigon/TigonServiceLayer.smali"
    if [ ! -f "$TIGON_FILE" ]; then
        echo -e "${RED}Error: TigonServiceLayer.smali not found${NC}"
        exit 1
    fi

    python3 "$SCRIPT_DIR/apply_network_patch.py" "$TIGON_FILE"
    echo -e "${GREEN}✓ Network hook patch applied${NC}"

    # Step 4: Initialize config system
    echo -e "\n${YELLOW}[4/9] Initializing config system...${NC}"
    python3 "$SCRIPT_DIR/patch_app_init.py" "$WORK_DIR"
    echo -e "${GREEN}✓ Application.onCreate patched for config init${NC}"

    # Step 5: Patch tab redirection
    echo -e "\n${YELLOW}[5/9] Patching tab redirection (Global)...${NC}"
    python3 "$SCRIPT_DIR/global_redirect.py" "$WORK_DIR"
    echo -e "${GREEN}✓ Global tab redirection applied${NC}"

    # Step 6: Register settings activity in manifest
    echo -e "\n${YELLOW}[6/9] Registering settings activity...${NC}"
    python3 "$SCRIPT_DIR/patch_manifest.py" "$WORK_DIR/AndroidManifest.xml"
    echo -e "${GREEN}✓ InstaFreeSettings registered in manifest${NC}"

    # Step 7: Inject settings entry
    echo -e "\n${YELLOW}[7/9] Injecting settings entry...${NC}"
    python3 "$SCRIPT_DIR/inject_settings_entry.py" "$WORK_DIR"
    echo -e "${GREEN}✓ Settings entry injected${NC}"

    # Step 8: Build APK
    echo -e "\n${YELLOW}[8/9] Building APK...${NC}"
    apktool b "$WORK_DIR" -o "$SCRIPT_DIR/instafree_unsigned.apk"
    echo -e "${GREEN}✓ APK built${NC}"

    # Step 9: Sign APK
    echo -e "\n${YELLOW}[9/9] Signing APK...${NC}"
    "$ZIPALIGN" -f 4 "$SCRIPT_DIR/instafree_unsigned.apk" "$SCRIPT_DIR/instafree_aligned.apk"
    "$APKSIGNER" sign --ks "$KEYSTORE" --ks-pass "pass:$KEYSTORE_PASS" --out "$OUTPUT_APK" "$SCRIPT_DIR/instafree_aligned.apk"

    # Cleanup intermediate files
    rm -f "$SCRIPT_DIR/instafree_unsigned.apk" "$SCRIPT_DIR/instafree_aligned.apk"

    echo -e "${GREEN}✓ APK signed${NC}"

    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS! Patched APK: $OUTPUT_APK${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\nInstall with: adb install -r $OUTPUT_APK"
    echo -e "Cleanup with: ./cleanup.sh"
}

# Print usage
usage() {
    echo "Usage: $0 <instagram.apk>"
    echo ""
    echo "Patches an Instagram APK to create InstaFree (Distraction-Free Instagram)"
    echo ""
    echo "Features disabled (configurable via settings menu):"
    echo "  - Feed posts (Stories remain visible)"
    echo "  - Explore content"
    echo "  - Reels content"
    echo ""
    echo "Features preserved:"
    echo "  - Stories"
    echo "  - Direct Messages"
    echo "  - Profile"
    echo "  - Reels shared via DMs"
    echo ""
    echo "Settings menu:"
    echo "  - In-app settings to toggle blocking per feature"
}

# Main
if [ $# -ne 1 ]; then
    usage
    exit 1
fi

if [ ! -f "$1" ]; then
    echo -e "${RED}Error: File not found: $1${NC}"
    exit 1
fi

check_dependencies
patch_apk "$1"
