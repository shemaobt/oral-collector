# Noridoc: Core Auth

Path: @/lib/core/auth

### Overview

- The app's single source of truth for the authenticated session. `AuthNotifier`
  in [./auth_notifier.dart](auth_notifier.dart) holds `currentUser` (the only
  signal of being logged in) and owns the access/refresh tokens and cached user
  in `FlutterSecureStorage`.
- It is the only place that mutates the session: login/signup/logout, profile
  and avatar updates, account deletion, boot restore (`tryAutoLogin`), and the
  401-driven token refresh (`handleUnauthorized`).
- [./auth_repository.dart](auth_repository.dart) is the abstract data port (HTTP
  calls live in `lib/features/auth/data/`); [./auth_state.dart](auth_state.dart)
  is the immutable state; [./providers.dart](providers.dart) wires the repository
  implementation.

### How it fits into the larger codebase

- `authNotifierProvider` is a **non-autoDispose `NotifierProvider`**, so there is
  exactly one `AuthNotifier` for the app lifetime. This single instance is what
  makes the refresh single-flight (below) genuinely shared across all callers —
  the in-flight field lives on that one notifier.
- The HTTP edge in [../network/authenticated_client.dart](../network/authenticated_client.dart)
  injects `handleUnauthorized` as its `TokenRefresher`: every 401 from a feature
  repository routes back here to refresh and (on success) retry. See
  [../network/docs.md](../network/docs.md) for the retry/three-outcome contract.
- The boot path `lib/main.dart` calls `tryAutoLogin`, and the router in
  [../router/app_router.dart](../router/app_router.dart) and the auth screens
  watch `authNotifierProvider` for redirect/UI. Clearing `currentUser` (logout,
  or a refresh that returns `false`) is the signal that drives them back to login.
- Several feature notifiers (genre/project/stats under
  `lib/features/*/presentation/notifiers/`) call `handleUnauthorized` directly,
  fire-and-forget, when they catch an `UnauthorizedException`. They guard it with
  `.catchError(..., test: (e) => e is Exception)` so a transient refresh throw
  preserves the session and never escapes as an unhandled async error.
- Errors crossing this boundary come from [../errors](../errors); the one leaf
  the session branches on by **type** is `UnauthorizedException` (a real 401 on
  the refresh = expired session). See [../errors/docs.md](../errors/docs.md).

### Core Implementation

- **Single-flight refresh (ENG-136).** `_tryRefresh` is deliberately **not**
  `async`: it assigns `_inFlightRefresh ??= _doTryRefresh().whenComplete(...)`
  before any `await`, so N concurrent callers share one in-flight `Future<bool>`
  and trigger exactly one token rotation. The slot clears on completion (success,
  `false`, or throw) to allow the next refresh. The real logic is in
  `_doTryRefresh`. Every refresh path funnels through `_tryRefresh`: the
  `AuthenticatedClient` callback, the three feature notifiers, and `tryAutoLogin`.
- **Why single-flight.** The backend rotates the refresh token on first use and
  invalidates the old one. Concurrent 401s previously each launched their own
  refresh reading the same (soon-stale) refresh token; the first won and the rest
  got a 401, which `handleUnauthorized` mis-read as an expired session and logged
  the user out. Coalescing makes concurrent 401s await one rotation and all retry.
- **Three-outcome contract (ENG-141), unchanged by ENG-136.** `_doTryRefresh`
  returns `true` (refreshed, session updated), returns `false` only on a genuine
  `UnauthorizedException` (expired → caller clears the session), or **propagates**
  any other exception (network/timeout/5xx/parse) as transient so the session is
  preserved. `handleUnauthorized` clears tokens + resets state only on `false`.
- **Tokens and cached user.** Stored under fixed keys in secure storage; a
  successful refresh re-stores both tokens and re-fetches `getMe`. The cached user
  enables offline-first restore in `tryAutoLogin`.

### Things to Know

- **`_tryRefresh` must stay non-`async`.** The coalescing correctness depends on
  the slot being assigned synchronously before the first `await`; making it
  `async` reintroduces the race the single-flight exists to remove.
- **The single-flight relies on the provider not auto-disposing.** If
  `authNotifierProvider` were autoDispose (or per-scope), `_inFlightRefresh` would
  not be shared and concurrent 401s could rotate the refresh token in parallel
  again.
- **`tryAutoLogin` is offline-first.** It restores the cached user first, only
  hits the network when online, and on a transient refresh throw it keeps the
  cached session (does not log out). Only a `false` from `_tryRefresh` (real 401)
  clears tokens at boot.
- **A real 401 on refresh logs the user out everywhere.** `handleUnauthorized`
  resetting state to `const AuthState()` clears `currentUser`, which the router
  and shells observe to redirect to login — there is no separate "session expired"
  flag.

Created and maintained by Nori.
