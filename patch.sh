#!/bin/bash
#
# InstaFree Patcher
# Turns a stock Instagram APK into a distraction-free build.
#
# Usage: ./patch.sh <instagram.apk|.apkm|.xapk|.apks> [options]
#
#   -o, --output FILE   Write the patched APK here
#                       (default: instafree_<instagram-version>.apk)
#       --keep-work     Keep the decoded sources after a successful build
#       --no-deeplinks  Skip the signature check bypass
#   -h, --help          Show this help
#
# Requirements:
#   - Java 17 or newer
#   - Python 3
#   - apktool (system package, tools/apktool_*.jar, or auto-downloaded)
#   - zipalign and apksigner from the Android SDK build-tools
#
# APKMirror ships Instagram as a split BUNDLE (.apkm). Those are merged into a
# single universal APK with APKEditor before patching; a plain .apk is used
# as-is.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHES_DIR="$SCRIPT_DIR/patches"
TOOLS_DIR="$SCRIPT_DIR/tools"
BUILD_DIR="$SCRIPT_DIR/build"
WORK_DIR="$SCRIPT_DIR/instagram_source"

KEYSTORE="${INSTAFREE_KEYSTORE:-$SCRIPT_DIR/instafree.keystore}"
KEYSTORE_PASS="${INSTAFREE_KEYSTORE_PASS:-android}"
KEY_ALIAS="${INSTAFREE_KEY_ALIAS:-instafree}"

# Heap for apktool. Instagram is a large app; the default is deliberately
# generous. Lower it on a small machine with INSTAFREE_HEAP=2g.
HEAP="${INSTAFREE_HEAP:-4g}"

# Pinned tool versions, fetched on demand and checksum-verified.
APKTOOL_VERSION="2.12.1"
APKTOOL_SHA256="66cf4524a4a45a7f56567d08b2c9b6ec237bcdd78cee69fd4a59c8a0243aeafa"
APKTOOL_URL="https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar"
APKEDITOR_VERSION="1.4.9"
APKEDITOR_SHA256="a9cd40df818845456be6d696de6110c89edf4b0a0580cb83438ed6b25a366e67"
APKEDITOR_URL="https://github.com/REAndroid/APKEditor/releases/download/V${APKEDITOR_VERSION}/APKEditor-${APKEDITOR_VERSION}.jar"

INPUT_APK=""
OUTPUT_APK=""
KEEP_WORK=0
DEEPLINKS=1

info()  { echo -e "${YELLOW}$*${NC}"; }
ok()    { echo -e "${GREEN}$*${NC}"; }
fail()  { echo -e "${RED}$*${NC}" >&2; exit 1; }

