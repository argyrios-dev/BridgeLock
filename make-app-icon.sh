#!/bin/bash

set -euo pipefail

PROJECT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
SOURCE_ICON="$PROJECT_DIRECTORY/AppIcon.png"
ICONSET_DIRECTORY="$PROJECT_DIRECTORY/AppIcon.iconset"
OUTPUT_ICON="$PROJECT_DIRECTORY/AppIcon.icns"

if [[ ! -f "$SOURCE_ICON" ]]; then
    echo "Error: AppIcon.png was not found at:"
    echo "$SOURCE_ICON"
    exit 1
fi

rm -rf "$ICONSET_DIRECTORY"
rm -f "$OUTPUT_ICON"

mkdir -p "$ICONSET_DIRECTORY"

sips -z 16 16 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_16x16.png"

sips -z 32 32 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_16x16@2x.png"

sips -z 32 32 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_32x32.png"

sips -z 64 64 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_32x32@2x.png"

sips -z 128 128 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_128x128.png"

sips -z 256 256 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_128x128@2x.png"

sips -z 256 256 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_256x256.png"

sips -z 512 512 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_256x256@2x.png"

sips -z 512 512 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_512x512.png"

sips -z 1024 1024 \
    "$SOURCE_ICON" \
    --out "$ICONSET_DIRECTORY/icon_512x512@2x.png"

iconutil \
    --convert icns \
    "$ICONSET_DIRECTORY" \
    --output "$OUTPUT_ICON"

echo "App icon created successfully:"
echo "$OUTPUT_ICON"