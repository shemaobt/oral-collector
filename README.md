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

- **Pre-commit hook:** Lint and format run automatically before each commit. Enable hooks (once per clone):
  ```bash
  git config core.hooksPath .githooks
  ```
- **Full check (manual):** `./scripts/lint.sh` — same as the pre-commit hook.
- **Analyze only:** `flutter analyze`
- **Format only:** `dart format lib/ test/`

The same checks run in CI on every push and pull request to `main` (see [.github/workflows/lint.yml](.github/workflows/lint.yml)).

## Deployment

- **iOS (TestFlight):** On push to `main`, [.github/workflows/testflight.yml](.github/workflows/testflight.yml) builds and uploads to TestFlight. See [docs/testflight-deployment.md](docs/testflight-deployment.md) for secrets and setup.
- **Web (GCP Cloud Run):** On push to `main`, [.github/workflows/deploy-web.yml](.github/workflows/deploy-web.yml) builds the web app, pushes a Docker image to Artifact Registry, and deploys to Cloud Run. See [docs/web-deployment.md](docs/web-deployment.md) for required secrets and one-time GCP setup.
