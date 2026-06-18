# ADR-0010: Logging facade

- Status: Accepted
- Date: 2026-06-18
- Epic: E3 (Error Handling & Observability)
- Related: ENG-96, ADR-0006

## Context

Application diagnostics were ~84 raw `debugPrint(...)` calls spread across ~24
files, with no central control over level, formatting, or destination, and no
connection to the `ErrorReporter` telemetry seam (ADR-0006).

Two facts drove the decision:

- `debugPrint` is **not** a release no-op. It prints in every build mode (only
  its throttling differs); only `dart:developer log()` is silenced by the VM in
  AOT/release. The prior code (and the observability `docs.md`) assumed the
  opposite, so those ~84 lines were spilling to the production console while
  remaining invisible to any crash backend.
- The codebase already has a vendor-neutral, swappable, Riverpod-wired
  `ErrorReporter` (ADR-0006). A logging facade should mirror that seam rather
  than invent a parallel one, and severe diagnostics should be able to reach it.

## Decision

Introduce a thin logging facade in `lib/core/observability/app_logger.dart`
backed by the first-party `package:logging`.

- **Backend: `package:logging`.** It supplies `Logger`/`Level`, named
  (hierarchical) loggers, and an `onRecord` stream — the same "does nothing
  until you attach a sink" property the `ErrorReporter` seam already relies on.
  It was already a transitive dependency, so adopting it adds no new transitive
  packages. A hand-rolled wrapper was rejected: it would re-implement `Level`
  and a sink abstraction for no benefit. `logger`/`talker` were rejected as
  heavier than needed given the existing `ErrorReporter`/Sentry path.
- **One sink, wired once.** `installLogging({required reporter, level})` is
  called from `main()` right after `installGlobalErrorHandlers`. It attaches a
  single `Logger.root.onRecord` listener that (1) emits every record to
  `dart:developer log()` (self-silencing in release) and (2) forwards records at
  `Level.SEVERE`+ to `reporter.reportError(...)`, mapping `SHOUT → fatal`,
  `SEVERE → error`. The forward is wrapped in a guard so a throwing reporter
  never propagates back into the synchronous log call.
- **Build-mode gating.** Root level defaults to `Level.ALL` in debug and
  `Level.WARNING` in release (overridable, e.g. in tests).
- **Call sites** use idiomatic named loggers (`Logger('SegmentedRecorder')`),
  so no dependency injection was threaded through the ~24 migrated files.
- **No double-reporting.** The global error hooks (`installGlobalErrorHandlers`,
  the `runZonedGuarded` `onError`) keep their own `reporter.reportError` and only
  their *console echo* moved to `dart:developer log()`; they are deliberately
  NOT routed through the facade. Likewise, call sites that already report to the
  `ErrorReporter` log at `warning`/`info` (not `severe`) so a fault is reported
  once. Expected conditions (401/`UnauthorizedException`, intentional best-effort
  fallbacks) never log at `severe`.

## Consequences

- Production console output is quiet by default; severe diagnostics become
  observable through the same backend that will later be Sentry (ADR-0006).
- The facade and the `ErrorReporter` stay distinct concerns with a one-way
  bridge (logging → reporter for severe records), the same shape as the
  `parseSkipSink` bridge.
- A regression risk remains: nothing yet prevents new raw `debugPrint`/`print`
  calls. A lint rule banning them outside the facade (mirroring the existing
  `obt_lints` color ban) is a candidate follow-up, intentionally out of scope
  here.
- `dart:developer log()` output is not asserted in tests (it targets the VM
  service); the facade's behavior is covered through the `ErrorReporter` bridge
  and level gating instead.
