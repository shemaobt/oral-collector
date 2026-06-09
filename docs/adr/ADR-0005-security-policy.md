# ADR-0005: Security policy

- Status: Proposed
- Date: 2026-06-04
- Epic: E6 (Security)
- Related: ENG-90, ENG-167, ENG-130, ADR-0000

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
    renderer, fetched from gstatic, with WASM instantiation), and jsDelivr
    because `web/index.html` loads sql.js from there.
  - `connect-src` permits the backend API
    (`https://tripod-backend.shemaywam.com`, the production URL pinned in
    `core/config/env.dart`) **and** Google Cloud Storage
    (`https://storage.googleapis.com`) — uploads PUT to GCS v4 presigned URLs
    and playback GETs from GCS, a different origin than the backend, so omitting
    it would break upload/playback — plus gstatic and jsDelivr for the
    `.wasm` fetches, plus `https://fonts.gstatic.com` for CanvasKit's
    Noto/Roboto fallback fonts (fetched via XHR, so under `connect-src`, not
    `font-src`).
  - `style-src 'self' 'unsafe-inline'` (Flutter injects inline styles),
    `media-src` permits GCS for audio playback, plus `img-src`, `worker-src`,
    and the lockdown directives `object-src 'none'`, `base-uri 'self'`,
    `frame-ancestors 'self'`. `X-Frame-Options: SAMEORIGIN` is the coherent
    legacy counterpart to `frame-ancestors 'self'`.
- `Strict-Transport-Security` (HSTS) is deliberately omitted: it is outside this
  ticket's scope and risky, since `includeSubDomains`/`preload` would affect
  sibling `*.shemaywam.com` subdomains. Left as a follow-up.
- The header CSP must stay in lockstep with whatever `web/index.html` loads
  (today, sql.js from jsDelivr — ENG-130's scope). If ENG-130 self-hosts sql.js
  or adds a `<meta http-equiv="Content-Security-Policy">`, this header must be
  updated together; a header CSP and a meta CSP are enforced as their
  intersection.
- A hermetic Docker test (`docker/verify-security-headers.sh`) builds nginx from
  the real config and curls `/`, a `.js`, and a `.png` to assert the headers. It
  is a local/manual gate, not wired into CI (CI runs `flutter test`, not
  Docker).

## Consequences

- The backend URL is a non-secret compile-time constant; pointing a debug build
  at a local backend is a build-time flag, not a runtime or bundled file.
- A future real secret must not reuse the bundled-`.env` pattern; it requires a
  server-side or secure-storage mechanism, to be specified by the broader E6
  policy (ENG-90).
- The CSP couples the deploy config to the web build's runtime dependencies:
  changing renderers, CDNs, or the set of contacted origins (backend, GCS) means
  the `docker/security-headers.conf` allowlist must change too, or requests are
  silently blocked. `docker/verify-security-headers.sh` is the manual check for
  this.
- Future tightening (follow-up): building with `--no-web-resources-cdn`
  (self-hosting CanvasKit, dropping www.gstatic.com) together with ENG-130
  self-hosting sql.js (dropping jsDelivr) would collapse the CSP toward
  `default-src 'self'` plus the backend, GCS, and — unless the CanvasKit font
  fallback is also self-hosted — fonts.gstatic.com. HSTS remains a separate
  follow-up.