usage() {
    sed -n '3,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# --- Tool discovery ------------------------------------------------------

fetch_jar() {
    local name="$1" url="$2" want="$3"
    # Declared separately: referring to `name` inside the same `local` reads as
    # unset under `set -u`.
    local dest="$TOOLS_DIR/$name"

    if [ -f "$dest" ]; then
        echo "$dest"
        return 0
    fi
    command -v curl >/dev/null 2>&1 || return 1

    mkdir -p "$TOOLS_DIR"
    info "  Downloading $name from $url" >&2
    curl -fsSL --retry 3 -o "$dest.part" "$url" || { rm -f "$dest.part"; return 1; }

    local got
    got="$(sha256sum "$dest.part" | cut -d' ' -f1)"
    if [ "$got" != "$want" ]; then
        rm -f "$dest.part"
        echo "  Checksum mismatch for $name (expected $want, got $got)" >&2
        return 1
    fi
    mv "$dest.part" "$dest"
    echo "$dest"
}

APKTOOL_JAR_PATH=""
resolve_apktool() {
    if [ -n "${APKTOOL_JAR:-}" ] && [ -f "${APKTOOL_JAR}" ]; then
        APKTOOL_JAR_PATH="$APKTOOL_JAR"
        return 0
    fi
    local local_jar
    local_jar="$(ls -t "$TOOLS_DIR"/apktool_*.jar 2>/dev/null | head -1 || true)"
    if [ -n "$local_jar" ]; then
        APKTOOL_JAR_PATH="$local_jar"
        return 0
    fi
    if command -v apktool >/dev/null 2>&1; then
        return 0   # use the system wrapper
    fi
    APKTOOL_JAR_PATH="$(fetch_jar "apktool_${APKTOOL_VERSION}.jar" "$APKTOOL_URL" "$APKTOOL_SHA256")" || {
        fail "apktool not found and could not be downloaded.
  Linux: sudo apt install apktool
  macOS: brew install apktool
  Or drop apktool_${APKTOOL_VERSION}.jar into $TOOLS_DIR/"
    }
}

run_apktool() {
    if [ -n "$APKTOOL_JAR_PATH" ]; then
        java "-Xmx$HEAP" -jar "$APKTOOL_JAR_PATH" "$@"
    else
        # The system wrapper caps the heap at 512M, which is not enough for
        # Instagram; -J passes our own limit through to the JVM.
        apktool "-JXmx$HEAP" "$@"
    fi
}

ZIPALIGN=""
APKSIGNER=""
resolve_build_tools() {
    local bases=(
        "${ANDROID_HOME:-}/build-tools"
        "${ANDROID_SDK_ROOT:-}/build-tools"
        "$HOME/Android/Sdk/build-tools"
        "/usr/lib/android-sdk/build-tools"
        "/opt/homebrew/share/android-commandlinetools/build-tools"
        "$HOME/Library/Android/sdk/build-tools"
        "/usr/local/share/android-commandlinetools/build-tools"
    )
    local base latest
    for base in "${bases[@]}"; do
        [ -d "$base" ] || continue
        latest="$(ls -1 "$base" 2>/dev/null | sort -V | tail -n1)"
        if [ -n "$latest" ] && [ -x "$base/$latest/zipalign" ]; then
            ZIPALIGN="$base/$latest/zipalign"
            APKSIGNER="$base/$latest/apksigner"
            return 0
        fi
    done
    if command -v zipalign >/dev/null 2>&1 && command -v apksigner >/dev/null 2>&1; then
        ZIPALIGN="$(command -v zipalign)"
        APKSIGNER="$(command -v apksigner)"
        return 0
    fi
    fail "Android build-tools not found (need zipalign and apksigner).
  Linux: sudo apt install zipalign apksigner
  macOS: brew install android-commandlinetools && sdkmanager 'build-tools;35.0.0'"
}

check_dependencies() {
    info "Checking dependencies..."
    command -v java >/dev/null 2>&1 || fail "java not found. Install a JDK (17 or newer)."
    command -v python3 >/dev/null 2>&1 || fail "python3 not found."
    [ -f "$KEYSTORE" ] || fail "Keystore not found: $KEYSTORE
  See the Keystore section of the README to generate one."

    resolve_apktool
    resolve_build_tools

    ok "✓ All dependencies found"
    echo "  apktool:     ${APKTOOL_JAR_PATH:-$(command -v apktool)}"
    echo "  build-tools: $(dirname "$ZIPALIGN")"
    echo "  heap:        $HEAP"
}

# --- Pipeline ------------------------------------------------------------

apk_version() {
    local apk="$1" dump="" tool
    local build_tools_dir
    build_tools_dir="$(dirname "$ZIPALIGN")"
    for tool in "$build_tools_dir/aapt2" "$build_tools_dir/aapt" aapt2 aapt; do
        command -v "$tool" >/dev/null 2>&1 || continue
        dump="$("$tool" dump badging "$apk" 2>/dev/null | head -1 || true)"
        [ -n "$dump" ] && break
    done
    echo "$dump" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p"
}

# APKMirror bundles hold base.apk plus per-ABI and per-density splits. The
# patcher works on one APK, so the splits are merged into a universal APK first.
merge_bundle() {
    local bundle="$1"
    local merged="$BUILD_DIR/merged/$(basename "${bundle%.*}").apk"

    if [ -f "$merged" ] && [ "$merged" -nt "$bundle" ]; then
        info "  Reusing merged bundle: $(basename "$merged")" >&2
        echo "$merged"
        return 0
    fi

    local editor
    editor="$(fetch_jar "APKEditor-${APKEDITOR_VERSION}.jar" "$APKEDITOR_URL" "$APKEDITOR_SHA256")" || {
        fail "$(basename "$bundle") is a split bundle and needs APKEditor to merge.
  Download APKEditor-${APKEDITOR_VERSION}.jar into $TOOLS_DIR/ and re-run."
    }

    mkdir -p "$(dirname "$merged")"
    info "  Merging splits from $(basename "$bundle")" >&2
    if ! java "-Xmx$HEAP" -jar "$editor" m -f -i "$bundle" -o "$merged" > "$merged.log" 2>&1; then
        fail "APKEditor failed to merge $(basename "$bundle"). Log: $merged.log"
    fi
    echo "$merged"
}

# Android refuses to load compressed native libraries when the manifest says
# extractNativeLibs="false", which is what merged bundles declare. apktool
# records which entries to leave uncompressed in apktool.yml; make sure the
# shared objects are on that list before rebuilding.
preserve_uncompressed_libs() {
    local apk="$1" yml="$WORK_DIR/apktool.yml"
    [ -f "$yml" ] || return 0
    unzip -v "$apk" 2>/dev/null | awk '$2 == "Stored" && $8 ~ /^lib\/.*\.so$/ {found=1} END {exit !found}' || return 0
    grep -qE '^- so$' "$yml" && return 0
    if grep -q '^doNotCompress:' "$yml"; then
        sed -i.bak '/^doNotCompress:/a\
- so' "$yml" && rm -f "$yml.bak"
    else
        printf 'doNotCompress:\n- so\n' >> "$yml"
    fi
    echo "  Kept native libraries uncompressed (extractNativeLibs=false)"
}

# Instagram ships 17+ dex files. Rather than squeezing our classes into one of
# them, give them a dex of their own: the next free slot is always safe, however
# many dex files a future release adds.
next_smali_dir() {
    local highest=1 entry index
    for entry in "$WORK_DIR"/smali_classes*; do
        [ -d "$entry" ] || continue
        index="${entry##*smali_classes}"
        case "$index" in
            ''|*[!0-9]*) continue ;;
        esac
        [ "$index" -gt "$highest" ] && highest="$index"
    done
    echo "$WORK_DIR/smali_classes$((highest + 1))"
}

