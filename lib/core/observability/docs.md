# Noridoc: Core Observability

Path: @/lib/core/observability

### Overview

- Two distinct app-wide observability seams. The **telemetry seam** is a
  vendor-neutral `ErrorReporter` interface, a `NoopErrorReporter` default (drops
  everything), a Riverpod `errorReporterProvider`, and `installGlobalErrorHandlers`,
  which routes Flutter's global error hooks through whichever reporter is wired in.
  The **diagnostics seam** is the logging facade in
  [./app_logger.dart](app_logger.dart) (`installLogging`), backed by
  `package:logging`, which is where general developer diagnostics across the app
  now flow (replacing scattered `debugPrint`). A one-way bridge connects them:
  log records at `Level.SEVERE`+ forward into the reporter.
- Exists because the app previously had no reporting abstraction, no
  `runZonedGuarded`, and no crash package — its global hooks only echoed to the
  console (and the rest of the app scattered raw `debugPrint`), so uncaught
  production errors went to the telemetry void. Note `debugPrint` is **not** a
  release no-op — it prints in every build mode; only `dart:developer log()` is
  silenced by the VM in AOT/release, which is why both the global-hook console
  echoes and the logging facade route through `dart:developer log()`.
- Default behavior of the reporter is intentionally identical to before (Noop
  drops everything); reporting is additive and zero-cost until a real adapter
  replaces the default. See
  [/docs/adr/0006-pluggable-error-reporter-telemetry.md](../../../docs/adr/0006-pluggable-error-reporter-telemetry.md)
  for the reporter and
  [/docs/adr/ADR-0010-logging-facade.md](../../../docs/adr/ADR-0010-logging-facade.md)
  for the logging facade.

### How it fits into the larger codebase

- This is the app-wide global error sink. It sits below the feature layers and
  is consumed at process startup by [/lib/main.dart](../../main.dart), which is
  the only caller of `installGlobalErrorHandlers` and `installLogging`. The two
  are wired back to back in `main()` (handlers first, so the reporter the logging
  bridge forwards to is the same instance), both reading the one reporter the
  app-root `ProviderContainer` produces.
- The **logging facade** ([./app_logger.dart](app_logger.dart)) is the general
  diagnostics path for the whole app. Feature code logs through named
  `package:logging` `Logger` instances (e.g. `Logger('SegmentedRecorder')`);
  every record is echoed to `dart:developer log()` and only records at
  `Level.SEVERE`+ cross the **one-way bridge** into the reporter
  (`SHOUT`→`fatal`, `SEVERE`→`error`). This is distinct from the `ErrorReporter`
  telemetry seam: diagnostics flow *one way into* telemetry, never the reverse.
  Severe production faults therefore become observable through the same reporter
  once a real adapter replaces the Noop default, while routine debug/info lines
  stay local. The recording and sync data layers
  ([../../features/recording/data/docs.md](../../features/recording/data/docs.md),
  [../../features/sync/data/services/docs.md](../../features/sync/data/services/docs.md))
  are the largest emitters.
- `errorReporterProvider` is the single seam for swapping reporters. The app-root
  `ProviderContainer` reads it once in `main()`; feature code that wants to report
  manually reads the same provider rather than constructing a reporter.
- Three feeds reach the reporter. The **global** hooks (ENG-173,
  `installGlobalErrorHandlers` + `runZonedGuarded`) catch what escapes; **domain**
  notifiers and auth screens (ENG-173) now also report from their own `on Exception`
  catch arms — `ref.read(errorReporterProvider).reportError(e, st)` — before storing
  the raw exception in state for the UI to translate. The diagnostic detail goes to
  the reporter; the typed exception goes to the UI. See the `error` invariant in
  [../auth/docs.md](../auth/docs.md) and [../errors/docs.md](../errors/docs.md).
