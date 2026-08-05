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
  `guardResponse` chokepoint (401/403 only) that the conservative repository
  sites still call after a request; it delegates to the boundary while preserving
  its exact prior contract.
- [./response_decoder.dart](response_decoder.dart) is the centralized typed-decode
  entry point: `decodeObject` / `decodeList` perform status-check → `jsonDecode`
  → root-shape assert in one call, so a malformed server payload surfaces as a
  **catchable** `AppException`/`FormatException` instead of an uncatchable
  `TypeError`. This is the throw-side fix for the Error-vs-Exception escape that
  motivated ENG-143/ENG-153 — see "Things to Know".
- The cleartext guard lives one folder over in
  [../config/url_policy.dart](../config/url_policy.dart) (`isHttpsUrl` /
  `assertHttpsUrl`) and is enforced at this edge: `AuthenticatedClient.put`
  asserts the scheme of any full caller URL before sending. See "Things to
  Know" for the policy and the app-wide scheme invariant.

### How it fits into the larger codebase

- `AuthenticatedClient` (in [./authenticated_client.dart](authenticated_client.dart))
  is provided via `authenticatedClientProvider` and consumed by **every** feature
  repository under `lib/features/*/data/repositories/` — with one deliberate,
  permanent exception, the auth repository (below). It injects the bearer
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
- **The auth repository is the single deliberate exception that does NOT use
  `AuthenticatedClient`.** `authRepositoryProvider`
  ([../auth/providers.dart](../auth/providers.dart)) injects a **raw**
  `http.Client` — the shared `httpClientProvider`
  ([../providers/http_client_provider.dart](../providers/http_client_provider.dart)),
  so it still rides the app's connection-timeout / web-vs-IO client, not a
  per-repository `http.Client()` — into `AuthRepositoryImpl`
  ([../../features/auth/data/repositories/auth_repository_impl.dart](../../features/auth/data/repositories/auth_repository_impl.dart)).
  Three reasons make this permanent: (1) it is the **token bootstrap** —
  login/signup precede the existence of any bearer token, so there is nothing for
  `AuthenticatedClient` to inject; (2) it **owns the refresh endpoint**, which must
  not itself trigger a 401-driven refresh or it would recurse; and (3) depending
  on `authenticatedClientProvider` would close a **Riverpod provider cycle** —
  `authenticatedClient` reads `authNotifier` (its `TokenRefresher` is
  `handleUnauthorized`), `authNotifier` reads `authRepository`, so routing
  `authRepository` back through `authenticatedClient` is a dependency loop. See
  [../auth/docs.md](../auth/docs.md).
- The boundary produces the leaves defined in
  [../errors/app_exception.dart](../errors/app_exception.dart); the UI consumes
  them in
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart).
  These leaves travel **untranslated** all the way to that UI boundary: feature
  notifiers store the raw exception in their `Object?` `error` field and only the
  UI calls `friendlyErrorFor` / `showErrorSnackBar` (ENG-173), so the type the
  boundary picks here is the type that reaches `messageForException`. See
  [../errors/docs.md](../errors/docs.md) for the hierarchy and its invariants, and
  [the ADR](../../../docs/adr/0001-sealed-app-exception.md) for the rationale.
