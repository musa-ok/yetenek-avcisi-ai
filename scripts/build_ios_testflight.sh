#!/usr/bin/env bash
# Scoutiq — TestFlight IPA build (release → production API)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT/yetenek_avcisi"

cd "$APP_DIR"

echo "==> Flutter clean + pub get"
flutter clean
flutter pub get

echo "==> CocoaPods"
cd ios
pod install
cd ..

echo "==> Analyze (non-blocking warnings OK)"
flutter analyze || true

echo "==> Release IPA (API: production default)"
flutter build ipa --release \
  --dart-define=API_BASE_URL=https://stingray-app-g3o9y.ondigitalocean.app

IPA_DIR="$APP_DIR/build/ios/ipa"
echo ""
echo "Done. Upload with Transporter or Xcode Organizer:"
ls -la "$IPA_DIR"/*.ipa 2>/dev/null || find "$IPA_DIR" -name '*.ipa' -print
