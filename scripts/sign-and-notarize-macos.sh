#!/bin/bash
#
# Sign and notarize Open Yapper for macOS distribution.
# Requires: Apple Developer Program ($99/year) + Developer ID Application certificate
#
# Setup:
# 1. Enroll at https://developer.apple.com/programs/
# 2. Create Developer ID Application certificate in Xcode/Keychain
# 3. Create App-Specific Password at https://appleid.apple.com
# 4. Set env vars:
#    export APPLE_ID="your@email.com"
#    export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
#    export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
#    export TEAM_ID="YOUR_TEAM_ID"  # 10-char ID from developer.apple.com
#
# Usage: ./scripts/sign-and-notarize-macos.sh

set -e

APP_NAME="open yapper"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
BUNDLE_ID="com.matin.openYapper"

# Check env
if [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ] || [ -z "$DEVELOPER_ID" ] || [ -z "$TEAM_ID" ]; then
  echo ""
  echo "Error: Set these environment variables first:"
  echo "  export APPLE_ID=\"your@email.com\""
  echo "  export APP_SPECIFIC_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
  echo "  export DEVELOPER_ID=\"Developer ID Application: Your Name (TEAMID)\""
  echo "  export TEAM_ID=\"YOUR_TEAM_ID\""
  echo ""
  echo "See docs/SIGN_AND_NOTARIZE.md for step-by-step setup."
  exit 1
fi

# Build
echo "Building..."
flutter build macos --release

if [ ! -d "$APP_PATH" ]; then
  echo "Error: App not found at $APP_PATH"
  exit 1
fi

# Sign
echo "Signing..."
codesign --deep --force --verbose --timestamp --sign "$DEVELOPER_ID" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH" && echo "Signature OK"

# Create DMG for notarization (Apple requires zip or dmg)
echo "Creating archive for notarization..."
cd build/macos/Build/Products/Release
ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}.zip"
cd - > /dev/null

# Notarize
echo "Submitting for notarization..."
xcrun notarytool submit "build/macos/Build/Products/Release/${APP_NAME}.zip" \
  --apple-id "$APPLE_ID" \
  --password "$APP_SPECIFIC_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait

echo "Notarization complete. Stapling..."
xcrun stapler staple "$APP_PATH"
xcrun stapler validate "$APP_PATH" && echo "Staple OK"

# Create final DMG
echo "Creating DMG..."
DMG_OUT="open_yapper.dmg"
rm -f "$DMG_OUT"
hdiutil create -volname "Open Yapper" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_OUT"

echo ""
echo "Done! Signed and notarized: $DMG_OUT"
echo "Upload this to GitHub Releases - users won't see the malware warning."
