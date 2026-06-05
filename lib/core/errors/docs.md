# Noridoc: Core Errors

Path: @/lib/core/errors

### Overview

- Defines the app's typed domain error hierarchy: `sealed class AppException`
  with `final class` leaves (Network, Timeout, Unauthorized, Forbidden,
  Validation, Server, Conflict) in [./app_exception.dart](app_exception.dart).
- The defining invariant is that an exception carries **no user-facing string
  and no raw response body**: only a stable machine `code`, optional
  `statusCode`, a `cause` that holds **only the originating type**, and a
  best-effort `traceId`. `toString()` exists for logs/diagnostics, never for
  display.
- [./api_exception.dart](api_exception.dart) is a backward-compatibility
  re-export shim. It re-exports only `UnauthorizedException` and
  `ForbiddenException` so the pre-existing imports and zero-arg `const`
  construction keep compiling unchanged; new code imports
  [./app_exception.dart](app_exception.dart) directly.

### How it fits into the larger codebase

- This is the foundation of the typed error-handling refactor (ENG-99, epic
  E3), introduced as groundwork for E2/E4/E5/E8. The rationale, alternatives,
  and consequences live in
  [the ADR](../../../docs/adr/0001-sealed-app-exception.md).
- Exceptions are produced at the network boundary in
  [../network/error_boundary.dart](../network/error_boundary.dart), which maps
  HTTP status and transport failures into these leaves. See
  [../network/docs.md](../network/docs.md).
- Exceptions are consumed at the UI boundary by
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart):
  `messageForException` is an **exhaustive** `switch` over the sealed type that
  maps each leaf to an `l10n.error_*` key, and `friendlyErrorFor(Object)`
  dispatches typed-first before falling back to legacy string matching. The
  snack bar entry point is
  [../../shared/widgets/error_snack_bar.dart](../../shared/widgets/error_snack_bar.dart).
- `UnauthorizedException` is the one leaf the app branches on by type, not just
  for display: [../auth/auth_notifier.dart](../auth/auth_notifier.dart) catches
  it to drive session-expiry/refresh handling.
- The ~52 legacy `throw Exception('Failed to X: ${response.body}')` call sites
  in the feature repositories are intentionally **not** migrated yet; they
  still flow through the legacy string fallback. This folder is the target they
  migrate toward in later waves.

### Core Implementation

- `AppException` is `sealed`, so the compiler knows the complete set of leaves.
  Every leaf is a `final class` defined in the **same library**
  ([./app_exception.dart](app_exception.dart) declares `library;`) because
  `sealed` requires all subtypes to be co-located. A new leaf cannot be added
  from another file.
- Leaf fields:

  | Leaf | Default `code` | `statusCode` | Extra |
  | --- | --- | --- | --- |
  | `NetworkException` | `network` | none | — |
  | `TimeoutException` | `timeout` | none | — |
  | `UnauthorizedException` | `unauthorized` | 401 | — |
  | `ForbiddenException` | `forbidden` | 403 | — |
  | `ValidationException` | `validation` | optional | `field` |
  | `ServerException` | `server` | required | — |
  | `ConflictException` | `conflict` | 409 | — |
  | `ParseException` | `parse` | none | `field`, `expected` |

- The boundary overrides `code` with a status-derived value (e.g. `server_500`,
  `client_404`) when it constructs a leaf; the defaults above apply when a leaf
  is constructed directly with no status context.
- `toString()` builds a diagnostic line from `runtimeType`, `code`,
  `statusCode`, `traceId`, and `cause.runtimeType` — never the cause's message
  or any body.

### Things to Know

- **Adding a leaf is a deliberate compile-time tripwire.** Because
  `messageForException` in
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart)
  switches exhaustively over the sealed type with no default arm, adding a new
  leaf here breaks that switch until a case is added. ENG-147 (E8) added the
  `ParseException` leaf to [./app_exception.dart](app_exception.dart) — the
  home of the safe-readers in
  [../serialization/docs.md](../serialization/docs.md) — and the matching switch
  arm mapping it to `error_generic`; this coupling is the intended tripwire.
- **`cause` is the type only, never the value.** Leaves store
  `e.runtimeType`, not the caught object, so a `SocketException` message or an
  HTTP body can never leak through the exception into a log or the UI.
- **`code` and `traceId` are best-effort until ENG-81.** `code` is derived from
  the HTTP status, and `traceId` is read from response headers, because the
  backend does not yet return a standardized error envelope or a fixed
  correlation header.
- **`TimeoutException` here collides with `dart:async.TimeoutException`.** The
  domain leaf keeps the ticket name; the collision is resolved only inside
  [../network/error_boundary.dart](../network/error_boundary.dart) via
  `import 'dart:async' as async;`. Any other file that needs both types must
  alias one of them.
- **No dedicated `NotFoundException`.** 404 maps to `ValidationException`
  because 404 is sometimes non-exceptional (e.g. a delete treats it as
  success), so a 404-specific leaf was deliberately left out of scope.

Created and maintained by Nori.
