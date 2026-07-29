#!/bin/bash

set -euo pipefail

APP_NAME="BridgeLock"

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$PROJECT_DIR/dist"
DMG_DIR="$PROJECT_DIR/dmg"

APP="$DIST_DIR/$APP_NAME.app"
TEMP_DMG="$DMG_DIR/$APP_NAME"
FINAL_DMG="$DIST_DIR/$APP_NAME.dmg"

rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"

cp -R "$APP" "$TEMP_DMG.app"

ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$FINAL_DMG"

rm -rf "$DMG_DIR"

echo
echo "DMG created:"
echo "$FINAL_DMG"