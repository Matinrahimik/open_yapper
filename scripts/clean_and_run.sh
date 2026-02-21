#!/bin/bash
# Full cleanup and debug run for Open Yapper
# Use this when permissions aren't being recognized (macOS requires app restart after granting Accessibility)

set -e
cd "$(dirname "$0")/.."

echo "==> Stopping any running instances..."
pkill -f "open_yapper" 2>/dev/null || true
pkill -f "Open Yapper" 2>/dev/null || true
sleep 1

echo "==> Flutter clean..."
flutter clean

echo "==> Clearing app preferences (onboarding state, etc.)..."
defaults delete com.matin.openYapper 2>/dev/null || true
defaults delete com.example.openYapper 2>/dev/null || true

echo "==> Resetting Accessibility permission (removes app from list - you'll re-add when prompted)..."
tccutil reset Accessibility com.matin.openYapper 2>/dev/null || true
tccutil reset Accessibility com.example.openYapper 2>/dev/null || true

echo ""
echo "==> Running in debug mode..."
echo "    Note: After granting Accessibility in System Settings, you MUST restart"
echo "    the app for it to be recognized (macOS limitation)."
echo ""
flutter run -d macos
