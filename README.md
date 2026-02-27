# Oral Collector

Mobile and web app (Oral Capture) for collecting monolingual audio data. Supports iOS, Android, and web.

See [AGENTS.md](AGENTS.md) for project conventions and agent guidelines.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10+)
- For **iOS**: Xcode and CocoaPods
- For **Android**: Android Studio and Android SDK
- For **web**: Chrome (for running and building)

## Setup

1. Clone the repo and open the project directory.
2. Copy `.env.example` to `.env` and set any required values (e.g. `BACKEND_URL=` when you have a backend).
3. Install dependencies:

   ```bash
   flutter pub get
   ```

## Run

- **Web (Chrome):**  
  `flutter run -d chrome`

- **iOS (simulator or device):**  
  `flutter run -d ios`

- **Android (emulator or device):**  
  `flutter run -d android`

- **Default device:**  
  `flutter run`

## Build

- **Android (APK):**  
  `flutter build apk`

- **iOS:**  
  `flutter build ios`  
  (or `flutter build ipa` for App Store archive)

- **Web:**  
  `flutter build web`  
  Output is in `build/web/`.

## Lint and format

- Analyze: `flutter analyze`
- Format: `dart format lib/`
