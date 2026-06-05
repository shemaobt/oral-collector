# ADR-0001: Sealed AppException hierarchy + typed boundary mapping

- Status: Accepted
- Date: 2026-06-04
- Ticket: ENG-99 (Refactor Wave 1, epic E3)

## Context

Error handling was stringly-typed: ~52 sites threw `Exception('Failed to X: ${response.body}')`, embedding the raw HTTP body (PII/security risk) into the message. The UI (`friendlyErrorMessage`) then reverse-engineered those strings back into user messages via substring matching — a brittle coupling. Only two custom exceptions existed (`UnauthorizedException`, `ForbiddenException`), both carrying a user-facing string in `toString()`. There was no base type, no mapping for Socket/timeout/4xx/5xx, and `Error.throwWithStackTrace` was used 0×. 409/Conflict was handled nowhere.

This is foundation work for E2/E4/E5/E8. We are NOT migrating the ~52 throws now.

## Decision

- Introduce `sealed class AppException implements Exception` with `final class` leaves: `NetworkException`, `TimeoutException`, `UnauthorizedException`, `ForbiddenException`, `ValidationException`, `ServerException`, `ConflictException`. All leaves live in one library, `lib/core/errors/app_exception.dart`.
- Each exception carries a stable machine `code` plus dev context (`statusCode`, `cause`, `traceId`). It carries **no** user-facing string and **no** raw response body — `cause` stores only the originating type. `toString()` is for logs/diagnostics only.
- Add a boundary helper `lib/core/network/error_boundary.dart`: `throwForStatus(int)` / `throwForResponse(http.Response)` map HTTP status → exception; `guard<T>(body)` maps `SocketException`→`NetworkException` and `dart:async` timeout→`TimeoutException`, rethrowing via `Error.throwWithStackTrace` to preserve the original stack.
- `TimeoutException` keeps the ticket name despite colliding with `dart:async.TimeoutException`. The collision is resolved only inside `error_boundary.dart` via `import 'dart:async' as async;`.
- Consolidate the two legacy exceptions into the hierarchy (no user string). `api_exception.dart` becomes a re-export shim (`show UnauthorizedException, ForbiddenException`) so existing imports and `const` zero-arg construction keep working unchanged. `guardResponse` keeps its exact 401/403 contract (now `AppException` leaves, with `traceId` populated).
- UI: `error_helpers.dart` gains `messageForException` (exhaustive `switch` over the sealed type → `l10n.error_*`) and `friendlyErrorFor(Object)` which dispatches typed-first and falls back to the legacy string matcher. `showErrorSnackBar` now accepts `Object`.
- Begin using it conservatively: the consolidated `guardResponse` (a chokepoint already wired into ~36 sites) and the tested helpers. No repository call sites are migrated in this change.

## Consequences

- ENG-147 (E8) adds its `ParseException` leaf to this same library AND a case to the `messageForException` switch — the `sealed` exhaustiveness makes that a compile error until handled (intended coupling).
- `code`/`traceId` are best-effort until ENG-81 lands a standardized error envelope and correlation header: `code` is derived from the status (`server_500`, `client_404`, ...), `traceId` is read from `x-request-id`/`x-trace-id`/`x-correlation-id` when present.
- 404 maps to `ValidationException` (`code: client_404`); no dedicated `NotFoundException` is introduced (404 is sometimes non-exceptional, e.g. delete treats it as success).
- `error_conflict`/`error_validation` l10n keys do not exist yet, so `ConflictException`→`error_serverFailure` and `ValidationException`→`error_generic`. Dedicated copy is a follow-up (touches 12 `.arb` files).
- A transitional safety net keeps UI behavior intact for legacy call sites that stringify errors before the UI: `friendlyErrorMessage` now also matches `unauthorized` (the diagnostic `toString()` token). Removed as call sites migrate in E2/E4/E5.
- Two `TimeoutException` types now coexist; any file needing both must alias `dart:async`.