- The repository layer reaches the boundary through three fronts.
  `guardResponse` (401/403 only) is still wired into the conservative sites that
  need bespoke status semantics (auth, recording, admin, user-lookup, stats,
  storyteller, project). Most **body-decoding** reads/creates were migrated to
  `decodeObject` / `decodeList`, which fold the full status check into the decode
  (any non-2xx → typed leaf via `throwForResponse`), so those paths no longer throw
  the legacy `Exception('Failed to X: ${response.body}')`. A **no-body** status path
  can also call `throwForResponse` directly for the full status table:
  `invite_repository`
  ([../../features/invite/data/repositories/invite_repository.dart](../../features/invite/data/repositories/invite_repository.dart))
  does exactly this for accept/decline (ENG-173), replacing the old
  `guardResponse` + bespoke `Exception('Failed to … : body)`. The legacy throw now
  survives mainly on the remaining **no-body** paths (deletes and a few mutations
  that do not parse a response root) that still keep `guardResponse` plus the
  bespoke `Exception`. Conservative status-semantics sites keep their own handling
  and use the decoder only for the safe decode — see "Things to Know".

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
- `decodeObject` / `decodeList` in
  [./response_decoder.dart](response_decoder.dart) are the status-check + decode +
  root-assert layer that sits between a raw `http.Response` and a typed
  `fromJson`/safe-reader. Each (1) delegates **any** non-2xx status to
  `throwForResponse` (so the full status table applies, not just 401/403), then
  (2) `jsonDecode`s the body — a non-JSON body raises the SDK `FormatException` —
  then (3) asserts the decoded root is the expected `Map`/`List`, raising
  `ParseException` ([../errors/app_exception.dart](../errors/app_exception.dart))
  on a wrong-shaped root. They replace the repeated
  `jsonDecode(response.body) as Map<String, dynamic>` / `as List` force-cast and
  **compose**, not compete, with the serialization layer: list endpoints wrap the
  result in `parseList` ([../serialization/parse_list.dart](../serialization/parse_list.dart))
  for per-element tolerance, and object endpoints feed the decoded `Map` to the
  `safe_read` leaf readers ([../serialization/safe_read.dart](../serialization/safe_read.dart))
  for individual fields. See [../serialization/docs.md](../serialization/docs.md).
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
- **The decode helpers exist to keep a malformed *server payload* catchable
  (Error-vs-Exception invariant, ENG-143/ENG-153).** A failed `as Map`/`as List`
  cast on a decoded body throws `TypeError`, a subclass of `Error`, **not**
  `Exception`. The upload pipeline catches `on Exception` deliberately — a
  programmer-error `Error` should propagate as a crash — so a malformed payload
  (a *server* problem, not a programmer bug) escaped every `on Exception` handler
  and left a recording wedged mid-upload, never transitioned to `markAsFailed`.
  `decodeObject` / `decodeList` convert that bad payload into a catchable
  `ParseException` / `FormatException` (both `Exception`s), so the **existing**
  handlers catch it and degrade gracefully. The fix is purely on the **throw**
  side: **no catch block was changed**, preserving the app-wide
  "catch `on Exception` only" policy. The same reasoning underlies the
  `safe_read` leaf readers ([../serialization/docs.md](../serialization/docs.md))
  and `parseList`'s broad per-element catch.
- **The decoder applies the *full* status table; conservative sites must guard
  status before calling it.** Because `decodeObject` / `decodeList` route any
  non-2xx through `throwForResponse`, a site that needs a non-exceptional status
  outcome (404 → `null`, non-200 → empty/`{}`, or a login 401 that must read as
  "bad credentials" rather than `UnauthorizedException`) checks the status and
  returns/throws **before** calling the decoder, then uses the decoder only for
  the 2xx safe decode. The known conservative callers are `auth_repository_impl`
  (login/signup keep `Exception('… failed')` so a 401 is not an
  `UnauthorizedException` — and note this repository is also the one that runs on
  a **raw** `http.Client`, not `AuthenticatedClient`; see "How it fits"),
  `user_lookup_provider` (404 → `null`), and the stats reads
  (`StatsRepositoryImpl`, `ProjectRepositoryImpl.getProjectStats`) which return
  `{}` on non-200.
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
  no `dart:io`, to stay web-safe). As of ENG-133 this Dart guard is backed by
  **OS-layer defense-in-depth**: an Android `network-security-config` blocks
  cleartext for non-debug builds (a debug overlay re-permits it for LAN/loopback
  dev backends), and the web deploy sends HSTS — both are infra-level and
  documented in [ADR-0005](../../../docs/adr/ADR-0005-security-policy.md), not a
  `docs.md`. The Dart policy:

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
