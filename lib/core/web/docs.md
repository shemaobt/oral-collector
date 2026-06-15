# Noridoc: Core Web

Path: @/lib/core/web

### Overview

- Web-platform browser plumbing that the rest of the app reaches through a
  conditional-import facade, so a feature can call one symbol and get a real
  browser action on web and a no-op everywhere else.
- Exists to scrub the password-reset `?token=` from the browser address bar
  (ENG-133, E6 security batch): a captured reset token must not linger in
  browser history / back-forward navigation or leak via the `Referer` header on
  later navigations.
- [./url_query.dart](url_query.dart) is the pure, platform-agnostic core
  (`cleanedLocationWithout(href, key)`); [./url_history.dart](url_history.dart)
  is the facade (`stripUrlQueryParam(key)`) that performs the side effect.

### How it fits into the larger codebase

- This is the OS/browser side of the transport-hardening story whose narrative
  lives in [ADR-0005](../../../docs/adr/ADR-0005-security-policy.md). It is a
  client-side mitigation only: the token still reaches nginx on the initial GET
  (access logs) and is briefly in-URL before first paint — full mitigation is a
  backend follow-up.
- The single caller is the reset-password screen
  ([../../features/auth/presentation/reset_password_screen.dart](../../features/auth/presentation/reset_password_screen.dart)),
  which calls `stripUrlQueryParam('token')` from `initState`, **only when a
  token is present**, after the value is already held in widget state. Scrubbing
  the URL therefore cannot affect the reset flow itself.
- Sibling to [../platform](../platform): both folders hide a per-target
  implementation behind a conditional-import facade. Platform splits
  native-vs-web for IO/FFmpeg; this folder splits **no-op-vs-web** for a
  browser-only API. Callers never import the `_stub` / `_web` files directly.
- Complements, but is independent of, the Dart-side cleartext guard in
  [../config/url_policy.dart](../config/url_policy.dart) and the network edge in
  [../network/docs.md](../network/docs.md): those govern which URLs may be
  *requested*; this folder rewrites what is *displayed* in the address bar.

### Core Implementation

- `cleanedLocationWithout(href, key)` ([./url_query.dart](url_query.dart))
  parses `href`, returns `null` when `key` is absent (signal to the caller that
  nothing needs rewriting), and otherwise rebuilds a **same-origin relative**
  reference — path + remaining query + fragment, origin dropped. Every
  occurrence of a repeated key is removed; the fragment is preserved. Being pure
  and `dart:html`-free, it is the unit-tested unit
  ([/test/core/web/url_query_test.dart](../../../test/core/web/url_query_test.dart)).
- `url_history.dart` is a conditional export, not a Dart file with logic:
  `export 'url_history_stub.dart' if (dart.library.js_interop) 'url_history_web.dart';`.
  This is the key invariant — it keeps `package:web` out of the Android/iOS AOT
  build (importing it unconditionally breaks the mobile compile).
- [./url_history_web.dart](url_history_web.dart) is the only impure code: it
  feeds `window.location.href` through `cleanedLocationWithout`, and on a
  non-null result calls `window.history.replaceState(...)` to swap the address
  bar without a navigation. `replaceState` (not `pushState`) means no new
  history entry is created.
- [./url_history_stub.dart](url_history_stub.dart) is the non-web `stripUrlQueryParam`
  no-op: there is no address bar to scrub off the browser.

### Things to Know

- **The split is no-op-vs-web, not native-vs-web.** `dart.library.js_interop`
  selects the web variant; everything else (Android, iOS, tests, the VM) links
  the stub, so `stripUrlQueryParam` is always safe to call unconditionally from
  shared widget code.
- **`url_query.dart` is the test seam.** The browser side cannot be unit-tested
  off a real `window`, so all behavior (absent key, empty value, repeated key,
  fragment preservation, sole-param removal) is covered against the pure
  function; `url_history_web.dart` is a thin two-line adapter over it.
- **Mitigation scope is deliberately partial.** This scrubs only the
  client-visible URL after capture. The token is still logged by nginx on the
  first GET and exists in the URL before the screen mounts; the ADR records this
  and defers the full fix (fragment token / one-time server code) to the
  backend.

Created and maintained by Nori.
