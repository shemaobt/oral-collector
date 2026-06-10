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
- The cleartext guard lives one folder over in
  [../config/url_policy.dart](../config/url_policy.dart) (`isHttpsUrl` /
  `assertHttpsUrl`) and is enforced at this edge: `AuthenticatedClient.put`
  asserts the scheme of any full caller URL before sending. See "Things to
  Know" for the policy and the app-wide scheme invariant.

### How it fits into the larger codebase

- `AuthenticatedClient` (in [./authenticated_client.dart](authenticated_client.dart))
  is provided via `authenticatedClientProvider` and consumed by feature
  repositories under `lib/features/*/data/repositories/`. It injects the bearer
  token, JSON-encodes bodies, and retries once after a 401 **only when** the
  `TokenRefresher` callback (wired to `handleUnauthorized` in
  [../auth/auth_notifier.dart](../auth/auth_notifier.dart)) reports a successful
  refresh. Every 401 invokes the refresher — there is no per-client guard
  skipping concurrent attempts — because the refresh itself is coalesced
  globally in `AuthNotifier` (ENG-136, see [../auth/docs.md](../auth/docs.md));
  concurrent 401s therefore await the **same** rotation and all retry. A 401 on
  the refresh itself (session truly expired) skips the retry; a transient
  refresh failure (network/timeout/5xx/parse) propagates and also skips the
  retry — see "Things to Know".
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
- **`put` is the only method that accepts a full caller-supplied URL**, so it
  is the only one that re-asserts the scheme. `get`/`post`/`patch`/`delete`
  build their target from `baseUrl` (which is `Env.backendUrl`, already
  validated when resolved — see [../config/env.dart](../config/env.dart)), so
  re-checking them would be redundant. `put` is the path the upload transport
  uses for server-provided presigned GCS URLs, which never pass through
  `baseUrl`.

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
  `_withRefresh` calls the refresher on every 401 and, on success, re-issues the
  request. Recursion safety does **not** come from a per-client flag: the retry
  is a raw `request()` that does not re-enter `_withRefresh`, so a request makes
  at most one retry. Deduping of concurrent refreshes is now a **global
  single-flight** in `AuthNotifier._tryRefresh` (ENG-136), shared by every
  refresh path (this client's callback, the fire-and-forget genre/project/stats
  notifiers, and the boot `tryAutoLogin`); concurrent 401s await one rotation
  and all retry, instead of all-but-one skipping the retry and failing with a
  401. The refresher is `handleUnauthorized` in
  [../auth/auth_notifier.dart](../auth/auth_notifier.dart), and its return /
  throw fully determines what reaches the repository's `guardResponse`:

  | Refresh outcome | `handleUnauthorized` | `_withRefresh` | Caller sees |
  | --- | --- | --- | --- |
  | Refresh OK | returns `true` | re-issues the request | the retried response (no `UnauthorizedException`) |
  | Refresh 401 (expired) | returns `false`, clears the session | skips retry, returns the original 401 | `UnauthorizedException` |
  | Refresh transient (network/timeout/5xx/parse) | **propagates**, session preserved | exception unwinds out of `_withRefresh`, no retry | the transient leaf, **not** a 401 |

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

- **The cleartext (HTTPS) scheme policy is enforced in Dart, not just by the
  platform.** `package:http` rides Dart's `HttpClient`, which the platform
  cleartext policies (Android network-security-config, iOS ATS) do not cover,
  so the scheme check is a pure-Dart guard in
  [../config/url_policy.dart](../config/url_policy.dart) (IPv4 parsed by hand,
  no `dart:io`, to stay web-safe). The policy:

  | Build | http allowed? | https allowed? |
  | --- | --- | --- |
  | non-release (`kReleaseMode` false) | loopback / RFC1918 private hosts only (`localhost`, `127/8`, `10/8`, `172.16/12`, `192.168/16`) | always |
  | release | never | always |

  The private-host carve-out exists so the emulator host (`10.0.2.2`) and LAN
  dev backends (`192.168.x.x`) keep working under `--dart-define=BACKEND_URL`;
  a host that merely contains `localhost` (e.g. `localhost.evil.com`) is **not**
  treated as loopback. `assertHttpsUrl` redacts the rejected value to
  `scheme://host` so a signed URL's query/signature never reaches logs or crash
  reports.
- **System invariant — no recording bytes are ever PUT over cleartext.** Two
  deliberate error models enforce this. Config/contract sites **throw**:
  `Env.backendUrl` ([../config/env.dart](../config/env.dart)) and
  `AuthenticatedClient.put` raise `ArgumentError`. Upload-transport sites use
  the `isHttpsUrl` predicate plus each layer's existing graceful failure, so a
  bad URL fails closed rather than crashing a background upload — the server's
  presigned `upload_url` / `session_uri` is validated at the server→app
  boundary before any PUT in
  [../../features/sync/data/services/resumable_upload_service.dart](../../features/sync/data/services/resumable_upload_service.dart)
  and
  [../../features/recording/data/services/direct_recording_uploader.dart](../../features/recording/data/services/direct_recording_uploader.dart).

Created and maintained by Nori.