patch_apk() {
    local source_apk="$1"

    info "\n[1/6] Decompiling APK..."
    rm -rf "$WORK_DIR"
    run_apktool d --no-res -f "$source_apk" -o "$WORK_DIR" >/dev/null
    preserve_uncompressed_libs "$source_apk"
    ok "✓ Decompiled"

    info "\n[2/6] Adding InstaFree classes..."
    local smali_dir
    smali_dir="$(next_smali_dir)"
    mkdir -p "$smali_dir/com/instafree"
    cp "$PATCHES_DIR/InstaFreeConfig.smali" "$PATCHES_DIR/InstaFreeHooks.smali" "$smali_dir/com/instafree/"
    ok "✓ Added InstaFreeConfig and InstaFreeHooks to $(basename "$smali_dir")"

    info "\n[3/6] Patching network layer..."
    python3 "$SCRIPT_DIR/apply_network_patch.py" "$WORK_DIR" || fail "Network hook patch failed"
    ok "✓ Network hook applied"

    info "\n[4/6] Redirecting the Reels tab..."
    python3 "$SCRIPT_DIR/global_redirect.py" "$WORK_DIR" || fail "Reels redirection failed"
    if [ "$DEEPLINKS" -eq 1 ]; then
        python3 "$SCRIPT_DIR/apply_signature_bypass.py" "$WORK_DIR" || fail "Signature bypass failed"
    else
        echo "  Skipping the signature check bypass (--no-deeplinks)"
    fi
    ok "✓ UI patches applied"

    info "\n[5/6] Building APK..."
    run_apktool b "$WORK_DIR" -o "$BUILD_DIR/instafree_unsigned.apk" >/dev/null
    ok "✓ APK built"

    info "\n[6/6] Signing APK..."
    local align_args=(-f 4) zipalign_usage
    zipalign_usage="$("$ZIPALIGN" 2>&1 || true)"
    if printf '%s' "$zipalign_usage" | grep -q -- '-P <pagesize'; then
        # 16 KB page alignment, required by Android 15+ devices.
        align_args=(-f -P 16 4)
    elif printf '%s' "$zipalign_usage" | grep -q -- '-p '; then
        align_args=(-f -p 4)
    fi
    echo "  zipalign ${align_args[*]}"
    "$ZIPALIGN" "${align_args[@]}" "$BUILD_DIR/instafree_unsigned.apk" "$BUILD_DIR/instafree_aligned.apk"
    "$APKSIGNER" sign \
        --ks "$KEYSTORE" \
        --ks-key-alias "$KEY_ALIAS" \
        --ks-pass "pass:$KEYSTORE_PASS" \
        --key-pass "pass:${INSTAFREE_KEY_PASS:-$KEYSTORE_PASS}" \
        --v1-signing-enabled true \
        --v2-signing-enabled true \
        --v3-signing-enabled true \
        --v4-signing-enabled false \
        --out "$OUTPUT_APK" \
        "$BUILD_DIR/instafree_aligned.apk"
    rm -f "$BUILD_DIR/instafree_unsigned.apk" "$BUILD_DIR/instafree_aligned.apk" "$OUTPUT_APK.idsig"
    ok "✓ APK signed"

    info "\nVerifying..."
    "$APKSIGNER" verify --print-certs "$OUTPUT_APK" \
        | grep -i "SHA-256 digest" | head -1 | sed 's/^/  /' || true
    ok "✓ Signature verified"
}

