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

### Secure storage — iOS Keychain accessibility (ENG-128)

- The runtime secret store (`flutter_secure_storage`, holding the access/refresh
  tokens and the cached user) pins the iOS Keychain accessibility to
  `first_unlock_this_device` (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`)
  via explicit `IOSOptions` in `core/providers/secure_storage_provider.dart`. The
  items are bound to the device (not migrated to a new device or included in
  backups) and stay readable in the background after the first unlock; the
  previous default (`whenUnlocked`) is unreadable while the device is locked,
  which can break background uploads.
- Android intentionally stays on the package default
  (`encryptedSharedPreferences: false`), which still encrypts at rest with a
  Keystore-backed key. Switching to AndroidX `EncryptedSharedPreferences` would
  invalidate already-stored tokens (one-time re-login), can crash when reading
  legacy data without `resetOnError`, and depends on a library Google has
  deprecated; revisit alongside the `flutter_secure_storage` v10 migration.

## Consequences

- The backend URL is a non-secret compile-time constant; pointing a debug build
  at a local backend is a build-time flag, not a runtime or bundled file.
- A future real secret must not reuse the bundled-`.env` pattern; it requires a
  server-side or secure-storage mechanism, to be specified by the broader E6
  policy (ENG-90).
- Changing iOS Keychain accessibility does not force re-login: the plugin's read
  path ignores accessibility, so existing tokens stay readable and acquire the
  new attribute lazily on the next write. Hardening Android storage at rest is an
  open follow-up gated on the v10 migration.
