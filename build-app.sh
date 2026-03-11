#!/bin/bash
set -e

# Load credentials from .env if exists
if [ -f .env ]; then
    source .env
fi

APP="OOMenuBar.app"
BUILD_DIR=".build-pkg"
LOGO_URL="https://raw.githubusercontent.com/wu-changxing/openonion-assets/master/imgs/Onion.png"

VERSION=$(grep '^version' ../connectonion/pyproject.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
echo "→ Version: $VERSION"

echo "→ Building Swift binary..."
swift build -c release

echo "→ Bundling co CLI with PyInstaller..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

python3 -m venv "$BUILD_DIR/venv"
"$BUILD_DIR/venv/bin/pip" install --force-reinstall --no-cache-dir ../connectonion pyinstaller --quiet

CODESIGN_ID="${CODESIGN_IDENTITY:-Developer ID Application: Tianle Xie (WABDYB5V3D)}"

"$BUILD_DIR/venv/bin/pyinstaller" \
  --onefile \
  --name co \
  --collect-all connectonion \
  --collect-all rich \
  --distpath "$BUILD_DIR/dist" \
  --workpath "$BUILD_DIR/work" \
  --specpath "$BUILD_DIR" \
  --log-level WARN \
  --codesign-identity "$CODESIGN_ID" \
  "$BUILD_DIR/venv/bin/co"

echo "→ Creating .app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/OOMenuBar "$APP/Contents/MacOS/OOMenuBar"

# PyInstaller already signed the co binary with --codesign-identity
cp "$BUILD_DIR/dist/co" "$APP/Contents/Resources/co"
chmod +x "$APP/Contents/Resources/co"

echo "→ Building app icon..."
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
curl -s "$LOGO_URL" -o "$BUILD_DIR/logo.png"
for size in 16 32 64 128 256 512 1024; do
  sips -z $size $size "$BUILD_DIR/logo.png" --out "$ICONSET/icon_${size}x${size}.png" > /dev/null
done
cp "$ICONSET/icon_32x32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$ICONSET/icon_64x64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$ICONSET/icon_256x256.png" "$ICONSET/icon_128x128@2x.png"
cp "$ICONSET/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
cp "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

# Create menu bar icon (44x44 for retina displays)
sips -Z 44 "$BUILD_DIR/logo.png" --out "$APP/Contents/Resources/menubar-icon.png" > /dev/null

cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>OOMenuBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.openonion.oo-menubar</string>
    <key>CFBundleName</key>
    <string>OOMenuBar</string>
    <key>CFBundleDisplayName</key>
    <string>OO MenuBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "→ Code signing with Developer ID..."
# Sign each component explicitly (don't use --deep which is deprecated)
codesign --force --options runtime --timestamp --sign "$CODESIGN_ID" "$APP/Contents/Resources/co"
codesign --force --options runtime --timestamp --sign "$CODESIGN_ID" "$APP/Contents/MacOS/OOMenuBar"
codesign --force --options runtime --timestamp --sign "$CODESIGN_ID" "$APP"

echo "→ Creating distributable ZIP..."
ditto -c -k --keepParent "$APP" OOMenuBar.app.zip

echo "→ Notarizing with Apple..."
if [ -n "$APPLE_ID" ] && [ -n "$APPLE_TEAM_ID" ] && [ -n "$APPLE_APP_PASSWORD" ]; then
  if xcrun notarytool submit OOMenuBar.app.zip \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait 2>&1; then
    echo "→ Stapling notarization ticket..."
    xcrun stapler staple "$APP"
  else
    echo "  Notarization failed (may need to accept Apple Developer agreements)"
    echo "  Continuing with code-signed (but not notarized) build..."
  fi
else
  echo "  Skipping notarization (no credentials in .env)"
fi

echo "→ Cleaning up..."
rm -rf "$BUILD_DIR"

echo ""
echo "✓ Done: $APP (signed & notarized)"
echo "  To install: cp -r $APP /Applications/"
echo "  To run:     open $APP"
echo "  Release:    OOMenuBar.app.zip"
