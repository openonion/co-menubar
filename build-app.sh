#!/bin/bash
set -e

# Load credentials from .env if exists
if [ -f .env ]; then
    source .env
fi

APP="CoMenuBar.app"
BUILD_DIR=".build-pkg"

echo "→ Building Swift binary..."
swift build -c release

echo "→ Bundling co CLI with PyInstaller..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

python3 -m venv "$BUILD_DIR/venv"
"$BUILD_DIR/venv/bin/pip" install connectonion pyinstaller --quiet

"$BUILD_DIR/venv/bin/pyinstaller" \
  --onefile \
  --name co \
  --collect-all connectonion \
  --distpath "$BUILD_DIR/dist" \
  --workpath "$BUILD_DIR/work" \
  --specpath "$BUILD_DIR" \
  --log-level WARN \
  "$BUILD_DIR/venv/bin/co"

echo "→ Creating .app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp .build/release/CoMenuBar "$APP/Contents/MacOS/CoMenuBar"
cp "$BUILD_DIR/dist/co" "$APP/Contents/Resources/co"
chmod +x "$APP/Contents/Resources/co"

VERSION=$(defaults read "$(pwd)/$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")

cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CoMenuBar</string>
    <key>CFBundleIdentifier</key>
    <string>com.connectonion.co-menubar</string>
    <key>CFBundleName</key>
    <string>CoMenuBar</string>
    <key>CFBundleDisplayName</key>
    <string>co-menubar</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
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
CODESIGN_ID="${CODESIGN_IDENTITY:-Developer ID Application: Tianle Xie (WABDYB5V3D)}"
codesign --deep --force --options runtime --sign "$CODESIGN_ID" "$APP"

echo "→ Creating distributable ZIP..."
ditto -c -k --keepParent "$APP" CoMenuBar.app.zip

echo "→ Notarizing with Apple..."
xcrun notarytool submit CoMenuBar.app.zip \
  --keychain-profile "AC_PASSWORD" \
  --wait

echo "→ Stapling notarization ticket..."
xcrun stapler staple "$APP"

echo "→ Cleaning up..."
rm -rf "$BUILD_DIR"

echo ""
echo "✓ Done: $APP (signed & notarized)"
echo "  To install: cp -r $APP /Applications/"
echo "  To run:     open $APP"
echo "  Release:    CoMenuBar.app.zip"
