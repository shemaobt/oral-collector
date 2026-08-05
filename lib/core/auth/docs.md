# Noridoc: Core Auth

Path: @/lib/core/auth

### Overview

- The app's single source of truth for the authenticated session. `AuthNotifier`
  in [./auth_notifier.dart](auth_notifier.dart) holds `currentUser` (the only
  signal of being logged in) and owns the access/refresh tokens and cached user
  in `FlutterSecureStorage`, the one store every secret in the app lives in. That
  store is encrypted at rest on both platforms: iOS via the Keychain, Android via
  the secure-storage plugin's platform-encrypted backend. Hardening the Android
  at-rest encryption (ENG-170, [the security ADR](../../../docs/adr/ADR-0005-security-policy.md))
  is why the plugin and `minSdk` were raised; the options pinning both backends
  live in [../providers/secure_storage_provider.dart](../providers/secure_storage_provider.dart).
- It is the only place that mutates the session: login/signup/logout, profile
  and avatar updates, account deletion, boot restore (`restoreSession` +
  `refreshSessionIfOnline`, composed by `tryAutoLogin`), and the 401-driven
  token refresh (`handleUnauthorized`).
- [./auth_repository.dart](auth_repository.dart) is the abstract data port (HTTP
  calls live in `lib/features/auth/data/`); [./auth_state.dart](auth_state.dart)
  is the immutable state; [./providers.dart](providers.dart) wires the repository
  implementation, injecting the shared **raw** `http.Client`
  (`httpClientProvider`) — deliberately **not** `AuthenticatedClient`. See the
  exception bullet in "How it fits" and [../network/docs.md](../network/docs.md).

### How it fits into the larger codebase

- `authNotifierProvider` is a **non-autoDispose `NotifierProvider`**, so there is
  exactly one `AuthNotifier` for the app lifetime. This single instance is what
  makes the refresh single-flight (below) genuinely shared across all callers —
  the in-flight field lives on that one notifier.
- The HTTP edge in [../network/authenticated_client.dart](../network/authenticated_client.dart)
  injects `handleUnauthorized` as its `TokenRefresher`: every 401 from a feature
  repository routes back here to refresh and (on success) retry. See
  [../network/docs.md](../network/docs.md) for the retry/three-outcome contract.
- **The auth repository is the one repository that runs on a raw `http.Client`,
  not `AuthenticatedClient`.** `providers.dart` injects the shared
  `httpClientProvider` ([../providers/http_client_provider.dart](../providers/http_client_provider.dart))
  into `AuthRepositoryImpl`. This is permanent because the repository is the token
  bootstrap (login/signup precede any token), owns the refresh endpoint (which
  must not self-trigger a refresh), and — critically — depending on
  `authenticatedClientProvider` here would close a Riverpod cycle:
  `authenticatedClient` → `authNotifier` (via the `handleUnauthorized` refresher
  above) → `authRepository` → back to `authenticatedClient`. See
  [../network/docs.md](../network/docs.md).
- The boot path is split across the startup gate (ENG-139 F8). `lib/main.dart`
  awaits `appStartupProvider` (which calls `restoreSession`) **before** the
  router is built, so the router's first redirect runs on settled auth state
  (no logged-out login flash); only afterward does the bootstrap microtask fire
  `refreshSessionIfOnline`. See [../startup/docs.md](../startup/docs.md). The
  router in [../router/app_router.dart](../router/app_router.dart) and the auth
  screens watch `authNotifierProvider` for redirect/UI; clearing `currentUser`
  (logout, or a refresh that returns `false`) is the signal that drives them
  back to login.
- Several feature notifiers (genre/project/stats and, since ENG-173, invite under
  `lib/features/*/presentation/notifiers/`) call `handleUnauthorized` directly,
  fire-and-forget, when they catch an `UnauthorizedException`. They guard it with
  `.catchError(..., test: (e) => e is Exception)` so a transient refresh throw
  preserves the session and never escapes as an unhandled async error. The `invite`
  accept/decline variants additionally return `false` from this arm so the caller
  treats the 401 as a failed action.
- Errors crossing this boundary come from [../errors](../errors); the one leaf
  the session branches on by **type** is `UnauthorizedException` (a real 401 on
  the refresh = expired session). See [../errors/docs.md](../errors/docs.md).
- **Notifier `error` convention (ENG-173), shared across the app.** `AuthState`
  and the other notifier states (admin, project, member, invite, storyteller) type
  their `error` field as `Object?` and store the **raw caught exception**
  (`copyWith(error: e)`), never a pre-localized string. The technical detail is
  reported to the telemetry sink from the same catch
  (`ref.read(errorReporterProvider).reportError(e, st)`,
  [../observability/docs.md](../observability/docs.md)); the UI layer translates the
  stored exception at display time via `friendlyErrorFor` /
  `showErrorSnackBar(context, Object)`
  ([../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart)).
  This keeps a typed `AppException` intact end-to-end so it hits the exhaustive
  `messageForException` switch instead of degrading to the string fallback.

### Core Implementation

