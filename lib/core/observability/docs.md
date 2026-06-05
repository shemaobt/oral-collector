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
  manually would read the same provider rather than constructing a reporter.
- It is distinct from [/lib/core/errors/](../errors/), which holds typed
  domain/API failures (e.g. `ApiException`) that flow through normal `Result`/
  exception paths. Observability is the catch-all for *uncaught* errors and
  future telemetry, not domain error modeling.
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
  errors from child isolates; the app spawns none today, so this is a documented
  limitation rather than a gap.
- **The app-root `ProviderContainer` is never disposed** — intentional, it lives
  for the process lifetime.
- Behavior is verified by the tests under
  [/test/core/observability/](../../../test/core/observability/): both Flutter
  hooks forward at `fatal`, `PlatformDispatcher.onError` returns `true`, and the
  Noop methods never throw across all argument shapes.

Created and maintained by Nori.
