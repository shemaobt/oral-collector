#!/usr/bin/env bash
# Set GitHub secrets for TestFlight signing (CERTIFICATES_P12_* and KEYCHAIN_PASSWORD).
# Run from repo root after exporting your Apple Distribution cert as .p12.
#
# Usage:
#   ./scripts/setup_signing_secrets.sh /path/to/distribution.p12
#   (you will be prompted for the p12 password and keychain password)
#
# Or with env vars (no prompt):
#   CERTIFICATES_P12_PASSWORD=xxx KEYCHAIN_PASSWORD=yyy ./scripts/setup_signing_secrets.sh /path/to/cert.p12

set -e
cd "$(git rev-parse --show-toplevel)"

P12_PATH="${1:-}"

if [ -z "$P12_PATH" ] || [ ! -f "$P12_PATH" ]; then
  echo "Usage: $0 /path/to/your/distribution.p12"
  echo ""
  echo "Export the cert first:"
  echo "  1. Open Keychain Access"
  echo "  2. Select 'login' and 'My Certificates'"
  echo "  3. Find 'Apple Distribution: ...' (or your team name)"
  echo "  4. Right-click → Export, save as .p12, set a password"
  echo "  5. Run: $0 /path/to/that/file.p12"
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not found. Install: https://cli.github.com/"
  exit 1
fi

if [ -z "$CERTIFICATES_P12_PASSWORD" ]; then
  echo "Enter the password you set when exporting the .p12:"
  read -rs CERTIFICATES_P12_PASSWORD
  echo ""
fi

if [ -z "$KEYCHAIN_PASSWORD" ]; then
  echo "Enter a password for CI keychain (any strong string; used only in GitHub Actions):"
  read -rs KEYCHAIN_PASSWORD
  echo ""
fi

echo "Setting CERTIFICATES_P12_BASE64..."
gh secret set CERTIFICATES_P12_BASE64 --body "$(base64 -i "$P12_PATH")"

echo "Setting CERTIFICATES_P12_PASSWORD..."
gh secret set CERTIFICATES_P12_PASSWORD --body "$CERTIFICATES_P12_PASSWORD"

echo "Setting KEYCHAIN_PASSWORD..."
gh secret set KEYCHAIN_PASSWORD --body "$KEYCHAIN_PASSWORD"

echo "Done. All three signing secrets are set. Delete the .p12 file if you saved it in a temp location."
