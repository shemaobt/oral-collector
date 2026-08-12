# Noridoc: Core Router

Path: @/lib/core/router

### Overview

- The app's single `GoRouter` instance and its route table. Everything a user
  navigates to — auth screens, the tabbed shell, and the top-level screens
  reached by pushing off a tab — is declared in
  [./app_router.dart](app_router.dart).
- Owns two `redirect` concerns that run before any route builds: the
  authenticated-vs-auth-screen gate, and a deep-link scheme redirect used by
  the iOS Live Activity.
- Does not own navigation *state* itself — it reacts to
  [../auth/auth_notifier.dart](../auth/auth_notifier.dart) via
  `refreshListenable` and to the project notifier via per-route `redirect`
  callbacks that read Riverpod directly.

### How it fits into the larger codebase

- `routerProvider` is read once, at the top of the widget tree, to build
  `MaterialApp.router`. Every screen under `lib/features/*/presentation`
  reaches the router only through `context.go` / `context.push` /
  `GoRouterState.of(context)`, never by holding a `Navigator` reference
  directly.
- The auth gate reads `authNotifierProvider.isAuthenticated`
  ([../auth/docs.md](../auth/docs.md)) through `_RouterNotifier`, a
  `ChangeNotifier` that forwards `ref.listen` into `refreshListenable`. This is
  why login/logout redirect immediately: clearing `currentUser` fires
  `notifyListeners()`, which makes `GoRouter` re-run `redirect` on the current
  location without a route change of its own. The router's first redirect
  only runs after `lib/main.dart` awaits the startup gate
  (`appStartupProvider`, [../startup/docs.md](../startup/docs.md)), so it
  never sees a transient logged-out flash while `restoreSession` is still
  running.
- `AppShell` ([../../shared/widgets/docs.md](../../shared/widgets/docs.md))
  wraps every route inside the `ShellRoute`; per-tab navigation
  (`_navigateToTab` in `app_shell.dart`) calls `context.go`, which — unlike
  `push` — replaces the shell's nested stack rather than growing it, so the
  bottom nav / web sidebar never accumulates history.
- Several routes gate on `projectNotifierProvider.activeProject` in their own
  `redirect` (record flow, quick-record, recovery-confirm, import-file):
  reading Riverpod state directly inside a `GoRoute.redirect`, rather than
  threading a guard widget, is how this router expresses "you need an active
  project to be here."
- The `/admin` route always redirects to `/profile`; `AdminDashboardScreen`
  is reached from a widget inside the profile screen, not by landing on
  `/admin` directly — the route exists so a stale deep link doesn't 404.

### Core Implementation

- **Deep-link scheme redirect runs first.** If the incoming URI scheme
  matches `RecordingConfig.liveActivityUrlScheme`, the redirect returns the
  router's *current* location (or `/home` if none) instead of following the
  scheme as a path — the Live Activity's deep link exists only to bring the
  app to the foreground, not to navigate anywhere, so this redirect is a
  no-op with a fallback.
- **Every route is declared exactly once conceptually, but appears twice in
  the file.** `/genre/:id`, `/recording/:id`, `/recording/:id/trim`,
  `/import-file`, `/project/:id/settings`, the storyteller routes, and
  `/admin` are each declared under `if (!kIsWeb)` **outside** the
  `ShellRoute`, and again under `if (kIsWeb)` **inside** it. (`/record-flow`
  is *not* one of these: it is the device-only top-level twin of `/record`,
  which lives in the shell on every platform — same screen, different path
  and different Navigator, so grepping for the screen finds both.)
  Only one branch compiles into the running app for a given platform — this
  is not dead code, it is two different Navigator placements for the same
  path, chosen by `kIsWeb` at route-table construction time:

  | Platform | Where `/recording/:id` (and siblings) live | Navigator |
  | --- | --- | --- |
  | Device (`!kIsWeb`) | top-level `GoRoute`, sibling of the `ShellRoute` | root `Navigator`, one level above the shell |
  | Web (`kIsWeb`) | `GoRoute` inside the `ShellRoute`'s `routes` | the shell's nested `Navigator` |

  This split is deliberate and intentionally not unified as part of any single
  ticket — flattening it would change which `Navigator` these screens push
  onto, and that Navigator placement is exactly what governs system-back
  behaviour (below). A reader who edits one branch without checking `kIsWeb`
  will silently change behaviour on only one platform.
- Routes that need an active project (`/record`, `/record-flow`,
  `/quick-record`, `/recovery-confirm`, and the device-side `/import-file`)
  repeat the same `redirect` body — read
  `projectNotifierProvider.activeProject`, fall back to `/home` if null —
  inline at each declaration rather than as a shared helper. The web
  `/import-file` inside the shell carries no such guard.

### Things to Know

- **System back on a device pops the root Navigator, and the root falls
  through to leaving the app.** Because `/recording/:id` and its siblings are
  top-level routes outside the `ShellRoute` on a device, pushing one of them
  (e.g. from `recordings_list_screen.dart`'s `context.push('/recording/${id}')`)
  stacks on the root `Navigator`. A system back there pops that route
  normally. At the root of the stack — nothing left to pop — a system back
  falls through to `SystemNavigator.pop`, which leaves the app; this is
  standard `WidgetsApp`/`Navigator` behavior, not something this router
  overrides. [../../../test/core/router/system_back_test.dart](../../../test/core/router/system_back_test.dart)
  pins both outcomes by driving the router through the actual platform
  channels rather than tapping an AppBar back arrow — see
  [../../../test/support/system_back.dart](../../../test/support/system_back.dart)
  for why the arrow is not an equivalent test (it calls `Navigator.maybePop`
  directly and would stay green even if the channel path were broken).
- **Predictive back is the path a real device takes, not the legacy
  `popRoute` channel.** `android/app/build.gradle.kts` builds against
  `flutter.targetSdkVersion`, which resolves to Android API 36 with the
  Flutter version this repo pins; since Android 15 (API 35), predictive back
  is enabled by default for apps targeting that level, and
  `android/app/src/main/AndroidManifest.xml` has no
  `android:enableOnBackInvokedCallback` override to opt out. A device
  therefore drives the `flutter/backgesture` channel (`startBackGesture` /
  `commitBackGesture`), and only falls back to the legacy `flutter/navigation`
  `popRoute` when the framework declines the gesture. Both channels were
  measured, in a widget test, to produce the same pop/leave outcome for this
  router's route table; `system_back_test.dart` covers both.
- **A reproduce-first investigation (ENG-68) did not reproduce the reported
  "back closes the app from a recording's detail screen" defect off-device.**
  The tests above are a regression guard for the behavior as measured in a
  widget test, not evidence that the defect was fixed — nothing in this
  router or in `AndroidManifest.xml`/`build.gradle.kts` changed to address it.
  If the defect resurfaces, it is real device/OS behavior not captured by a
  widget test's platform-channel simulation, and needs on-device
  reproduction.
- **A counted `pump(duration)` loop is not a substitute for `pumpAndSettle`
  when asserting a route was popped.** A route removed by a system back stays
  mounted through several fixed-duration pumps and only unmounts once the
  widget tree settles; a test that pumps a fixed number of times can read a
  route as still present when it has, in fact, already been told to leave.

Created and maintained by Nori.