- **Single-flight refresh (ENG-136).** `_tryRefresh` is deliberately **not**
  `async`: it assigns `_inFlightRefresh ??= _doTryRefresh().whenComplete(...)`
  before any `await`, so N concurrent callers share one in-flight `Future<bool>`
  and trigger exactly one token rotation. The slot clears on completion (success,
  `false`, or throw) to allow the next refresh. The real logic is in
  `_doTryRefresh`. Every refresh path funnels through `_tryRefresh`: the
  `AuthenticatedClient` callback, the three feature notifiers, and
  `refreshSessionIfOnline` (the network half of `tryAutoLogin`).
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
- **Boot restore is split into a local half and a network half (ENG-139 F8).**
  `restoreSession()` is local-only: it reads the access token and the cached user
  from secure storage and seeds `currentUser`, never hitting the network. It is
  wrapped in `try/on Exception` so a Keychain read failure at boot leaves the app
  logged out rather than wedging the splash — **it never throws.** This is what
  the startup gate awaits (`appStartupProvider`, [../startup/docs.md](../startup/docs.md))
  so the router's first redirect sees settled state. `refreshSessionIfOnline()` is
  the network half: it re-checks the token, gates on `connectivityServiceProvider.isOnline`,
  and refreshes the cached user against the server (`getMe` via the refresh funnel).
  It runs after the gate, off the first-frame path, so a slow or offline `getMe`
  never delays startup. `tryAutoLogin()` now simply composes the two in order
  (`restoreSession` then `refreshSessionIfOnline`) and remains the single entry
  point for callers that want both halves.
- **Tokens and cached user.** Stored under fixed keys in secure storage; a
  successful refresh re-stores both tokens and re-fetches `getMe`. The cached user
  enables offline-first restore in `restoreSession`. Every secret write (`_storeTokens`
  for the access/refresh tokens, `_storeUser` for the cached user) routes through
  `_writeIdempotent`, which makes the write update-safe (below).

### Things to Know

- **`_tryRefresh` must stay non-`async`.** The coalescing correctness depends on
  the slot being assigned synchronously before the first `await`; making it
  `async` reintroduces the race the single-flight exists to remove.
- **The single-flight relies on the provider not auto-disposing.** If
  `authNotifierProvider` were autoDispose (or per-scope), `_inFlightRefresh` would
  not be shared and concurrent 401s could rotate the refresh token in parallel
  again.
- **Auto-login is offline-first, and the local half must never throw (ENG-139
  F8).** `restoreSession` restores the cached user first and is the only piece
  the startup gate blocks on, so it is wrapped to swallow a boot Keychain read
  failure — a throw there would wedge the splash. `refreshSessionIfOnline` only
  hits the network when online, and on a transient refresh throw it keeps the
  cached session (does not log out). Only a `false` from `_tryRefresh` (real 401)
  clears tokens at boot. The ordering change is purely about the UI flash: the
  access token is read from secure storage **per request** by
  `AuthenticatedClient` ([../network/docs.md](../network/docs.md)), independent of
  auto-login, so deferring `refreshSessionIfOnline` past first frame never gates
  uploads or any other authenticated call on auto-login completing.
- **A real 401 on refresh logs the user out everywhere.** `handleUnauthorized`
  resetting state to `const AuthState()` clears `currentUser`, which the router
  and shells observe to redirect to login — there is no separate "session expired"
  flag.
- **Secret writes are idempotent (ENG-188), because the iOS Keychain survives the
  app.** `_writeIdempotent` wraps the secure-storage `write`. The Darwin plugin's
  `write` is itself an upsert (a `containsKey` precheck → `SecItemUpdate` on hit,
  else `SecItemAdd`), so a plain same-accessibility re-login normally takes the
  update path. The collision arises because `containsKey`'s lookup query includes
  `kSecAttrAccessible`: if the stored item's accessibility differs from the current
  query's — notably after ENG-128 / ADR-0005 moved the keys to
  `first_unlock_this_device` — `containsKey` **false-negatives** the still-present
  item (Keychain uniqueness is service+account, not accessibility), the plugin
  falls through to `SecItemAdd` on an item that already exists, and that surfaces as
  `errSecDuplicateItem` (OSStatus `-25299`). On that specific `PlatformException`
  (matched by `details == -25299` or the message carrying `-25299`/"already exists")
  the helper deletes the key and rewrites it; any other `PlatformException` is
  rethrown. Before this, a second-or-later correct-password `login` caught the
  collision into `state.error` and surfaced only the generic snackbar — every login
  after the first failed — and `tryAutoLogin`'s `_storeUser` refresh failed the same
  silent way (only erasing the simulator cleared it).
- **The collision repair is off the happy path, by design.** The happy path is a
  plain `write`; the delete-then-rewrite runs **only** on a real `-25299`, so it
  adds no `delete` call in the normal flow and does not perturb the delete-call
  accounting the ENG-136/141 refresh tests assert on.
- **The rewrite preserves ADR-0005 device-binding and recovers the
  accessibility-migration case.** It reuses the same provider `IOSOptions`
  (`KeychainAccessibility.first_unlock_this_device`) from
  [../providers/secure_storage_provider.dart](../providers/secure_storage_provider.dart),
  so the rewritten item keeps its accessibility / background-readability;
  `secure_storage_provider.dart` is unchanged. Crucially, the plugin's `delete`
  (`performDelete`) is **accessibility-agnostic** — it nils the accessibility level
  and deletes across both synchronizable states — so the delete clears the stale
  item *regardless* of the accessibility it was stored under (e.g. a pre-ENG-128
  level), and the subsequent retry `SecItemAdd` succeeds. The recovery is
  **trigger-agnostic**: it keys off the `-25299` error, not off any specific cause,
  so it covers the migration path even though the exact production trigger was never
  reproduced on a physical device.

Created and maintained by Nori.
