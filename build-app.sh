#!/bin/bash

set -euo pipefail

PROJECT_DIRECTORY="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIRECTORY="$PROJECT_DIRECTORY/.bridge-build"
OUTPUT_DIRECTORY="$PROJECT_DIRECTORY/dist"

APP_NAME="BridgeLock"
BUNDLE_IDENTIFIER="com.argyrios.BridgeLock"

APP_BUNDLE="$OUTPUT_DIRECTORY/$APP_NAME.app"
CONTENTS_DIRECTORY="$APP_BUNDLE/Contents"
MACOS_DIRECTORY="$CONTENTS_DIRECTORY/MacOS"
RESOURCES_DIRECTORY="$CONTENTS_DIRECTORY/Resources"

EXECUTABLE_SOURCE="$BUILD_DIRECTORY/release/$APP_NAME"
EXECUTABLE_DESTINATION="$MACOS_DIRECTORY/$APP_NAME"

ICON_SOURCE="$PROJECT_DIRECTORY/AppIcon.icns"
ICON_DESTINATION="$RESOURCES_DIRECTORY/AppIcon.icns"

INFO_PLIST="$CONTENTS_DIRECTORY/Info.plist"

if [[ ! -f "$ICON_SOURCE" ]]; then
    echo "Error: AppIcon.icns was not found."
    echo "Run ./make-app-icon.sh first."
    exit 1
fi

rm -rf "$BUILD_DIRECTORY"
rm -rf "$APP_BUNDLE"

swift build \
    --configuration release \
    --scratch-path "$BUILD_DIRECTORY"

if [[ ! -f "$EXECUTABLE_SOURCE" ]]; then
    echo "Error: BridgeLock executable was not generated."
    exit 1
fi

mkdir -p "$MACOS_DIRECTORY"
mkdir -p "$RESOURCES_DIRECTORY"

cp "$EXECUTABLE_SOURCE" "$EXECUTABLE_DESTINATION"
cp "$ICON_SOURCE" "$ICON_DESTINATION"

chmod +x "$EXECUTABLE_DESTINATION"

cat > "$INFO_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>

    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>

    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>

    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>

    <key>CFBundlePackageType</key>
    <string>APPL</string>

    <key>CFBundleIconFile</key>
    <string>AppIcon</string>

    <key>CFBundleShortVersionString</key>
    <string>1.0</string>

    <key>CFBundleVersion</key>
    <string>1</string>

    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>

    <key>LSUIElement</key>
    <true/>

    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

codesign \
    --force \
    --deep \
    --sign - \
    "$APP_BUNDLE"

echo "Application created successfully:"
echo "$APP_BUNDLE"