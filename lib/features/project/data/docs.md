# Noridoc: Project Data Layer

Path: @/lib/features/project/data

### Overview

- Owns the side-effecting backends for projects: the HTTP repositories that
  list/create/update projects, languages, and members, plus the device-local
  cache that survives offline launches.
- Project persistence sits behind an injectable `ProjectCache` interface
  ([project_cache.dart](project_cache.dart)) so the cache-read and cache-write
  timing can be decoupled in tests; the real `SharedPreferences` singleton
  couples them, which made an ordering race untestable (ENG-80).
- `providers.dart` ([providers.dart](providers.dart)) wires the cache and both
  repositories as Riverpod `Provider`s consumed by the notifiers in the
  presentation layer.

### How it fits into the larger codebase

- Project data is one of the app's most widely-watched state sources. The
  presentation notifier
  ([/lib/features/project/presentation/notifiers/project_notifier.dart](../presentation/notifiers/project_notifier.dart))
  is the single source of truth (`projectNotifierProvider`) for the project
  list, available languages, and the user's **active project**. Screens across
  home, profile, and recording watch it because the active project scopes
  recording capture, file import, and the recordings list; this folder supplies
  the data that backs that state.
- `ProjectRepositoryImpl`
  ([repositories/project_repository_impl.dart](repositories/project_repository_impl.dart))
  and `StatsRepositoryImpl`
  ([repositories/stats_repository_impl.dart](repositories/stats_repository_impl.dart))
  implement the domain contracts
  ([/lib/features/project/domain/repositories](../domain/repositories)) and talk
  to the backend through the shared
  [/lib/core/network/authenticated_client.dart](../../../core/network/authenticated_client.dart),
  running responses through `guardResponse`
  ([/lib/core/network/api_error_handler.dart](../../../core/network/api_error_handler.dart))
  so a 401 surfaces as the `UnauthorizedException` the notifier hands to
  [/lib/core/auth/auth_notifier.dart](../../../core/auth/auth_notifier.dart).
- Both the repository and the cache serialize via `Project.fromJson` /
  `toJson` and `Language.fromJson` / `toJson`
  ([/lib/features/project/domain/entities](../domain/entities)), so the
  on-device cache format is the server's JSON shape and stays in sync with the
  wire contract automatically.

### Core Implementation

- `ProjectCache` exposes `read()` (nullable) and `write(projects, languages)`.
  Unlike a single-list cache, both collections travel together in one
  `ProjectCacheSnapshot` value type, persisted under separate keys
  (`cached_projects` / `cached_languages`). `read()` keys off the projects blob:
  null when nothing is cached or the blob is corrupt, with an empty language
  list tolerated.
- `SharedPreferencesProjectCache` intentionally swallows any malformed-cache
  failure with a broad `catch` and returns null, so a corrupt cache degrades to
  an empty/offline state rather than throwing. The catch is broad rather than
  `on Exception` because the un-migrated `Project.fromJson` / `Language.fromJson`
  still force-cast, so a bad cached record raises a cast `Error`, not an
  `Exception` (ENG-148); it narrows once those factories adopt the safe-readers
  in [/lib/core/serialization](../../../core/serialization/docs.md).
- The repositories are thin request wrappers: they guard the response, fail
  loudly on unexpected status codes, and map JSON into entities. The
  list-returning reads route their array through `parseList`
  ([/lib/core/serialization](../../../core/serialization/docs.md)), which
  **skips-and-logs** a malformed element instead of failing the page, while
  single-object reads (`getProject`, create/update) stay fail-fast. Both differ
  from the cache above, which drops the whole snapshot on any bad record. They do
  not cache; caching is the notifier's decision after a successful fetch.
- The mutation/stats surface is **typed at the repository boundary** (ENG-94):
  `updateProject`/`createProject` take a `ProjectUpdate`
  ([../domain/entities/project_update.dart](../domain/entities/project_update.dart))
  whose `toJson` builds the PATCH body, and `getProjectStats` returns a parsed
  `ProjectStats`
  ([../domain/entities/project_stats.dart](../domain/entities/project_stats.dart))
  instead of a raw `Map`. `ProjectUpdate.toJson` encodes the partial-update
  distinction: a `null` field is omitted (left untouched) while a
  `clearDescription` flag emits an explicit `null` to clear it — the wire cannot
  otherwise tell "leave alone" from "clear". `ProjectStats.fromJson` reads its
  counters through the safe-readers
  ([/lib/core/serialization](../../../core/serialization/docs.md)) and its fields
  are nullable so a caller can fall back to the project's own counts.
- The notifier hydrates from `ProjectCache.read()` on build (fire-and-forget, so
  cached data appears before the network returns) and persists the enriched
  project list via `ProjectCache.write()` after a successful fetch.

### Things to Know

- **Server-wins-after-fetch invariant.** Build kicks off cache hydration without
  awaiting it, so a slow `read()` can resolve after a fast `fetchProjects()` has
  already populated fresh server data. Hydration bails when the fetch has
  completed, checked via `lastFetched` on `ProjectState`
  ([/lib/features/project/presentation/notifiers/project_state.dart](../presentation/notifiers/project_state.dart)).
  The `ProjectCache` seam exists primarily to make this ordering testable.
- **Hydration guards twice.** Unlike the genre cache
  ([/lib/features/genre/data](../../genre/data)), project hydration performs an
  extra `await` (`_restoreActiveProject`, which reads/writes prefs) between the
  read and the `state =`. A second `lastFetched` re-check closes the window where
  a fetch completes during that gap, so a late hydration still cannot clobber
  authoritative server data.
- **The active-project id lives outside this cache.** The user's selected
  project (`active_project_id`) has its own lifecycle and is read/written
  directly in `SharedPreferences` by the notifier, deliberately kept out of
  `ProjectCache`. The cache carries only the project/language reference data.
- **`fetchProjects` does not de-duplicate.** Whereas the genre notifier short-
  circuits a redundant fetch once data is loaded, project fetch always re-hits
  the server because it backs pull-to-refresh on multiple screens (home and
  projects). Here `lastFetched` serves exclusively the hydration guard, never
  fetch de-duplication.
- **`getProjectStats` now throws on non-200; "best-effort" lives at the call
  site, not the repository.** It previously returned an empty `Map` on any
  non-200, silently hiding the failure. It now routes non-200 through
  `throwForResponse` ([/lib/core/network](../../../core/network/docs.md)) like
  the other reads. The settings screen
  ([../presentation/project_settings_screen.dart](../presentation/project_settings_screen.dart))
  is the only caller and wraps the stats fetch in its own `try`/`catch`,
  falling back to the project's own counts so a stats failure no longer fails
  the whole screen load. Note this stats endpoint lives on
  `ProjectRepositoryImpl`, distinct from `StatsRepositoryImpl`.
- **Provider override is the supported injection point.** Tests and any
  alternate backend swap the cache by overriding `projectCacheProvider`; nothing
  else in the app constructs `SharedPreferencesProjectCache` directly.

Created and maintained by Nori.
