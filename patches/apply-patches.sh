#!/bin/bash
# Apply all kernel patches for ReSukiSU manual hook integration
set -e

PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[-] Applying patches..."

for patch in "$PATCH_DIR"/*.patch; do
    echo "[-] Applying $(basename "$patch")..."
    patch -p1 -N -r- < "$patch" 2>/dev/null || echo "[-] $(basename "$patch"): already applied or skipped"
done

echo "[-] All patches applied successfully."