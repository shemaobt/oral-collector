# ADR-0009: Release obfuscation

- Status: Accepted
- Date: 2026-06-09
- Epic: E6 (Security)
- Related: ENG-127, ADR-0005

## Context

Release builds shipped un-obfuscated Dart: `ios/Flutter/Generated.xcconfig` carried
`DART_OBFUSCATION=false` and neither release workflow passed `--obfuscate`. The AOT
artifacts therefore exposed original class and function names, making the shipped binaries
easier to reverse-engineer. We want defense-in-depth name mangling on the store builds
while keeping the ability to de-obfuscate production crash traces.

Two constraints shape the approach:

- **iOS signing.** `testflight.yml` does not run a plain build. It manually signs *two*
  targets with separate provisioning profiles — `Runner` and
  `RecordingLiveActivityWidgetExtension` (the Live Activity) — which is why it uses
  `flutter build ios --release --config-only` followed by a hand-written `xcodebuild
  archive`/`-exportArchive` against `ios/ExportOptions.plist` (`signingStyle=manual`). That
  flow must not be disturbed.
- **Symbol survivability.** Obfuscated stack traces are useless without the matching
  `--split-debug-info` symbol files, so those must be retained per release.

## Decision

Enable Dart obfuscation on the Android (AAB) and iOS release builds via
`--obfuscate --split-debug-info=build/symbols`, and archive the symbol maps as CI
artifacts.

- **Android** (`google-play.yml`): append the flags to `flutter build appbundle --release`.
- **iOS** (`testflight.yml`): append the flags to the existing
  `flutter build ios --release --config-only` step. Flutter writes `DART_OBFUSCATION=true`
  and `SPLIT_DEBUG_INFO=…` into `Generated.xcconfig`; `xcode_backend.dart` reads them and
  forwards `-dDartObfuscation`/`-dSplitDebugInfo` to `flutter assemble` during the
  subsequent `xcodebuild archive`, which performs the obfuscation and emits
  `app.ios-arm64.symbols`. We deliberately **keep** `--config-only` + `xcodebuild` and do
  **not** switch to `flutter build ipa`, which would risk the widget extension's manual
  signing for no obfuscation benefit. The split-debug path is absolute
  (`$GITHUB_WORKSPACE/build/symbols`) to avoid xcodebuild working-directory ambiguity.
- **Symbols**: each workflow uploads `build/symbols/` via `actions/upload-artifact@v4`
  (`name: <platform>-symbols-<run>`, `retention-days: 90`, `if-no-files-found: error`).
- **Web** (`deploy-web.yml`): no change. Flutter web has no `--obfuscate`; the release web
  compiler minifies instead. A comment in the workflow records this.
- **R8 (later enabled by ENG-133).** This ADR originally left Java/Kotlin shrinking
  (`isMinifyEnabled`/`isShrinkResources`) off. ENG-133 enabled R8 on the release build
  (`proguard-android-optimize.txt` + the existing `proguard-rules.pro`); it is an
  independent layer from Dart obfuscation. See ADR-0005 / ENG-133.

## Consequences

- Store-distributed Android/iOS releases obfuscate Dart symbols. This is a deterrent, not a
  security guarantee — obfuscation does not encrypt code or hide bundled secrets.
- Release crash traces are obfuscated. De-obfuscate with the symbols artifact from the
  matching CI run:
  `flutter symbolize -i trace.txt -d build/symbols/app.<platform>-<arch>.symbols`.
- **Retention risk.** CI artifacts retain 90 days, but a store build can crash months
  later. To de-obfuscate an older release you must download and durably store its symbols
  artifact at release time. Follow-up (out of scope here): persist per-release symbols to
  durable storage.
- `if-no-files-found: error` makes a misconfigured symbol path fail the release loudly
  instead of silently shipping without symbols.
- These workflows only run on push to `main` (and `workflow_dispatch` for TestFlight) and
  perform real store uploads, so the change cannot be dry-run in CI without a real release;
  it is verified by local builds (`build/symbols` populated; `Generated.xcconfig` shows
  `DART_OBFUSCATION=true`).
