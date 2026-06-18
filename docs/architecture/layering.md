# Architecture: layering overview

This is the synthesis view of how the layers fit together. It does **not** repeat
the conventions and rules in [`AGENTS.md`](../../AGENTS.md) (the living standard
for the `features/<f>/{data,domain,presentation}` + `core/` split, the
repository/notifier/screen roles, and dependency injection). Read that first.
What follows is the cross-cutting glue that no single folder doc captures, plus
pointers to the per-folder `docs.md` files and the ADRs for detail.

## HTTP client convention (and the one deliberate exception)

Every **feature** repository under `lib/features/*/data/repositories/` takes an
injected `AuthenticatedClient` (`lib/core/network/`, provided by
`authenticatedClientProvider`). That client reads the bearer token from secure
storage, JSON-encodes bodies, and retries once after a 401 via a global
single-flight `TokenRefresher`. See [`lib/core/network/docs.md`](../../lib/core/network/docs.md).

`auth_repository` is the **single intentional exception**: it talks to the API
over a plain `http.Client` (the shared `httpClientProvider`), not
`AuthenticatedClient`. This is structural, not an oversight:

- It is the **token bootstrap**. `login`/`signup` run before any token exists,
  so token injection buys nothing there.
- It **owns the refresh endpoint**. `refreshToken` is what the `TokenRefresher`
  ultimately calls; if it went through `AuthenticatedClient`, a 401 on
  `/auth/refresh` would trigger another refresh — unbounded recursion.
- It would create a **Riverpod provider cycle**:
  `authenticatedClientProvider → authNotifier → authRepositoryProvider →
  authenticatedClientProvider`. `authenticatedClientProvider` already depends
  (transitively, via the refresher) on `authRepository`.

So "make every repo use `AuthenticatedClient`" is explicitly rejected for
`auth_repository`. The only cleanup applied was wiring it to the shared
`httpClientProvider` instead of constructing its own `http.Client`.

## Notifier data access

Notifiers read their **own feature's** repositories directly via that feature's
`data/providers.dart` (e.g. `recordings_list`, `sync`, `genre`, `member`). This
is the established convention; `lib/core/providers/` holds only genuinely
cross-cutting re-exports (e.g. `activeProjectProvider`), not a mandatory
indirection layer.

`home_notifier` aggregates across features (project, stats, local recordings),
so it reads from more than one feature — this is consistent with the convention
(home is the aggregation surface), not a layering defect, and was deliberately
left as-is.

## Observability vs errors (three distinct seams)

- **Typed domain errors** — `lib/core/errors/` (the `AppException` hierarchy).
  Flow through normal exception paths to the UI boundary. See
  [`ADR-0001`](adr/ADR-0001-error-model.md).
- **Telemetry / crash reporting** — `ErrorReporter` in
  `lib/core/observability/` (Noop default, Sentry-shaped, swappable via
  `errorReporterProvider`). See [`ADR-0006`](adr/ADR-0006-observability.md) and
  [`lib/core/observability/docs.md`](../../lib/core/observability/docs.md).
- **Developer diagnostics** — the logging facade
  (`lib/core/observability/app_logger.dart`, `package:logging`). Emits to
  `dart:developer log()` and forwards `SEVERE`+ records into the `ErrorReporter`.
  See [`ADR-0010`](adr/ADR-0010-logging-facade.md).

The one-way bridge is logging → reporter (severe records only). Reporting that
already happens explicitly at a call site does not also go through the facade, so
a fault is reported once.
