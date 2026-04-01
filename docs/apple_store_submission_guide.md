# Oral Collector - Apple App Store Submission Guide

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Enable GitHub Pages (Privacy Policy)](#2-enable-github-pages)
3. [App Store Connect - Step by Step](#3-app-store-connect)
4. [Screenshots](#4-screenshots)
5. [App Privacy Section](#5-app-privacy)
6. [App Review Information](#6-app-review)
7. [Submit for Review](#7-submit)
8. [After Submission](#8-after-submission)

---

## 1. Prerequisites

Before submitting, make sure you have:

- [x] Apple Developer account (you already have one - logged in as Joao Victor Carvalho)
- [x] App created in App Store Connect (Oral Collector - already exists)
- [x] Build uploaded via TestFlight (Build 24 - v1.0.0 - already uploaded)
- [x] Account deletion feature implemented (just added)
- [ ] Privacy policy hosted (see Section 2)
- [ ] Screenshots captured (see Section 4)
- [ ] All fields filled in App Store Connect (see Section 3)
- [ ] Backend: implement `DELETE /api/auth/me` endpoint (deletes user account but preserves uploaded recordings)

### Backend Endpoint Required

You need to add this endpoint to your tripod-backend before the app goes live:

```
DELETE /api/auth/me
Authorization: Bearer <access_token>

Behavior:
- Delete user account from database
- Delete user's project memberships
- DO NOT delete user's uploaded audio recordings (preserve for language projects)
- Return 200 OK
```

---

## 2. Enable GitHub Pages

The privacy policy page has been created at `docs/index.html`. To host it:

1. Push this branch to GitHub
2. Go to https://github.com/shemaobt/oral-collector/settings/pages
3. Under "Source", select **Deploy from a branch**
4. Select branch: **main**, folder: **/docs**
5. Click **Save**
6. Wait 1-2 minutes. Your privacy policy will be live at:
   **https://shemaobt.github.io/oral-collector/**

Use this URL in App Store Connect for the Privacy Policy URL field.

---

## 3. App Store Connect - Field by Field

Go to https://appstoreconnect.apple.com > **Oral Collector** > **Distribution**

### iOS App Version 1.0

#### Previews and Screenshots
See Section 4 below for details on which screenshots to capture.

#### Promotional Text (170 chars max)
```
Record and preserve oral language data for documentation projects. Supports 10 languages with offline recording and automatic cloud sync.
```

#### Description (4000 chars max)
```
Oral Collector is a mobile app designed for language documentation and preservation. Created by Shema OBT, it enables researchers, linguists, and community members to record, organize, and upload oral language data for documentation projects.

KEY FEATURES:

- Audio Recording: Record oral language samples directly from your device with a simple, intuitive interface
- Quick Record: Start recording instantly with a single tap
- Genre Classification: Organize recordings by genre, subcategory, and register for systematic documentation
- Multi-Project Support: Participate in multiple language documentation projects
- Offline First: Record anywhere, even without internet. Recordings sync automatically when you're back online
- Cloud Sync: Securely upload recordings to the cloud with automatic background synchronization
- Audio Trimming: Edit and trim your recordings before uploading
- File Import: Import existing audio files into your projects
- Multilingual Interface: Available in 10 languages - English, Spanish, French, Portuguese, Arabic, Hindi, Indonesian, Korean, Swahili, and Tok Pisin
- Dark Mode: Full support for light and dark themes
- Storage Management: Monitor your local storage usage and manage cached files

Oral Collector is built for the language documentation community. Whether you're a field linguist, a language project coordinator, or a community member contributing to the preservation of your language, Oral Collector provides the tools you need to capture and organize oral data effectively.

Your recordings contribute to the collective effort of language preservation and documentation for future generations.
```

#### Keywords (100 chars max, comma-separated)
```
language,documentation,audio,recording,oral,preservation,linguistics,fieldwork,research
```

#### Support URL
```
https://shemaobt.github.io/oral-collector/
```
(Same as privacy policy page, or create a separate support page later)

#### Marketing URL (optional)
Leave blank or use your organization's website if available.

#### Version
```
1.0
```

#### Copyright
```
2026 Shema OBT
```

#### Build
Click the **+** button next to "Build" and select **Build 24 (1.0.0)**

---

## 4. Screenshots

You need screenshots for **iPhone 6.5" Display** (required). Sizes accepted:
- 1242 x 2688 px (iPhone 11 Pro Max / XS Max)
- 1284 x 2778 px (iPhone 12/13/14 Pro Max)
- 1290 x 2796 px (iPhone 15 Pro Max)

### How to Take Screenshots

**Option A: From iOS Simulator**
```bash
# Open the simulator with an iPhone 15 Pro Max
open -a Simulator
# Run the app
flutter run

# Take screenshot (from another terminal)
xcrun simctl io booted screenshot ~/Desktop/screenshot_1.png
```

**Option B: From a Real Device**
Press the side button + volume up simultaneously on your iPhone.

### Which Screens to Capture (minimum 3, recommended 5)

1. **Home Screen** - Shows the dashboard with project name, stats (recordings count, duration, members), and genre cards. This is your hero screenshot.

2. **Recording Screen** - Show the recording interface with the microphone button active and waveform visualization. Demonstrates the core functionality.

3. **Recordings List** - Display a list of several recordings with genre tags, durations, and status indicators. Shows organization capabilities.

4. **Genre Selection / Recording Flow** - The multi-step flow where users select genre, subcategory, and register. Shows the classification system.

5. **Profile Screen** - Shows the user profile with multilingual support, sync settings, and storage usage.

### Tips for Better Screenshots
- Use realistic data (have some test recordings already created)
- Use the app in light mode for cleaner screenshots
- Make sure the status bar shows a good time (like 9:41 AM - Apple's standard)
- No personal information visible

---

## 5. App Privacy Section

Go to **App Store Connect** > **Oral Collector** > **General** > **App Privacy**

### Data Types to Declare

Click "Get Started" and declare:

| Data Type | Category | Linked to User? | Used for Tracking? |
|-----------|----------|-----------------|-------------------|
| Audio Data | Audio Data | Yes | No |
| Email Address | Contact Info | Yes | No |
| Name | Contact Info | Yes | No |
| Photos | Photos or Videos | Yes | No |

For each data type:
- **Purpose**: Select "App Functionality"
- **Linked to User**: Yes
- **Used for Tracking**: No

---

## 6. App Review Information

Scroll down on the Distribution page to "App Review Information":

### Sign-In Information
- **Sign-in required**: Yes (keep checked)
- **Username**: Enter your test account email
- **Password**: Enter your test account password

### Contact Information
- **First name**: Joao
- **Last name**: Victor Carvalho de Oliveira
- **Phone number**: Your phone number
- **Email**: Your email address

### Notes for Reviewer
```
Oral Collector is an audio recording app for language documentation projects.

To test the app:
1. Log in with the provided test credentials
2. You will see the home dashboard with an active project
3. Tap the floating record button (microphone icon) to start recording
4. Grant microphone permission when prompted
5. Record a short audio sample, then tap stop
6. The recording will appear in your recordings list
7. You can classify, trim, and upload recordings

The app requires microphone access to function. It works offline and syncs recordings when online.

Account deletion is available in Profile > Account > Delete Account.
```

### App Store Version Release
- Select **"Manually release this version"** (recommended for your first release so you can control when it goes live)

---

## 7. Submit for Review

1. Double-check all fields are filled (the page will show warnings for missing items)
2. Make sure you've selected Build 24 under the "Build" section
3. Click **"Save"** in the top right
4. Click **"Add for Review"** in the top right
5. On the submission confirmation page, review everything
6. Click **"Submit to App Review"**

---

## 8. After Submission

### Timeline
- Apple review typically takes **24-48 hours** (sometimes up to 7 days for first submissions)
- You'll receive an email notification when the review is complete

### If Approved
- If you chose "Manually release", go to App Store Connect and click "Release this version"
- The app will be live on the App Store within a few hours

### If Rejected
- Apple will provide specific reasons in the Resolution Center
- Common first-submission issues:
  - Missing privacy policy URL (we've set this up)
  - Account deletion not working (make sure backend endpoint is deployed)
  - Reviewer couldn't log in (verify test credentials work)
  - App crashes on reviewer's device (test on real hardware)
- Fix the issues, upload a new build if needed, and resubmit

### Post-Launch Checklist
- [ ] Verify the app is searchable on the App Store
- [ ] Test downloading and installing from the App Store
- [ ] Monitor crash reports in App Store Connect > Feedback > Crashes
- [ ] Respond to any user reviews

---

## Quick Reference: What to Fill Where

| App Store Connect Location | What to Enter |
|---------------------------|---------------|
| Distribution > Screenshots | 3-5 iPhone screenshots (see Section 4) |
| Distribution > Promotional Text | Short tagline (see Section 3) |
| Distribution > Description | Full description (see Section 3) |
| Distribution > Keywords | language,documentation,audio,recording,oral,preservation,linguistics,fieldwork,research |
| Distribution > Support URL | https://shemaobt.github.io/oral-collector/ |
| Distribution > Version | 1.0 |
| Distribution > Copyright | 2026 Shema OBT |
| Distribution > Build | Build 24 (1.0.0) |
| Distribution > App Review | Test credentials + notes (see Section 6) |
| General > App Information > Category | Education |
| General > App Information > Content Rights | Does not contain third-party content |
| General > App Information > Age Rating | 4+ |
| General > App Information > Privacy Policy URL | https://shemaobt.github.io/oral-collector/ |
| Trust & Safety > App Privacy | See Section 5 |
| Pricing and Availability | Free |
