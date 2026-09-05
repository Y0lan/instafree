#!/bin/bash

# InstaFree Cleanup Script
# Removes everything the patcher generates. Downloaded tools under tools/ are
# kept, since they are pinned and reused across builds; delete that directory
# by hand to force a re-download.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Cleaning up InstaFree build artifacts..."

# Decompiled source
rm -rf "$SCRIPT_DIR/instagram_source"

# Merged bundles and intermediate APKs
rm -rf "$SCRIPT_DIR/build"

# Intermediate APKs from older runs
rm -f "$SCRIPT_DIR/instafree_unsigned.apk"
rm -f "$SCRIPT_DIR/instafree_aligned.apk"

# Signature sidecars
rm -f "$SCRIPT_DIR"/*.idsig

# Python cache
rm -rf "$SCRIPT_DIR/__pycache__"
find "$SCRIPT_DIR" -name "*.pyc" -delete

# macOS metadata
find "$SCRIPT_DIR" -name ".DS_Store" -delete

echo "Cleanup complete"
echo
echo "Patched APKs were left in place:"
ls -1 "$SCRIPT_DIR"/instafree_*.apk 2>/dev/null || echo "  (none)"
