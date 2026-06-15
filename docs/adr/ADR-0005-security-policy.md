# ADR-0005: Security policy

- Status: Proposed
- Date: 2026-06-04
- Epic: E6 (Security)
- Related: ENG-90, ENG-167, ENG-130, ENG-133, ENG-132, ADR-0000

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

### Web deploy security headers and CSP (ENG-167)

The nginx-served web build (Cloud Run; `docker/Dockerfile.web` serving
`build/web` via `docker/nginx.conf`) sends a Content-Security-Policy plus
`X-Content-Type-Options: nosniff`, `Referrer-Policy:
strict-origin-when-cross-origin`, and `X-Frame-Options: SAMEORIGIN`. The
directives live in a single `docker/security-headers.conf` snippet copied to
`/etc/nginx/snippets/`.

- The snippet is `include`d at `server` scope **and** inside every `location`
  block. nginx discards all inherited `add_header` directives at any scope that
  defines its own; each location here sets its own `Cache-Control`, so headers
  declared only at `server` scope would silently vanish on `/`, `.js`, `.css`,
  and asset responses. Per-location inclusion is what keeps them present
  everywhere.
- The CSP is tailored to exactly what the current web build loads and contacts
  at runtime, not a generic allowlist:
  - `script-src` permits `'wasm-unsafe-eval'` and the gstatic CDN because the
    build is `flutter build web --release --no-wasm-dry-run` (CanvasKit
    renderer, fetched from gstatic, with WASM instantiation). sql.js is served
    same-origin (ENG-130 self-hosts it), so `'self'` covers it.
  - `connect-src` permits the backend API
    (`https://tripod-backend.shemaywam.com`, the production URL pinned in
    `core/config/env.dart`) **and** Google Cloud Storage
    (`https://storage.googleapis.com`) — uploads PUT to GCS v4 presigned URLs
    and playback GETs from GCS, a different origin than the backend, so omitting
    it would break upload/playback — plus gstatic for the CanvasKit `.wasm`
    fetch and `https://fonts.gstatic.com` for CanvasKit's Noto/Roboto fallback
    fonts (fetched via XHR, so under `connect-src`, not `font-src`).
  - `style-src 'self' 'unsafe-inline'` (Flutter injects inline styles),
    `media-src` permits GCS for audio playback, plus `img-src`, `worker-src`,
    and the lockdown directives `object-src 'none'`, `base-uri 'self'`,
    `frame-ancestors 'self'`. `X-Frame-Options: SAMEORIGIN` is the coherent
    legacy counterpart to `frame-ancestors 'self'`.
- `Strict-Transport-Security` (HSTS) is omitted **in ENG-167**; it was added later
  by ENG-133 (see "Transport hardening" below).
- The header CSP must stay in lockstep with whatever `web/index.html` loads. With
  ENG-130 self-hosting sql.js, the only remaining third-party origins are gstatic
  (CanvasKit) and fonts.gstatic.com (its font fallback). If a future change adds
  a `<meta http-equiv="Content-Security-Policy">` to `web/index.html`, this
  header and that meta must be updated together; the two are enforced as their
  intersection.
- A hermetic Docker test (`docker/verify-security-headers.sh`) builds nginx from
  the real config and curls `/`, a `.js`, and a `.png` to assert the headers. It
  is a local/manual gate, not wired into CI (CI runs `flutter test`, not
  Docker).

### Transport hardening: cleartext block, HSTS, reset-token scrubbing (ENG-133)

- **Android cleartext is blocked at the OS layer.** A `network-security-config`
  (`android/app/src/main/res/xml/network_security_config.xml`, wired via
  `android:networkSecurityConfig` on `<application>`) sets
  `cleartextTrafficPermitted="false"`, so non-debug builds cannot make plaintext
  HTTP requests even from native plugins that bypass Dart's `HttpClient`. This is
  defense-in-depth under `core/config/url_policy.dart` (ENG-132), which already
  blocks http in release at the Dart layer. `minSdk` is 24, so the config is always
  honored and `usesCleartextTraffic` is redundant (omitted).
- **Debug keeps cleartext for local dev.** A build-type resource overlay
  (`android/app/src/debug/res/xml/network_security_config.xml`) re-permits
  cleartext in debug builds so developers can reach a LAN/loopback HTTP backend
  (dev `.env` uses an RFC1918 IP over http). It never ships, and `url_policy.dart`
  still restricts the Dart client. A permissive debug base is used rather than a
  per-host `domain-config` because the config cannot express CIDR ranges and the
  dev IP varies per machine.
- **HSTS is now sent** (supersedes the ENG-167 omission above):
  `Strict-Transport-Security: max-age=63072000; includeSubDomains` in
  `docker/security-headers.conf`, with a matching assertion in
  `docker/verify-security-headers.sh`. No `preload` — it is effectively permanent
  and would lock every `*.shemaywam.com` subdomain to HTTPS; `includeSubDomains`
  already assumes all subdomains serve HTTPS. The header is only honored over
  HTTPS; nginx serves plain `:8080` behind a TLS-terminating edge, which must
  forward it.
- **The password-reset token is scrubbed from the web URL.** The reset link
  carries `?token=…`; once the screen captures it, `core/web/url_history.dart`
  (web-only, behind a conditional import so `package:web` never enters the
  Android/iOS AOT build) calls `history.replaceState` to drop the query, so the
  token is not retained in browser history / back-forward or leaked via Referer on
  later navigations. The token is still sent to nginx on the initial GET (access
  logs) and is briefly in-URL before first paint; full mitigation (a fragment token
  or a one-time server-side code) is a backend follow-up.
- **R8 (Android shrink/obfuscate)** is enabled on the release build in the same
  batch — see ADR-0009, whose original "R8 out of scope" note ENG-133 supersedes.

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
- The CSP couples the deploy config to the web build's runtime dependencies:
  changing renderers, CDNs, or the set of contacted origins (backend, GCS) means
  the `docker/security-headers.conf` allowlist must change too, or requests are
  silently blocked. `docker/verify-security-headers.sh` is the manual check for
  this.
- Future tightening (follow-up): building with `--no-web-resources-cdn`
  (self-hosting CanvasKit, dropping www.gstatic.com) and self-hosting the
  CanvasKit font fallback (dropping fonts.gstatic.com) would collapse the CSP
  toward `default-src 'self'` plus the backend and GCS only. HSTS was added in
  ENG-133.
