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
  [../../shared/widgets/error_snack_bar.dart](../../shared/widgets/error_snack_bar.dart),
  whose `showErrorSnackBar(context, Object)` calls `friendlyErrorFor`.
- **The exception type is preserved until that UI boundary (ENG-173).** Feature
  state holds the *raw* exception, not a pre-localized string: every notifier's
  `error` field is typed `Object?` and a catch stores `copyWith(error: e)` — never
  `e.toString()`. Stringifying early (the old
  `e.toString().replaceFirst('Exception: ', '')`) discarded the type, forcing a
  typed leaf through the brittle string fallback and leaking custom messages /
  response bodies. Translation is exclusively the UI's job (`friendlyErrorFor`
  / `showErrorSnackBar`), so a typed leaf always reaches `messageForException`.
  ENG-100 routed the widget catch-sites it found that still called
  `friendlyErrorMessage(e.toString())` directly (file-import, trim-split,
  confirmation-step upload) through `friendlyErrorFor`, and ENG-104 finished the
  job for the remaining screen catch-sites that were still bypassing the typed
  path another way — passing `e.toString()`, a hardcoded English string, or an
  *already-localized* string (e.g.
  `recording_downloadFailed(e.toString())`) straight into `showErrorSnackBar` /
  raw `ScaffoldMessenger`. All of those now hand the **typed object** (`e`, or
  the notifier's `state.error`) to `showErrorSnackBar`, so a typed leaf reaches
  `messageForException` and `friendlyErrorMessage` is reached only via
  `friendlyErrorFor`'s fallback arm for genuinely untyped errors. That
  retained-but-legacy fallback (and its private `_humanizeDetail`) is now pinned
  by characterization tests
  ([../../../test/shared/utils/error_helpers_test.dart](../../../test/shared/utils/error_helpers_test.dart))
  so its input→output mapping is locked; it is **not** retired, since untyped
  `throw Exception('Failed to X')` repo call-sites still depend on it for
  specific copy and migrate toward the typed boundary in later waves. ENG-184
  corrected two branches those tests had pinned: `'upload failed'` no longer
  reuses the image key (now `error_serverFailure`, since a generic transport
  failure is not an image upload) and `'recording not found'` no longer maps to
  the import-empty key. ENG-184 also added a regression guard proving divergent
  typed leaves (Network/Conflict/Server) resolve via `messageForException` and
  never through the regex-over-`toString()` path. See the `error` invariant in
  [../auth/docs.md](../auth/docs.md).
- `UnauthorizedException` is the one leaf the app branches on by type, not just
  for display: [../auth/auth_notifier.dart](../auth/auth_notifier.dart) catches
  it to drive session-expiry/refresh handling. See [../auth/docs.md](../auth/docs.md)
  for the refresh contract and single-flight invariant.
- The legacy `throw Exception('Failed to X: ${response.body}')` call sites that
  remain in the feature repositories are intentionally **not** migrated yet; they
  still flow through the legacy string fallback. This folder is the target they
  migrate toward in later waves. `invite_repository` was migrated in ENG-173 — its
  no-body accept/decline now route any non-2xx through `throwForResponse`
  ([../network/error_boundary.dart](../network/error_boundary.dart)) and stop
  leaking the body — so it is the worked example of moving a no-body status path
  onto the typed boundary.

### Core Implementation

- `AppException` is `sealed`, so the compiler knows the complete set of leaves.
  Every leaf is a `final class` defined in the **same library**
  ([./app_exception.dart](app_exception.dart) declares `library;`) because
  `sealed` requires all subtypes to be co-located. A new leaf cannot be added
  from another file.
- Leaf fields. `retryable` (ENG-103) is intrinsic to the leaf: it answers
  "could re-issuing the identical request plausibly succeed?" and is what the
  upload queue branches on (see "Things to Know").

  | Leaf | Default `code` | `statusCode` | `retryable` | Extra |
  | --- | --- | --- | --- | --- |
  | `NetworkException` | `network` | none | true | — |
  | `TimeoutException` | `timeout` | none | true | — |
  | `UnauthorizedException` | `unauthorized` | 401 | false | — |
  | `ForbiddenException` | `forbidden` | 403 | false | — |
  | `ValidationException` | `validation` | optional | only when 429 | `field` |
  | `ServerException` | `server` | required | true | — |
  | `ConflictException` | `conflict` | 409 | false | — |
  | `ParseException` | `parse` | none | false | `field`, `expected` |

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
  ENG-148 then wired the first runtime producers (the safe-reader call-site
  migration), so `ParseException` now actually reaches this switch from live
  parse paths such as login and stats, not only as a compile-time tripwire.
- **`retryable` is intrinsic to the type, with 429 as the one status-dependent
  case.** Transport/transient leaves (`Network`, `Timeout`, `Server`) are
  retryable; auth/authorization/conflict and `ParseException` are not.
  `ValidationException` is retryable **only** for `statusCode == 429`, since a
  rate-limit is the one `4xx` that clears on its own. The sole consumer today is
  the upload queue in
  [../../features/sync/data/repositories/sync_engine.dart](../../features/sync/data/repositories/sync_engine.dart),
  which marks a row failed-and-retryable vs permanently-failed by this flag
  alone, never by the exception subtype — so the `429`-becomes-retryable rule is
  what flipped a rate-limited upload from terminal to retried (see
  [../../features/sync/docs.md](../../features/sync/docs.md)).
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
- **Screens hand `showErrorSnackBar` the typed object, never a string
  (ENG-104).** The single display entry point is
  [../../shared/widgets/error_snack_bar.dart](../../shared/widgets/error_snack_bar.dart)'s
  `showErrorSnackBar(context, Object)`; call sites pass the caught exception `e`
  or the notifier's `state.error`. Passing `e.toString()` discards the type and
  forces the regex fallback. Passing an **already-localized** string is worse: the
  fallback's substring rules re-map it — any message containing "permission" or
  "forbidden" collapses to `error_noPermission`, "timeout" to `error_timeout`,
  etc. — so a correctly-localized message can be silently rewritten into the wrong
  one. Localization happens exactly once, inside `friendlyErrorFor`. This is also
  why the hardcoded English permission string in project-settings was deleted:
  `ForbiddenException` now localizes through the type switch to `error_noPermission`.
- **A notifier mutation does not rethrow — screens must read `state.error`
  after the await (ENG-104).** The notifiers capture failures into their
  `Object?` `error` field and return normally (e.g. `updateProject` in
  [../../features/project/presentation/notifiers/project_notifier.dart](../../features/project/presentation/notifiers/project_notifier.dart);
  same shape as `fetchProjects` and the other notifier mutations). A `try/catch`
  around such a call is therefore dead code, and an unguarded happy path will
  show a false success. The contract for a notifier-driven screen action is:
  `await` the mutation, then check `state.error` (surface it via
  `showErrorSnackBar`) before treating the action as succeeded. The project-save
  screen was fixed to follow this — it previously caught nothing and showed a
  false "updated" toast on failure (regression pinned by
  [../../../test/features/project/presentation/project_settings_save_error_test.dart](../../../test/features/project/presentation/project_settings_save_error_test.dart)).

Created and maintained by Nori.