# --- Entry point ---------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -o|--output)
            [ -n "${2:-}" ] || fail "--output needs a filename"
            OUTPUT_APK="$2"; shift 2 ;;
        --keep-work) KEEP_WORK=1; shift ;;
        --no-deeplinks) DEEPLINKS=0; shift ;;
        -*) fail "Unknown option: $1" ;;
        *) [ -n "$INPUT_APK" ] && fail "Only one input file is supported"; INPUT_APK="$1"; shift ;;
    esac
done

[ -n "$INPUT_APK" ] || { usage; exit 1; }
[ -f "$INPUT_APK" ] || fail "File not found: $INPUT_APK"

check_dependencies
mkdir -p "$BUILD_DIR"

SOURCE_APK="$INPUT_APK"
case "$INPUT_APK" in
    *.apkm|*.xapk|*.apks)
        info "\n[0/6] Merging split bundle..."
        SOURCE_APK="$(merge_bundle "$INPUT_APK")"
        ok "✓ Merged into $(basename "$SOURCE_APK")"
        ;;
esac

IG_VERSION="$(apk_version "$SOURCE_APK")"
[ -n "$IG_VERSION" ] && echo -e "\nInstagram version: $IG_VERSION"

if [ -z "$OUTPUT_APK" ]; then
    if [ -n "$IG_VERSION" ]; then
        OUTPUT_APK="$SCRIPT_DIR/instafree_${IG_VERSION}.apk"
    else
        OUTPUT_APK="$SCRIPT_DIR/instafree_patched.apk"
    fi
fi

patch_apk "$SOURCE_APK"

if [ "$KEEP_WORK" -eq 0 ]; then
    rm -rf "$WORK_DIR"
fi

echo
ok "========================================"
ok "SUCCESS: $OUTPUT_APK"
ok "========================================"
echo "  Instagram version: ${IG_VERSION:-unknown}"
echo "  Size:              $(du -h "$OUTPUT_APK" | cut -f1)"
echo "  SHA256:            $(sha256sum "$OUTPUT_APK" | cut -d' ' -f1)"
echo
echo "Install with: adb install -r $OUTPUT_APK"
