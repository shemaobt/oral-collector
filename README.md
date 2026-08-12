# Oral Collector

Mobile and web app (Oral Capture) for collecting monolingual audio data. Supports iOS, Android, and web.

See [AGENTS.md](AGENTS.md) for project conventions and agent guidelines, and [docs/adr/](docs/adr/ADR-0000-process.md) for architecture decisions.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10+)
- For **iOS**: Xcode and CocoaPods
- For **Android**: Android Studio and Android SDK
- For **web**: Chrome (for running and building)

## Setup

1. Clone the repo and open the project directory.
2. (Optional, debug only) To point at a local backend, copy `.env.example` to `.env` and set `BACKEND_URL`. It is read at build time via `--dart-define-from-file=.env` (see Run) and is never bundled into the app. Without it, builds use the production backend.
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

- **Local backend (debug):**  
  `flutter run --dart-define-from-file=.env` (or `--dart-define=BACKEND_URL=http://host:port`)

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
- **Analyze only:** `flutter analyze --no-fatal-infos` (strict lints are staged at `info`; see [ADR-0007](docs/adr/ADR-0007-lint-baseline.md))
- **Riverpod lints:** `fvm dart run custom_lint`
- **Format only:** `fvm dart format lib/ test/`

> Run these through `fvm` locally. The project's SDK is pinned by FVM, so an
> unprefixed `dart` is FVM's `stable` channel: it downgrades the packages the
> Flutter SDK pins in `pubspec.lock`, and the downgraded `matcher` then breaks
> compilation inside a test run that is already going — which reads as a bug in
> `semantics.dart` and is not one. CI has no FVM and is right to omit the
> prefix; `scripts/lint.sh` and `scripts/check_metrics.sh` add it themselves.

Format, analyze, and the full test suite (`flutter test`) run in CI on every pull request to `main` and `dev` (see [.github/workflows/lint.yml](.github/workflows/lint.yml) and [.github/workflows/test.yml](.github/workflows/test.yml)).

## Deployment

- **iOS (TestFlight):** On push to `main`, [.github/workflows/testflight.yml](.github/workflows/testflight.yml) builds and uploads to TestFlight. See [docs/testflight-deployment.md](docs/testflight-deployment.md) for secrets and setup.
- **Web (GCP Cloud Run):** On push to `main`, [.github/workflows/deploy-web.yml](.github/workflows/deploy-web.yml) builds the web app, pushes a Docker image to Artifact Registry, and deploys to Cloud Run. See [docs/web-deployment.md](docs/web-deployment.md) for required secrets and one-time GCP setup.
- **Release obfuscation:** Android and iOS release builds obfuscate Dart code (`--obfuscate`); the split-debug-info symbol maps are archived as CI artifacts (`android-symbols-<run>` / `ios-symbols-<run>`) so crash traces can be de-obfuscated with `flutter symbolize`. Web is minified, not obfuscated. See [ADR-0009](docs/adr/ADR-0009-release-obfuscation.md).
