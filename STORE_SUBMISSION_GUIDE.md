# App Store & Google Play Submission Guide

Everything below requires **your manual action** and cannot be automated through code changes alone.

---

## 1. Android Release Keystore (BLOCKING - Google Play)

Google Play requires a release signing key. A `key.properties.example` file has been created.

**Steps:**

```bash
# 1. Generate a keystore (use your real name/org info)
keytool -genkey -v \
  -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Joao Victor Carvalho, OU=Shema, O=Shema OBT, L=City, ST=State, C=BR"

# 2. Create key.properties from the example
cp android/key.properties.example android/key.properties

# 3. Edit android/key.properties with your actual passwords
# storePassword=YOUR_STORE_PASSWORD
# keyPassword=YOUR_KEY_PASSWORD
# keyAlias=upload
# storeFile=../upload-keystore.jks

# 4. Verify it builds
flutter build appbundle --release
```

**IMPORTANT:** Back up `upload-keystore.jks` securely. If lost, you cannot push updates to the same app listing.

---

## 2. Asset Image Compression (RECOMMENDED - Both stores)

Current app assets total ~23 MB. This inflates your APK/IPA size significantly.

| File | Current Size | Target Size |
|------|-------------|-------------|
| `assets/app_icon.png` | 6.7 MB | < 500 KB |
| `assets/hero_hands.png` | 4.9 MB | < 300 KB |
| `assets/hero_listen.png` | 4.5 MB | < 300 KB |
| `assets/hero_woman.png` | 3.8 MB | < 300 KB |
| `assets/hero_wide.png` | 1.8 MB | < 200 KB |
| `assets/hero_heart.png` | 1.7 MB | < 200 KB |

**Steps:**

```bash
# Option A: Use TinyPNG CLI (npm install -g tinypng-cli)
tinypng assets/*.png

# Option B: Use Squoosh (https://squoosh.app)
# Upload each image, choose WebP or optimized PNG, download replacements

# Option C: Convert to WebP (better compression)
# After converting, update pubspec.yaml asset references from .png to .webp

# After compression, regenerate launcher icons:
dart run flutter_launcher_icons
```

---

## 3. Privacy Policy (BLOCKING - Both stores)

Both Apple and Google require a privacy policy URL for apps that collect user data.

**What your privacy policy must cover:**
- Data collected: audio recordings, email address, display name, project metadata, photos
- Purpose: language documentation and preservation
- Data storage: encrypted on device (FlutterSecureStorage), transmitted via HTTPS to `tripod-backend.shemaywam.com`
- Data sharing: not shared with third parties
- Data retention: how long recordings are stored, when they are deleted
- User rights: how to request data deletion or export
- Contact information: email for privacy inquiries

**Steps:**

