#!/bin/bash
#
# Sign and notarize Open Yapper for macOS distribution.
# Usage: ./scripts/sign-and-notarize-macos.sh

set -euo pipefail

APP_NAME="Open Yapper"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_OUT="open_yapper.dmg"
NOTARY_WAIT_MODE="${NOTARY_WAIT_MODE:-wait}" # wait | nowait
RELEASE_VERSION="$(awk -F ': ' '/^version:/{print $2}' pubspec.yaml | tr -d '\r')"
RELEASE_VERSION_BASE="${RELEASE_VERSION%%+*}"
RELEASE_TAG="v${RELEASE_VERSION_BASE}"
VERSIONED_DMG_OUT="open_yapper-${RELEASE_TAG}.dmg"
SPARKLE_ARCHIVE_OUT="open_yapper-${RELEASE_TAG}.zip"
GITHUB_FALLBACK_URL="https://github.com/Matinrahimik/open_yapper/releases/latest/download/open_yapper.dmg"

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

if [[ "$DEVELOPER_ID" != Developer\ ID\ Application:* ]]; then
  echo "Error: DEVELOPER_ID must start with 'Developer ID Application:'"
  echo "Current value: $DEVELOPER_ID"
  exit 1
fi

if [[ "$NOTARY_WAIT_MODE" != "wait" && "$NOTARY_WAIT_MODE" != "nowait" ]]; then
  echo "Error: NOTARY_WAIT_MODE must be 'wait' or 'nowait'"
  echo "Current value: $NOTARY_WAIT_MODE"
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
codesign --deep --force --options runtime --timestamp --verbose --sign "$DEVELOPER_ID" "$APP_PATH"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
# Expected to be "Unnotarized Developer ID" until the notarization step completes.
if spctl -a -vv "$APP_PATH"; then
  echo "Gatekeeper accepted app pre-notarization."
else
  echo "Gatekeeper pre-check reports unnotarized app (expected before notarization). Continuing..."
fi
echo "App signature OK"

# Create DMG
echo "Creating DMG..."
rm -f "$DMG_OUT"
hdiutil create -volname "Open Yapper" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_OUT"
cp "$DMG_OUT" "$VERSIONED_DMG_OUT"

# Create Sparkle archive (recommended for appcast generation)
echo "Creating Sparkle ZIP archive..."
rm -f "$SPARKLE_ARCHIVE_OUT"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$SPARKLE_ARCHIVE_OUT"

# Sign DMG (recommended so Gatekeeper can assess container cleanly)
echo "Signing DMG..."
codesign --force --timestamp --verbose --sign "$DEVELOPER_ID" "$DMG_OUT"
codesign --verify --strict --verbose=2 "$DMG_OUT"
codesign --force --timestamp --verbose --sign "$DEVELOPER_ID" "$VERSIONED_DMG_OUT"
codesign --verify --strict --verbose=2 "$VERSIONED_DMG_OUT"
echo "DMG signature OK"

# Notarize
echo "Submitting for notarization..."
if [[ "$NOTARY_WAIT_MODE" == "wait" ]]; then
  xcrun notarytool submit "$DMG_OUT" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait
else
  NOTARY_OUTPUT_FILE="$(mktemp -t open_yapper_notary_submit.XXXXXX)"
  xcrun notarytool submit "$DMG_OUT" \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" >"$NOTARY_OUTPUT_FILE"
  cat "$NOTARY_OUTPUT_FILE"
  SUBMISSION_ID="$(awk '/^[[:space:]]*id:/{print $2; exit}' "$NOTARY_OUTPUT_FILE")"

  echo ""
  echo "Notary submission created (async mode)."
  echo "Submission ID: ${SUBMISSION_ID:-unknown}"
  echo "Check status with:"
  echo "  xcrun notarytool info ${SUBMISSION_ID:-<submission-id>} --apple-id \"\$APPLE_ID\" --password \"\$APP_SPECIFIC_PASSWORD\" --team-id \"\$TEAM_ID\""
  echo "After status becomes Accepted, staple manually:"
  echo "  xcrun stapler staple \"$DMG_OUT\" && xcrun stapler validate \"$DMG_OUT\""
  echo "  xcrun stapler staple \"$VERSIONED_DMG_OUT\" && xcrun stapler validate \"$VERSIONED_DMG_OUT\""
  exit 0
fi

echo "Notarization complete. Stapling..."
xcrun stapler staple "$DMG_OUT"
xcrun stapler validate "$DMG_OUT"
spctl -a -vv -t open --context context:primary-signature "$DMG_OUT"
xcrun stapler staple "$VERSIONED_DMG_OUT"
xcrun stapler validate "$VERSIONED_DMG_OUT"
echo "Notarization ticket stapled and validated"

echo ""
echo "Done! Signed + notarized artifacts:"
echo "  - $DMG_OUT (stable website/latest link)"
echo "  - $VERSIONED_DMG_OUT (versioned release asset)"
echo "  - $SPARKLE_ARCHIVE_OUT (for Sparkle appcast generation)"
echo "Use release tag: $RELEASE_TAG"
echo "Keep pubspec.yaml version and GitHub tag aligned."
echo "Upload artifacts to GitHub Releases."
echo "If using Firebase Storage, set NEXT_PUBLIC_DOWNLOAD_URL to that URL."
echo "If not set, website falls back to: $GITHUB_FALLBACK_URL"
