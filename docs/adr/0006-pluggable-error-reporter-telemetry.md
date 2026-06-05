# ADR-0006: Pluggable ErrorReporter/Telemetry (Noop) + global error capture

- Status: Accepted
- Date: 2026-06-04
- Ticket: ENG-101 (Refactor Wave 1, epic E3)

## Context

`main.dart`'s global error hooks (`FlutterError.onError`, `PlatformDispatcher.instance.onError`) only called `debugPrint` — a no-op in release. There was no `runZonedGuarded`, no reporting abstraction, and no logging/crash package, so uncaught errors were invisible in production. We want a pluggable sink now and a Sentry adapter later (decision locked: Sentry deferred), with behavior preserved meanwhile.

## Decision

- Define `ErrorReporter` (`abstract interface class`) in `lib/core/observability/error_reporter.dart` with `reportError`, `addBreadcrumb`, `setUser`, `clearUser`, `setTag`, plus an `ErrorLevel` enum. Method signatures mirror `sentry_flutter` so a future adapter is a thin pass-through. YAGNI: no `reportMessage`.
- `NoopErrorReporter` (const) is the default, exposed via `errorReporterProvider`. It drops everything, preserving the prior release behavior.
- `installGlobalErrorHandlers(reporter)` routes both `FlutterError.onError` and `PlatformDispatcher.instance.onError` through the reporter at `ErrorLevel.fatal`, keeping the existing `FlutterError.presentError` + `debugPrint` calls.
- `main()` creates a `ProviderContainer` outside the guarded zone, reads the reporter, then runs the entire startup body inside `runZonedGuarded`, handing the same container to the tree via `UncontrolledProviderScope` (not `ProviderScope`). `runApp` and `WidgetsFlutterBinding.ensureInitialized()` therefore share one zone.

## Consequences

- `runZonedGuarded` is partially redundant with `PlatformDispatcher.onError` on Flutter ≥3.3 (which this app targets). It is kept per the ticket as defense-in-depth and to capture zone/`print` errors; all three hooks coexist. Consequence for a real adapter: an uncaught async error reaches both `PlatformDispatcher.onError` and the zone `onError`, so the adapter must dedupe (or drop one hook) to avoid reporting it twice.
- **Future Sentry adapter:** `SentryFlutter.init(appRunner: ...)` installs the global handlers itself. The adapter must own the bootstrap and must NOT also call `installGlobalErrorHandlers`, or errors would be double-reported. It is wired purely via `errorReporterProvider.overrideWithValue(...)`; no call sites change.
- **Child isolates:** `PlatformDispatcher.onError` does not catch errors from child isolates. The app uses none today (`compute()`/`Isolate.spawn` absent), so this is a documented limitation, not a gap.
- **Zone safety:** the whole `main` body runs inside the zone; creating the container outside is safe because it does not touch the binding. This avoids the "Zone mismatch" assertion.
- The app-root `ProviderContainer` is intentionally never disposed (process lifetime).
- Behavior preserved: with the Noop default, the handlers do exactly what they did before (`presentError` + `debugPrint`); reporting is additive and zero-cost.
