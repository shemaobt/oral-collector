# Noridoc: Core Observability

Path: @/lib/core/observability

### Overview

- Pluggable crash/telemetry layer: a vendor-neutral `ErrorReporter` interface, a
  `NoopErrorReporter` default (drops everything), a Riverpod
  `errorReporterProvider`, and `installGlobalErrorHandlers`, which routes
  Flutter's global error hooks through whichever reporter is wired in.
- Exists because the app previously had no reporting abstraction, no
  `runZonedGuarded`, and no crash package — its global hooks only called
  `debugPrint`, a no-op in release, so uncaught production errors were invisible.
- Default behavior is intentionally identical to before (Noop drops everything);
  reporting is additive and zero-cost until a real adapter replaces the default.
  See [/docs/adr/0006-pluggable-error-reporter-telemetry.md](../../../docs/adr/0006-pluggable-error-reporter-telemetry.md).

### How it fits into the larger codebase

- This is the app-wide global error sink. It sits below the feature layers and
  is consumed at process startup by [/lib/main.dart](../../main.dart), which is
  the only caller of `installGlobalErrorHandlers`.
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
- Notifiers never telemeter a 401: it is the expected token-refresh flow, not a
  fault, so reporting it would be noise. Notifiers with an `on UnauthorizedException`
  arm (project/genre/stats/invite) catch it there (driving `handleUnauthorized`), so
  it never reaches the generic report. Those without that arm (member/storyteller/
  admin) route reporting through a `_reportUnexpected` guard that skips
  `UnauthorizedException` while still surfacing the error to the UI.
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
- `installGlobalErrorHandlers(reporter)` wires both global hooks:
  - `FlutterError.onError` keeps `FlutterError.presentError` + `debugPrint`, then
    forwards as `ErrorLevel.fatal`.
  - `PlatformDispatcher.instance.onError` `debugPrint`s, forwards as
    `ErrorLevel.fatal`, and returns `true` (error handled).
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
- Behavior is verified by the tests under
  [/test/core/observability/](../../../test/core/observability/): both Flutter
  hooks forward at `fatal`, `PlatformDispatcher.onError` returns `true`, and the
  Noop methods never throw across all argument shapes.

Created and maintained by Nori.
