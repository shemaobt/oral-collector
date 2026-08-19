# Noridoc: Core Startup

Path: @/lib/core/startup

### Overview

- The cold-start gate (ENG-139 F8): the must-finish-before-first-frame work that
  settles authentication state before the router's first redirect, so the app
  never flashes the logged-out login screen on launch.
- `appStartupProvider` (a `FutureProvider<void>` in
  [./app_startup.dart](app_startup.dart)) awaits the local session restore;
  `StartupSplash` is the themed placeholder shown while it resolves.
- Tiny by design — it holds only the gate provider and the splash widget; the
  actual session work lives in [../auth/auth_notifier.dart](../auth/auth_notifier.dart).

### How it fits into the larger codebase

- `appStartupProvider` calls `AuthNotifier.restoreSession()`
  ([../auth/docs.md](../auth/docs.md)) — the **local-only** half of auto-login
  (token + cached user, never the network, never throws). It deliberately does
  **not** await the network refresh; `refreshSessionIfOnline()` runs later, off
  the first-frame path.
- [/lib/main.dart](../../main.dart) consumes the gate at both ends. `build()`
  watches `appStartupProvider` and renders `StartupSplash` while `loading`,
  switching to the real app (the router-backed `MaterialApp.router`) on `data`
  **or** `error` — a restore failure falls through to the app logged-out rather
  than wedging the splash. Separately, the bootstrap microtask `await`s
  `appStartupProvider.future`, then fires `refreshSessionIfOnline()` and the rest
  of post-boot work (orphan-upload reclaim, sync/listener init). The
  housekeeping in that microtask splits on `kIsWeb`: trash pruning, the
  recovery scan and Live Activity teardown on device; the sweep of recordings
  abandoned in browser storage on web (ENG-426). The two prunes — device trash
  and browser audio — are fired unawaited, so neither stands between the person
  and the first screen; the recovery scan is awaited because the upload
  listeners that come after it must not see a stale recording flag.
- The router in [../router/app_router.dart](../router/app_router.dart) is only
  built inside `main.dart`'s `_buildApp()`, which runs after the gate resolves.
  Its redirect keys off `authNotifierProvider.isAuthenticated`; because
  `restoreSession` has already seeded `currentUser` by then, the **first**
  redirect decision is made on settled auth state.
- Because it is its own `MaterialApp`, `StartupSplash` carries
  `Directionality`/theme (`AppTheme`, [../theme/](../theme/)) before the router's
  `MaterialApp.router` exists, so the splash can render legally during the gate.

### Core Implementation

```
main.build()
  └─ watch(appStartupProvider)
       ├─ loading → StartupSplash            (own MaterialApp, themed spinner)
       ├─ error   → _buildApp()              (logged-out → router sends to /login)
       └─ data    → _buildApp()              (router's first redirect on settled auth)

main bootstrap microtask
  └─ await appStartupProvider.future
       └─ refreshSessionIfOnline()  +  orphan reclaim  +  sync/listeners
```

- `appStartupProvider` resolves once and is cached for the app lifetime (non-
  autoDispose `FutureProvider`); `main.dart`'s `build()` watch and the microtask
  `.future` await share that single resolution.
- `StartupSplash` is a `const` `StatelessWidget` with no logic — a centered
  `CircularProgressIndicator` in a `Scaffold`.

### Things to Know

- **The gate removes a UI flash only — it never gates work on auth.** The access
  token is read from secure storage **per request** by `AuthenticatedClient`
  ([../network/docs.md](../network/docs.md)), independent of auto-login. Deferring
  `refreshSessionIfOnline` past first frame and gating the router on
  `restoreSession` changes only *when the login screen can appear*; it does not
  block uploads or any other authenticated call on the gate completing.
- **`restoreSession` must never throw** — see [../auth/docs.md](../auth/docs.md).
  If it did, `appStartupProvider` would resolve to `error`; `main.dart` handles
  that by building the app logged-out (router → `/login`) rather than leaving the
  splash up, but the intended contract is that a boot Keychain read failure is
  swallowed inside `restoreSession` and surfaces as "logged out", not as a gate
  error.
- **The network half is intentionally outside the gate.** A slow or offline
  `getMe` must not delay first frame; `refreshSessionIfOnline` runs after
  `appStartupProvider.future` settles in the bootstrap microtask, so first frame
  never waits on the server.

Created and maintained by Nori.
