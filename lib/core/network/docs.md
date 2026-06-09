# Noridoc: Core Network

Path: @/lib/core/network

### Overview

- The HTTP edge of the app. Holds the authenticated HTTP client used by every
  feature repository, plus the error boundary that converts HTTP/transport
  failures into the typed `AppException` hierarchy.
- [./error_boundary.dart](error_boundary.dart) is the single place that maps
  raw failures into domain exceptions: `throwForStatus` / `throwForResponse`
  (HTTP status -> leaf) and `guard<T>` (transport exceptions -> leaf).
- [./api_error_handler.dart](api_error_handler.dart) exposes the narrow
  `guardResponse` chokepoint that most repositories already call after each
  request; it now delegates to the boundary while preserving its exact prior
  contract.

### How it fits into the larger codebase

- `AuthenticatedClient` (in [./authenticated_client.dart](authenticated_client.dart))
  is provided via `authenticatedClientProvider` and consumed by feature
  repositories under `lib/features/*/data/repositories/`. It injects the bearer
  token, JSON-encodes bodies, and retries once after a 401 **only when** the
  `TokenRefresher` callback (wired to `handleUnauthorized` in
  [../auth/auth_notifier.dart](../auth/auth_notifier.dart)) reports a successful
  refresh. A 401 on the refresh itself (session truly expired) skips the retry;
  a transient refresh failure (network/timeout/5xx/parse) propagates and also
  skips the retry — see "Things to Know".
- The boundary produces the leaves defined in
  [../errors/app_exception.dart](../errors/app_exception.dart); the UI consumes
  them in
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart).
  See [../errors/docs.md](../errors/docs.md) for the hierarchy and its
  invariants, and
  [the ADR](../../../docs/adr/0001-sealed-app-exception.md) for the rationale.
- `guardResponse` is already wired into the repository layer (auth, recording,
  project, genre, storyteller, admin, user, stats, ...). Those repositories
  still throw legacy `Exception('Failed to X: ${response.body}')` for non
  401/403 statuses; the boundary did not change that, so those call sites are
  migrated only in later waves.

### Core Implementation

- Status mapping in `throwForStatus`:

  | Status | Leaf | `code` |
  | --- | --- | --- |
  | 401 | `UnauthorizedException` | `unauthorized` |
  | 403 | `ForbiddenException` | `forbidden` |
  | 409 | `ConflictException` | `conflict` |
  | >= 500 | `ServerException` | `server_<status>` |
  | >= 400 (incl. 404) | `ValidationException` | `client_<status>` |
  | other | `ServerException` | `unexpected_<status>` |

- `throwForResponse(http.Response)` extracts a `traceId` from the response
  headers before delegating to `throwForStatus`. It tries
  `x-request-id`, `x-trace-id`, then `x-correlation-id` and uses the first
  non-empty value (a `needs-api`/ENG-81 stopgap until the header is
  standardized).
- `guard<T>(body)` wraps an async operation: it rethrows any `AppException`
  unchanged (so a boundary that already mapped a status is not re-wrapped),
  maps `SocketException` -> `NetworkException`, and maps
  `dart:async` `TimeoutException` -> the domain `TimeoutException`.
- `guardResponse(response)` in
  [./api_error_handler.dart](api_error_handler.dart) throws **only** on 401 and
  403 (delegating to `throwForResponse`); every other status passes through for
  the caller to handle. This is the historical contract — the consolidation
  kept the same statuses and leaf types and only added `traceId` population.

### Things to Know

- **`guard` preserves the original stack trace.** It rethrows via
  `Error.throwWithStackTrace(leaf, st)` rather than a bare `throw`, so the
  domain exception surfaces with the stack of the underlying
  `SocketException` / timeout instead of the boundary frame. The leaf stores
  only `e.runtimeType` as its `cause`, never the original object.
- **`on AppException { rethrow; }` ordering matters.** It is the first catch in
  `guard` so an exception already mapped by `throwForStatus` is passed through
  untouched and not double-wrapped as a `NetworkException`/`TimeoutException`.
- **`TimeoutException` is aliased here and only here.** The domain
  `TimeoutException` collides with `dart:async.TimeoutException`; this file
  imports `dart:async as async` so it can catch the SDK type while throwing the
  domain type. Other files that import the domain leaf must apply their own
  alias if they also need the SDK one.
- **404 is intentionally a `ValidationException`, not a not-found leaf.** It
  falls into the `>= 400` arm; there is no dedicated `NotFoundException`
  because 404 is sometimes a non-exceptional outcome (e.g. delete-then-404 is
  treated as success by callers).
- **The 401 retry in `AuthenticatedClient` happens before `guardResponse`,
  and the `TokenRefresher` contract decides between three outcomes.**
  `_withRefresh` calls the refresher once on a 401 (guarded by `_isRefreshing`
  against recursion) inside a `try`/`finally` that resets the flag. The
  refresher is `handleUnauthorized` in
  [../auth/auth_notifier.dart](../auth/auth_notifier.dart), and its return /
  throw fully determines what reaches the repository's `guardResponse`:

  | Refresh outcome | `handleUnauthorized` | `_withRefresh` | Caller sees |
  | --- | --- | --- | --- |
  | Refresh OK | returns `true` | re-issues the request | the retried response (no `UnauthorizedException`) |
  | Refresh 401 (expired) | returns `false`, clears the session | skips retry, returns the original 401 | `UnauthorizedException` |
  | Refresh transient (network/timeout/5xx/parse) | **propagates**, session preserved | exception unwinds through `finally`, no retry | the transient leaf, **not** a 401 |

  Before ENG-141 the refresher swallowed every non-401 failure as `return true`,
  so `_withRefresh` re-ran the request with the still-stale token and a real
  network/timeout error was masked as a 401. The current contract is the fix:
  only a genuine 401 on the refresh clears the session, and a transient failure
  surfaces its own leaf so feature notifiers that catch `UnauthorizedException`
  (genre/project/stats) fall through to their generic `on Exception` arm
  instead. Because `handleUnauthorized` can now throw, its fire-and-forget
  callers guard it: those notifiers wrap the call in `.catchError` so a
  transient throw on a 401 that does reach them never escapes as an unhandled
  async error, and the boot path `tryAutoLogin` catches the transient throw to
  keep the cached session offline-first.

Created and maintained by Nori.
