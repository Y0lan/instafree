#!/bin/bash

# FeurStagram Cleanup Script
# Removes all generated files after patching

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Cleaning up FeurStagram build artifacts..."

# Remove decompiled source
rm -rf "$SCRIPT_DIR/instagram_source"

# Remove intermediate APKs
rm -f "$SCRIPT_DIR/feurstagram_unsigned.apk"
rm -f "$SCRIPT_DIR/feurstagram_aligned.apk"

# Remove signature files
rm -f "$SCRIPT_DIR"/*.idsig

# Remove Python cache
rm -rf "$SCRIPT_DIR/__pycache__"
find "$SCRIPT_DIR" -name "*.pyc" -delete

# Remove macOS metadata
find "$SCRIPT_DIR" -name ".DS_Store" -delete

echo "✓ Cleanup complete"
echo ""
echo "Remaining files:"
ls -la "$SCRIPT_DIR"
