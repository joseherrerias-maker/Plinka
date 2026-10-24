#!/bin/bash
# Build the approved temporary Pluki iOS icon from the checked-in image source.
# The source is a compact JPEG encoding of the user's approved artwork.
# It stays in Git to support repeatable Codemagic and GitHub Actions builds.
set -euo pipefail
IOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="$IOS_DIR/icon-source/pluki-approved-icon.jpeg.b64"
DEST="$IOS_DIR/Plinka/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
if [[ ! -s "$SOURCE" ]]; then
  echo "Missing embedded Pluki app icon source at $SOURCE" >&2
  exit 1
fi
mkdir -p "$(dirname "$DEST")"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
base64 -D -i "$SOURCE" -o "$TMP_DIR/pluki.jpeg"
sips -s format png "$TMP_DIR/pluki.jpeg" --out "$DEST" >/dev/null
WIDTH="$(sips -g pixelWidth "$DEST" | awk '/pixelWidth/{print $2}')"
HEIGHT="$(sips -g pixelHeight "$DEST" | awk '/pixelHeight/{print $2}')"
if [[ "$WIDTH" != "1024" || "$HEIGHT" != "1024" ]]; then
  echo "Pluki icon must be 1024 by 1024 pixels (got ${WIDTH}x${HEIGHT})." >&2
  exit 1
fi
echo "Pluki app icon prepared for Xcode: $DEST"