1. Write your privacy policy (use a template from [Termly](https://termly.io), [Privacy Policy Generator](https://www.privacypolicygenerator.info/), or consult legal counsel)
2. Host it on a public URL (e.g., `https://shemaywam.com/privacy-policy`)
3. Add the URL to:
   - **Apple App Store Connect** -> App Information -> Privacy Policy URL
   - **Google Play Console** -> Store Listing -> Privacy Policy URL
4. Optionally add a link in the app's profile screen (About section)

---

## 4. Terms of Service (RECOMMENDED - Both stores)

Recommended for compliance, especially if operating in the EU (GDPR).

**Steps:**

1. Write Terms of Service covering:
   - Acceptable use of the recording tool
   - User-generated content ownership
   - Account termination conditions
   - Limitation of liability
2. Host alongside your privacy policy
3. Add a "Terms of Service" link in your app's About/Profile section

---

## 5. Account Deletion (BLOCKING - Apple App Store)

**Apple Guideline 5.1.1(v):** Apps that support account creation must also support account deletion.

**Backend work required:**

```
# Add endpoint to your tripod-backend:
DELETE /api/auth/me
# Should:
# 1. Delete user's recordings from GCS
# 2. Delete user's project memberships
# 3. Delete user account from database
# 4. Return 200 OK
```

**Frontend work required:**

1. Add `deleteAccount(String accessToken)` method to `lib/core/auth/auth_repository.dart`:
```dart
Future<void> deleteAccount(String accessToken);
```

2. Add implementation in `lib/features/auth/data/repositories/auth_repository_impl.dart`:
```dart
@override
Future<void> deleteAccount(String accessToken) async {
  final response = await _client.delete(
    Uri.parse('$_baseUrl/api/auth/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
  );
  guardResponse(response);
}
```

3. Add to `lib/core/auth/auth_notifier.dart`:
```dart
Future<void> deleteAccount() async {
  final token = await _storage.read(key: _accessTokenKey);
  if (token == null) return;
  await _repo.deleteAccount(token);
  await _clearTokens();
  state = const AuthState();
}
```

4. Add a "Delete Account" button in `lib/features/profile/presentation/profile_screen.dart` (in the Account section, below the logout button) with a **two-step confirmation dialog** that:
   - First dialog: warns this is irreversible
   - Second dialog: requires typing "DELETE" to confirm

5. Add l10n keys for all 10 locales:
   - `profile_deleteAccount`
   - `profile_deleteAccountConfirm`
   - `profile_deleteAccountWarning`
   - `profile_typeDelete`

---

## 6. Forgot Password / Password Reset (RECOMMENDED - Both stores)

Users who forget their password currently have no recovery path.

**Backend work required:**

```
# Add endpoints to tripod-backend:
POST /api/auth/forgot-password   { "email": "user@example.com" }
POST /api/auth/reset-password    { "token": "...", "new_password": "..." }
```

**Frontend work required:**

1. Create `lib/features/auth/presentation/forgot_password_screen.dart`
   - Email input field
   - "Send Reset Link" button
   - Success message: "Check your email for reset instructions"

2. Add a "Forgot Password?" link in `lib/features/auth/presentation/widgets/login_form.dart` below the password field

3. Add route in `lib/core/router/app_router.dart`:
```dart
GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
```

4. Add l10n keys for all 10 locales

---

## 7. iOS Launch Screen Branding (RECOMMENDED - Apple)

Currently shows a plain white screen during app launch.

**Steps:**

1. Create a 1x, 2x, 3x version of your app logo (transparent PNG):
   - `LaunchImage.png` (320x320)
   - `LaunchImage@2x.png` (640x640)
   - `LaunchImage@3x.png` (960x960)

2. Place them in `ios/Runner/Assets.xcassets/LaunchImage.imageset/`

3. Update `ios/Runner/Base.lproj/LaunchScreen.storyboard`:
   - Set the background color to match your app theme (`#EEEADD` for light)
   - Center the LaunchImage on screen

4. Alternatively, open the project in Xcode and use the visual storyboard editor

---

## 8. Data Export / GDPR Compliance (RECOMMENDED - EU markets)

GDPR Article 20 requires data portability — users must be able to export their data.

**Backend work required:**

```
# Add endpoint:
GET /api/auth/me/export
# Returns a ZIP containing:
# - user_profile.json (email, name, created_at)
# - recordings/ (all audio files)
# - metadata.json (recording titles, dates, genres, durations)
```

**Frontend work required:**

1. Add "Export My Data" button in profile screen
2. Show progress indicator during export
3. Use `share_plus` package to share the downloaded ZIP

---

## 9. Store Listing Checklist

### Apple App Store Connect
- [ ] App name: "Oral Collector"
- [ ] Bundle ID: matches `com.shema.oralCollector` (set in Xcode)
- [ ] Screenshots: 6.7" (iPhone 15 Pro Max), 6.1" (iPhone 15), 12.9" iPad Pro
- [ ] App description (localized in all supported languages)
- [ ] Keywords
- [ ] Category: Education or Utilities
- [ ] Privacy Policy URL
- [ ] Age Rating: 4+ (no objectionable content)
- [ ] App Review Information: test account credentials for reviewers
- [ ] Contact info for reviewer questions

### Google Play Console
- [ ] App name: "Oral Collector"
- [ ] Package name: `com.shema.oralCollector`
- [ ] Screenshots: phone (min 2), 7" tablet, 10" tablet
- [ ] Feature graphic (1024x500)
- [ ] Short description (80 chars max)
- [ ] Full description
- [ ] Category: Education
- [ ] Content rating questionnaire (complete in Play Console)
- [ ] Privacy Policy URL
- [ ] Data Safety section (declare: audio, email, name collected for app functionality)
- [ ] Target audience: 18+ (or specify age group)
- [ ] Signed AAB uploaded (from `flutter build appbundle --release`)

---

## 10. Pre-Submission Testing Checklist

```bash
# Build release versions
flutter build appbundle --release    # Android AAB
flutter build ipa --release          # iOS IPA (requires Mac + Xcode)

# Test on real devices
# - Record audio, verify playback
# - Import a file, verify it appears in list
# - Upload recording while online
# - Record while offline, then go online (verify auto-sync)
# - Login, logout, login again
# - Deny microphone permission, verify dialog appears
# - Test all 10 languages
# - Test dark mode
# - Test on tablet (iPad / Android tablet)
# - Test low storage scenario
# - Kill app during recording, reopen
# - Test with slow network (throttle to 3G)
```

---

## Priority Order

| Priority | Item | Blocking? |
|----------|------|-----------|
| 1 | Release keystore | YES (Google Play) |
| 2 | Privacy policy | YES (Both stores) |
| 3 | Account deletion | YES (Apple) |
| 4 | Asset compression | NO but strongly recommended |
| 5 | Forgot password | NO but impacts UX |
| 6 | iOS launch screen | NO but impacts first impression |
| 7 | Terms of Service | NO but recommended for EU |
| 8 | Data export | NO but required for GDPR |
