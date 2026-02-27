#!/usr/bin/env bash
# Upload IPA to App Store Connect (TestFlight) using xcrun altool.
#
# Option 1: API Key (recommended for CI)
# 1. Create API key in App Store Connect: https://appstoreconnect.apple.com/access/api
# 2. Download the .p8 file and store its contents in secret APPSTORE_API_PRIVATE_KEY
# 3. Run: ./scripts/upload_ipa.sh api <KEY_ID> <ISSUER_ID>
#    (or set env APPSTORE_API_KEY_ID, APPSTORE_ISSUER_ID and pass "api")
#
# Option 2: Apple ID
# 1. Create app-specific password: https://appleid.apple.com
# 2. Run: ./scripts/upload_ipa.sh apple "your-email@example.com" "app-specific-password"

set -e
cd "$(git rev-parse --show-toplevel)"
IPA_PATH="build/ios/ipa/oral_collector.ipa"

if [ ! -f "$IPA_PATH" ]; then
  echo "Error: IPA not found at $IPA_PATH. Run: flutter build ipa --release"
  exit 1
fi

if [ "$1" = "api" ]; then
  KEY_ID="${APPSTORE_API_KEY_ID:-$2}"
  ISSUER_ID="${APPSTORE_ISSUER_ID:-$3}"
  if [ -z "$KEY_ID" ] || [ -z "$ISSUER_ID" ]; then
    echo "Usage: $0 api <API_KEY_ID> <ISSUER_ID>"
    echo "  or set APPSTORE_API_KEY_ID, APPSTORE_ISSUER_ID and run: $0 api"
    exit 1
  fi
  if [ -z "$APPSTORE_API_PRIVATE_KEY" ]; then
    echo "Set APPSTORE_API_PRIVATE_KEY (contents of .p8 file) for API upload."
    exit 1
  fi
  KEY_DIR="$HOME/.appstoreconnect/private_keys"
  mkdir -p "$KEY_DIR"
  echo "$APPSTORE_API_PRIVATE_KEY" > "$KEY_DIR/AuthKey_${KEY_ID}.p8"
  echo "Uploading with API Key..."
  xcrun altool --upload-app --type ios -f "$IPA_PATH" --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"
elif [ "$1" = "apple" ]; then
  if [ -z "$2" ] || [ -z "$3" ]; then
    echo "Usage: $0 apple <APPLE_ID_EMAIL> <APP_SPECIFIC_PASSWORD>"
    exit 1
  fi
  echo "Uploading with Apple ID..."
  xcrun altool --upload-app --type ios -f "$IPA_PATH" -u "$2" -p "$3"
else
  echo "Usage:"
  echo "  API Key:  $0 api <KEY_ID> <ISSUER_ID>"
  echo "  Apple ID: $0 apple <EMAIL> <APP_SPECIFIC_PASSWORD>"
  exit 1
fi
