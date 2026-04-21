#!/usr/bin/env bash
# Build a distributable (unsigned, ad-hoc signed) DMG of YouTubeMusicWrapper.
#
# Usage:  scripts/build-dmg.sh [version]
#   version defaults to the MARKETING_VERSION in the Xcode project (e.g. 0.1.0).
#
# Output: dist/YouTubeMusicWrapper-<version>.dmg

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="YouTubeMusicWrapper.xcodeproj"
SCHEME="YouTubeMusicWrapper"
APP_NAME="YouTubeMusicWrapper.app"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$DIST_DIR/build"
STAGING_DIR="$DIST_DIR/staging"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  VERSION=$(xcodebuild -project "$PROJECT" -showBuildSettings -configuration Release 2>/dev/null \
    | awk -F' = ' '/MARKETING_VERSION/ {print $2; exit}' \
    | tr -d '[:space:]')
  VERSION="${VERSION:-0.0.0}"
fi

DMG_NAME="YouTubeMusicWrapper-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "==> Cleaning dist/"
rm -rf "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$STAGING_DIR"

echo "==> Building Release (ad-hoc signed)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  build | tail -20

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  echo "ERROR: app bundle not found at $BUILT_APP" >&2
  exit 1
fi

echo "==> Staging app bundle"
cp -R "$BUILT_APP" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating DMG -> $DMG_PATH"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "YouTube Music" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" > /dev/null

SIZE=$(du -h "$DMG_PATH" | awk '{print $1}')
SHA=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')

echo ""
echo "Done."
echo "  DMG:    $DMG_PATH"
echo "  Size:   $SIZE"
echo "  SHA256: $SHA"
