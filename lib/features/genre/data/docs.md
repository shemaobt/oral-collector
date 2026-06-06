# Noridoc: Genre Data Layer

Path: @/lib/features/genre/data

### Overview

- Owns the two side-effecting backends for the genre taxonomy: the HTTP
  repository that lists genres from the server and the device-local cache that
  survives offline launches.
- Genre persistence sits behind an injectable `GenreCache` interface
  ([genre_cache.dart](genre_cache.dart)) so the cache-read and cache-write
  timing can be decoupled in tests; the real `SharedPreferences` singleton
  couples them, which made an ordering race untestable.
- `providers.dart` ([providers.dart](providers.dart)) wires both backends as
  Riverpod `Provider`s consumed by the genre notifier in the presentation
  layer.

### How it fits into the larger codebase

- The genre taxonomy is read-only reference data shared across the app. The
  presentation notifier
  ([/lib/features/genre/presentation/notifiers/genre_notifier.dart](../presentation/notifiers/genre_notifier.dart))
  is the single source of truth (`genreNotifierProvider`), and many screens
  watch it: the home screen
  ([/lib/features/home/presentation/home_screen.dart](../../home/presentation/home_screen.dart))
  triggers the fetch, and recording screens resolve genre / subcategory names
  for display, classification, and filtering. This folder supplies the data;
  it holds no observable state of its own.
- `GenreRepositoryImpl` ([repositories/genre_repository.dart](repositories/genre_repository.dart))
  implements the domain contract
  ([/lib/features/genre/domain/repositories/genre_repository.dart](../domain/repositories/genre_repository.dart))
  and talks to the backend through the shared
  [/lib/core/network/authenticated_client.dart](../../../core/network/authenticated_client.dart),
  running every response through `guardResponse`
  ([/lib/core/network/api_error_handler.dart](../../../core/network/api_error_handler.dart))
  so a 401 surfaces as the same `UnauthorizedException` the notifier hands to
  [/lib/core/auth/auth_notifier.dart](../../../core/auth/auth_notifier.dart).
- Both backends serialize via `Genre.fromJson` / `Genre.toJson`
  ([/lib/features/genre/domain/entities/genre.dart](../domain/entities/genre.dart)),
  so the on-device cache format is the server's JSON shape and stays in sync
  with the wire contract automatically.

### Core Implementation

- `GenreCache` exposes `read()` (nullable: null when nothing is cached or the
  blob is unreadable) and `write(genres)`. `SharedPreferencesGenreCache`
  stores the genre list as a JSON string under a single key and intentionally
  swallows any malformed-cache failure with a broad `catch`, returning null so a
  corrupt cache degrades to an empty/offline state rather than throwing. The
  catch is broad rather than `on Exception` because the un-migrated
  `Genre.fromJson` still force-casts, so a bad cached record raises a cast
  `Error`, not an `Exception` (ENG-148); it narrows to a catchable
  `ParseException` once that factory adopts the safe-readers in
  [/lib/core/serialization](../../../core/serialization/docs.md).
- The repository is a thin GET wrapper: it guards the response, fails loudly
  on non-200, and maps the JSON array into `Genre` entities. It does not cache;
  caching is the notifier's decision after a successful fetch.
- The notifier hydrates from `GenreCache.read()` on build (fire-and-forget, so
  cached genres appear before the network returns) and persists via
  `GenreCache.write()` only after a successful `listGenres()`.

### Things to Know

- **Server-wins-after-fetch invariant.** Build kicks off cache hydration
  without awaiting it, so a slow `read()` can resolve after a fast
  `fetchGenres()` has already populated fresh server data. Hydration is
  guarded to bail when the fetch has completed (it checks `lastFetched` on
  `GenreState`, [/lib/features/genre/presentation/notifiers/genre_state.dart](../presentation/notifiers/genre_state.dart)),
  so a late cache read can never clobber authoritative server data. The
  `GenreCache` seam exists primarily to make this ordering testable.
- **Cache writes are best-effort and unconditional on fetch success.** Every
  successful fetch overwrites the cached blob; there is no staleness check on
  the cache itself. Freshness is governed entirely by the notifier's
  `lastFetched` / `isLoading` fetch de-duplication, not by the cache.
- **Provider override is the supported injection point.** Tests and any
  alternate backend swap the cache by overriding `genreCacheProvider`; nothing
  else in the app constructs `SharedPreferencesGenreCache` directly.

Created and maintained by Nori.