- The third feed is the **serialization page policy** (ENG-166). List-returning
  repositories route each `parseList` skip into the reporter via the
  `parseSkipSink` adapter, so a record dropped by ADR-0008 skip-and-log becomes
  observable. It reports at `ErrorLevel.warning` (a dropped row is non-fatal
  degradation), distinct from the `fatal` global hooks, with the parseList
  `context` string and the offending element index attached. The adapter also
  keeps the local `developer.log` trace, so debug visibility is unchanged and the
  change is additive/zero-cost under the Noop default. See
  [../serialization/docs.md](../serialization/docs.md).
- A fourth feed (ENG-102, extended by ENG-139) is the **silent-fallback /
  best-effort** catches that previously swallowed errors outright. The
  recordings-list notifier
  ([../../features/recording/presentation/notifiers/docs.md](../../features/recording/presentation/notifiers/docs.md)),
  the sync notifier's best-effort file ops, and — added in ENG-139 —
  `RecordingFinalizationService`'s best-effort temp deletes (F20) and the
  recording session's coalesced 1 Hz foreground/Live-Activity updates (F5, via
  `SingleFlightRunner`'s `onError`) now report to the reporter (stack preserved)
  on the way through their fallback. Unlike the state-storing arms above, none
  of these surface anything to the UI: the intentional fallback (degrade to
  local, return 0/null, finish the row delete, let the temp file leak, drop the
  missed tick) is unchanged, and the report is the *only* visibility these paths
  have. See
  [../../features/recording/data/docs.md](../../features/recording/data/docs.md).
- Notifiers never telemeter a 401: it is the expected token-refresh flow, not a
  fault, so reporting it would be noise. Notifiers with an `on UnauthorizedException`
  arm (project/genre/stats/invite) catch it there (driving `handleUnauthorized`), so
  it never reaches the generic report. Those without that arm (member/storyteller/
  admin/recordings-list) route reporting through a `_reportUnexpected` guard that
  skips `UnauthorizedException`; whether the error also reaches the UI depends on
  the arm — state-storing arms surface the raw exception, silent-fallback arms do
  not.
- It is distinct from [/lib/core/errors/](../errors/), which holds the typed
  domain/API failures (the `AppException` hierarchy) that flow through normal
  exception paths. Observability is the telemetry sink — fed both by *uncaught*
  errors and by the domain catch arms above — not domain error modeling.
- The interface is deliberately shaped after `sentry_flutter` so a deferred
  Sentry adapter can be a thin pass-through, swapped purely via
  `errorReporterProvider.overrideWithValue(...)` with no call-site changes.

### Core Implementation

- `ErrorReporter` (an `abstract interface class`) exposes `reportError`,
  `addBreadcrumb`, `setUser`, `clearUser`, and `setTag`. `ErrorLevel`
  (`fatal`/`error`/`warning`/`info`/`debug`) is vendor-neutral and is intended to
  map onto `SentryLevel` later.
- `NoopErrorReporter` is a `const` implementation whose methods all no-op. It is
  the value behind `errorReporterProvider` and preserves prior release behavior.
- `installGlobalErrorHandlers(reporter)` wires both global hooks. Their console
  echo is `dart:developer log()` (self-silencing in AOT/release), **not**
  `debugPrint` — `debugPrint` prints in release too, so the prior code leaked
  fatal traces to the production console:
  - `FlutterError.onError` keeps `FlutterError.presentError`, then echoes via
    `developer.log` and forwards as `ErrorLevel.fatal`.
  - `PlatformDispatcher.instance.onError` echoes via `developer.log`, forwards as
    `ErrorLevel.fatal`, and returns `true` (error handled).
- `installLogging({reporter, level})` ([./app_logger.dart](app_logger.dart))
  configures `Logger.root` and is **idempotent**: it `clearListeners()` first so
  repeated calls (and tests) never stack handlers on the shared root logger. The
  root level defaults to `Level.ALL` in debug and `Level.WARNING` in release (an
  explicit `level` overrides). Its single `onRecord` listener (1) emits every
  record to `dart:developer log()` and (2) for `Level.SEVERE`+ forwards to
  `reporter.reportError(...)` inside a `try`/`catch` that swallows a throwing
  reporter — see the synchronous-listener invariant in "Things to Know".
