# TestFlight deployment (optimized)

This doc describes the automated TestFlight workflow (triggered on merge to `main`), how to create the required App Store Connect API key with your Apple account, and how to run uploads locally with the Xcode CLI (`xcrun altool`).

## CI workflow (merge to main)

The workflow [.github/workflows/testflight.yml](../.github/workflows/testflight.yml) runs **only when code is pushed to `main`** (e.g. after a PR is merged). It:

1. Uses a `macos-14` runner.
2. Caches Flutter SDK and CocoaPods to speed up builds.
3. Imports the distribution certificate and **provisioning profile** from secrets, then builds the IPA with manual signing (no Apple account needed in CI).
4. Uploads the IPA to TestFlight using **xcrun altool** with your App Store Connect API key.

You must add the required secrets (API key, certificate, and **provisioning profile**) to the repo before the workflow can succeed.

## Create App Store Connect API key (your Apple account)

Do this once with your Apple ID; the key is used by the workflow and by the local upload script.

1. **Open App Store Connect**
   - Go to [App Store Connect](https://appstoreconnect.apple.com) and sign in with your Apple account.

2. **Create an API key**
   - Go to **Users and Access** → **Integrations** → **App Store Connect API** (or [direct link Keys](https://appstoreconnect.apple.com/access/integrations/api)).
   - Click **Generate API Key** (or the + button).
   - Name it (e.g. `oral-collector-ci`), choose role **App Manager** (or **Admin**), then **Generate**.
   - **Download the .p8 file** — you can only do this once. Store it safely.

3. **Note the IDs**
   - **Key ID** — shown in the key list (e.g. `ABC123XYZ`).
   - **Issuer ID** — at the top of the App Store Connect API page (e.g. `12345678-1234-1234-1234-123456789012`).

4. **Add GitHub secrets**
   - Repo → **Settings** → **Secrets and variables** → **Actions**.
   - **New repository secret** for each:
     - `APPSTORE_API_KEY_ID` — the Key ID from step 3.
     - `APPSTORE_ISSUER_ID` — the Issuer ID from step 3.
     - `APPSTORE_API_PRIVATE_KEY` — **entire contents** of the downloaded `.p8` file (copy-paste, including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`).

## Signing certificate (for CI build)

The workflow signs the app using a distribution certificate stored in GitHub secrets. Do this once on a Mac where the app is already set up for App Store distribution.

### Step 1: Export the certificate from Keychain Access

1. Open **Keychain Access** (Spotlight → “Keychain Access”).
2. In the sidebar, select **login** and **My Certificates**.
3. Find **Apple Distribution: …** (or your team/name). If you don’t see it, select **All Items** and search for “Apple Distribution”.
4. Right‑click the certificate → **Export "Apple Distribution: …"**.
5. Save as a `.p12` file (e.g. on Desktop). Choose a **password** when asked and remember it.
6. Keep the file somewhere safe temporarily; you’ll delete it after running the script.

### Step 2: Add the three secrets with the helper script

From the repo root, run (use the path where you saved the .p12):

```bash
./scripts/setup_signing_secrets.sh /path/to/your/certificate.p12
```

The script will prompt for:

- **P12 password** — the password you set when exporting the .p12.
- **Keychain password** — any strong string (used only by CI; e.g. a random password).

It then sets the three GitHub secrets: `CERTIFICATES_P12_BASE64`, `CERTIFICATES_P12_PASSWORD`, `KEYCHAIN_PASSWORD`.

**Without prompts** (e.g. in a script):

```bash
CERTIFICATES_P12_PASSWORD="your-p12-password" KEYCHAIN_PASSWORD="ci-keychain-password" ./scripts/setup_signing_secrets.sh /path/to/certificate.p12
```

After this, delete the .p12 file from your Mac when done.

## Provisioning profile (for CI build)

CI has no Apple ID, so Xcode cannot use “automatic” signing. The workflow uses **manual** signing with an **App Store distribution provisioning profile** for the app’s bundle ID (`com.example.oralCollector`).

### Step 1: Create the profile in Apple Developer

1. Go to [Apple Developer → Certificates, Identifiers & Profiles → Profiles](https://developer.apple.com/account/resources/profiles/list).
2. Click **+** to create a new profile.
3. Choose **App Store** under Distribution → **Continue**.
4. Select the **App ID** for this app (`com.example.oralCollector`). Create the App ID first if it does not exist (Identifiers → App IDs).
5. Select the **distribution certificate** you use for this app (the same one you exported as .p12).
6. Name the profile (e.g. `Oral Collector App Store`) and **Generate**.
7. **Download** the `.mobileprovision` file.

### Step 2: Add the profile as a GitHub secret

Encode the profile and add it as a repository secret:

```bash
base64 -i path/to/your/profile.mobileprovision | pbcopy
```

Then in the repo: **Settings → Secrets and variables → Actions → New repository secret**. Name: `PROVISIONING_PROFILE_BASE64`, value: paste the base64 string.

After this, the TestFlight workflow can build the IPA on push to `main`. Do not commit the `.mobileprovision` file.

## Local upload with Xcode CLI (xcrun altool)

After building an IPA locally (`flutter build ipa --release`), you can upload it with the script that uses **xcrun altool** (same as in CI).

**Using API key (recommended):**
```bash
export APPSTORE_API_PRIVATE_KEY="$(cat /path/to/AuthKey_KEYID.p8)"
./scripts/upload_ipa.sh api YOUR_KEY_ID YOUR_ISSUER_ID
```

**Using Apple ID (app-specific password):**
```bash
./scripts/upload_ipa.sh apple "your-email@example.com" "your-app-specific-password"
```

App-specific passwords are created at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords.

## Files in this repo

| File | Purpose |
|------|---------|
| [.github/workflows/testflight.yml](../.github/workflows/testflight.yml) | Runs on push to `main`: build IPA, upload to TestFlight via `xcrun altool`. |
| [scripts/upload_ipa.sh](../scripts/upload_ipa.sh) | Local upload using `xcrun altool` (API key or Apple ID). |
| [ios/ExportOptions.plist](../ios/ExportOptions.plist) | Export options for app-store (team ID, signing style). Used when exporting from Xcode or by Flutter. |

## Optimizations in place

- **Trigger:** Only on push to `main` (no tag or schedule), so only merges to main produce a TestFlight build.
- **Caching:** Flutter (via `subosito/flutter-action` with `cache: true`) and CocoaPods (via `actions/cache` on `Podfile.lock`).
- **Upload:** `xcrun altool` with API key (no Apple ID in CI).
- **Pods:** `ENV['COCOAPODS_DISABLE_STATS'] = 'true'` in the Podfile reduces pod install latency.

## References

- [Flutter: Build and release an iOS app](https://docs.flutter.dev/deployment/ios)
- [App Store Connect API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
- [Upload with altool](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow#3087734)
