# ADR-0005: Security policy

- Status: Proposed
- Date: 2026-06-04
- Epic: E6 (Security)
- Related: ENG-90, ADR-0000

## Context

Security practices — secret storage, token handling, transport, and what may be
logged — are applied case by case without a documented policy. Wave 1 E6
defines the security policy the app follows.

## Decision

The full security policy is still being defined by E6 (ENG-90). Specific
decisions are recorded here as their features land:

### Client-bundle configuration and secrets (ENG-126)

- No secrets and no `.env` file are shipped in the client bundle (APK/IPA or the
  public web build); `.env` must never be a Flutter asset.
- Non-secret build configuration (e.g. the backend URL) is resolved at compile
  time via `--dart-define` / `--dart-define-from-file`, read with
  `String.fromEnvironment` in `core/config/env.dart`. Release pins the
  production value; debug/profile builds may override it.
- `--dart-define` values are compiled into the binary and are extractable
  (especially from the web bundle), so they are for non-secret config only. Real
  secrets stay server-side or in `flutter_secure_storage` at runtime.

## Consequences

- The backend URL is a non-secret compile-time constant; pointing a debug build
  at a local backend is a build-time flag, not a runtime or bundled file.
- A future real secret must not reuse the bundled-`.env` pattern; it requires a
  server-side or secure-storage mechanism, to be specified by the broader E6
  policy (ENG-90).