- Startup wiring lives in [/lib/main.dart](../../main.dart): the
  `ProviderContainer` is created *outside* the guarded zone, the reporter is read
  from it, and the entire `main` body runs inside `runZonedGuarded` whose
  `onError` also forwards as `fatal`. The same container is handed to the widget
  tree via `UncontrolledProviderScope` (not `ProviderScope`) so the handlers and
  the tree share one reporter.
- The `ParseSkipReporting` extension (also in `error_reporter.dart`) exposes
  `parseSkipSink({context})`, which bridges a `parseList` `SkipCallback` to
  `reportError`. List repositories inject the reporter by constructor and pass the
  returned callback as `onSkip` on every `parseList` call (ENG-166); see
  [../serialization/docs.md](../serialization/docs.md).

### Things to Know

- **Three capture mechanisms coexist** (`FlutterError.onError`,
  `PlatformDispatcher.onError`, `runZonedGuarded`). `runZonedGuarded` is partly
  redundant with `PlatformDispatcher.onError` on Flutter ≥3.3; it is kept as
  defense-in-depth and to catch zone/`print` errors.
- **Zone safety is why the container is created outside the zone.** Creating it
  does not touch the binding, so it avoids the "Zone mismatch" assertion while
  still letting `ensureInitialized()` and `runApp` share the one guarded zone.
- **The future Sentry adapter must own the bootstrap.**
  `SentryFlutter.init(appRunner:)` installs the global handlers itself, so the
  adapter must NOT also call `installGlobalErrorHandlers`, or every error is
  reported twice.
- **Child isolates are not covered.** `PlatformDispatcher.onError` does not catch
  errors from child isolates. The app does spawn short-lived background isolates
  for off-UI work (the `compute`-based CRC32C helper in
  [/lib/core/util/docs.md](../util/docs.md); see ADR-0004), but `compute`
  propagates an isolate failure back through the caller's `Future`, so those
  errors surface at the awaiting call site rather than escaping to the global
  handlers. A fire-and-forget isolate would not be covered.
- **The app-root `ProviderContainer` is never disposed** — intentional, it lives
  for the process lifetime.
- **The logging→reporter bridge runs synchronously inside every `Logger` call,
  so it must never throw.** `Logger.root.onRecord.listen` fires on the same stack
  as the code that logged; a `reporter.reportError` that threw would propagate
  into unrelated callers. The forward is therefore wrapped in a
  swallow-everything `try`/`catch` — telemetry is best-effort and cannot crash the
  code emitting a log. This is the system-boundary exception to the app's
  otherwise-bubble-up error policy.
- **`installLogging` is idempotent by design.** It clears existing root listeners
  before attaching its own, so re-wiring (or a test harness calling it per case)
  cannot stack duplicate handlers on the process-global `Logger.root`.
- **`debugPrint` is not a release no-op.** It prints in every build mode; only
  `dart:developer log()` is silenced by the VM under AOT/release. Both the global
  hooks and the logging facade route through `developer.log` for exactly that
  reason, so no diagnostics leak to the production console.
- **Raw `print` / `debugPrint` is banned outside this directory and `test/`.**
  The `avoid_raw_print` rule in [/packages/obt_lints/](../../../packages/obt_lints)
  (ENG-190, closing an ADR-0010 follow-up) flags any no-receiver
  `print`/`debugPrint` call, exempting only files under this folder (the one
  legitimate spot for a low-level fallback) and `test/`. This is what keeps app
  code routing diagnostics through the `package:logging` facade above rather than
  re-scattering raw calls.
- Behavior is verified by the tests under
  [/test/core/observability/](../../../test/core/observability/): both Flutter
  hooks forward at `fatal`, `PlatformDispatcher.onError` returns `true`, and the
  Noop methods never throw across all argument shapes.

Created and maintained by Nori.
