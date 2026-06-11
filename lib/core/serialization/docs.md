# Noridoc: Core Serialization

Path: @/lib/core/serialization

### Overview

- Home of the E8 serialization toolkit (ENG-147, [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md)).
  Holds the typed **safe-readers** in [./safe_read.dart](safe_read.dart): pure
  top-level functions that pull fields out of an already-decoded
  `Map<String, dynamic>` and throw a catchable
  [`ParseException`](../errors/app_exception.dart) instead of the uncatchable
  `TypeError`/`NoSuchMethodError` a raw cast (`json['x'] as String`) would.
- The safe-readers are the typed replacement for the hand-written
  `json['x'] as T` force-casts scattered across every `fromJson`. Migration is
  incremental and behavior-preserving: ENG-148 is the **first consuming wave**,
  routing the enumerated quick-win fragile casts (single scalar/string/nested-map
  reads at repository and DTO boundaries) through the readers. ENG-153 then added
  the centralized `decodeObject` / `decodeList` entry point in
  [../network/response_decoder.dart](../network/response_decoder.dart) and routed
  the **upload-pipeline** force-casts through it plus these readers (so a
  malformed payload can no longer escape the upload's `on Exception` handlers as
  an uncatchable `Error`). Broad `fromJson`-factory migration across every
  feature remains partial.
- The folder also holds the element-isolating **`parseList<T>`**
  ([./parse_list.dart](parse_list.dart), ENG-146): a page-policy layer, already
  consumed by the network-list endpoints, that maps a decoded array
  element-by-element and **skips-and-logs** bad records so one cannot blank a
  page. Where the safe-readers decide *how* a field is read, `parseList` decides
  *whether* a bad record drops the page. The status-check + decode + root-assert
  layer (`decodeObject` / `decodeList`, ENG-153) that produces the decoded `Map`
  / `List` these helpers consume landed one folder over in
  [../network/response_decoder.dart](../network/response_decoder.dart) (see
  [../network/docs.md](../network/docs.md)); a future E8 sibling still expected
  here is the tolerant `fromWire` enum mapping (ENG-150).

### How it fits into the larger codebase

- The single dependency is [../errors/app_exception.dart](../errors/app_exception.dart):
  every contract violation surfaces as `ParseException`, a `final` leaf of the
  `sealed AppException`. See [../errors/docs.md](../errors/docs.md).
- The motivating problem is that a raw cast throws an `Error`, not an
  `Exception`, so it escapes the `on Exception` handlers used everywhere and can
  blank a list page, fail login, or crash sync. Converting to `ParseException`
  lets the existing UI-boundary mapping in
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart)
  handle it (it maps to `error_generic`).
- The first safe-reader consumers landed in ENG-148: a curated set of fragile
  force-casts at the data boundary — repository response parsing (e.g. stats
  counts, login/signup token extraction) and a server DTO scalar field. ENG-153
  extended this to the **upload pipeline**, replacing the response force-casts in
  the sync engine, the resumable upload service, and the direct uploader with
  `decodeObject` + these readers — the path where an uncatchable `Error` was most
  damaging because it stranded a recording mid-upload. The broader population of
  feature `fromJson` factories under `lib/features/*/data/` still force-cast and
  migrates incrementally, so much of this folder's inbound surface is still ahead
  of it.
- `parseList` (ENG-146) is, by contrast, already wired at the network-list
  boundary: every list-returning repository method routes its decoded array
  through it — genre
  [`listGenres`](../../features/genre/data/repositories/genre_repository.dart),
  the project list/language/member reads
  ([project_repository_impl.dart](../../features/project/data/repositories/project_repository_impl.dart)),
  and the admin queues
  ([admin_repository.dart](../../features/admin/data/repositories/admin_repository.dart)) —
  plus the invite-dialog user search
  ([invite_dialog.dart](../../shared/widgets/invite_dialog.dart)). Single-object
  reads (`getProject`, login, create/update) deliberately stay fail-fast and do
  not use it.
- The readers operate strictly **after** JSON decoding: they take a decoded
  `Map`, not bytes. They contain **no** `dart:convert`, no logging, and no l10n —
  pure functions with no side effects. `parseList` is the one deliberate
  exception in the folder: as a policy layer it **does** log each skipped element
  (via `dart:developer`), an intentional side effect, not a reader concern.
- Rationale, the rejected codegen alternatives (`freezed`, `json_serializable`),
  and the verified backend wire contract live in
  [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md).

### Core Implementation

- Two variants per type. `readX` requires the key **present, non-null, and of
  the expected type**. `readXOrNull` returns `null` for an absent/null key but
  still **throws** on a present value of the wrong type — a malformed value is a
  contract violation, not an optional miss (equivalent to `as T?`, only the
  thrown type changes from `Error` to `Exception`).
- Numerics (`readInt`/`readDouble`) accept any `num` and convert, mirroring the
  existing `(x as num).toInt()/.toDouble()` call sites rather than demanding the
  exact runtime type.
- `readInt` guards non-finite doubles: `NaN`/`Infinity` would make `toInt()`
  throw an uncatchable `UnsupportedError`, so a non-finite value becomes a
  `ParseException` instead.
- `readDate` parses an ISO-8601 string via `DateTime.parse` and wraps the
  resulting `FormatException` as a `ParseException`. Tolerance beyond
  String-plus-parse is out of scope.
- `readMap` is **load-bearing for nested access**: it converts the
  `NoSuchMethodError` of a chained `data['x']['y']` (when `x` is absent) into a
  `ParseException`, and returns a typed `Map<String, dynamic>` so successive
  reads chain off its result.
- **`parseList<T>`** ([./parse_list.dart](parse_list.dart)) wraps a decoded list
  as a page-policy layer, not a per-field reader. A non-`List` `raw` is a broken
  container, not a bad row, so it **fails fast** with a `ParseException` (the
  `context` argument becomes the exception's `field`; `expected` is `'List'`). A
  `List` is mapped element-by-element; any element whose `parse` throws is caught
  and **skipped-and-logged**, and the surviving elements are returned.
- `parseList`'s per-element `catch` is intentionally **broad** (`Error` *and*
  `Exception`): the `fromJson` factories it drives still force-cast, so a bad
  element surfaces as an `Error` that escapes `on Exception`, and the collection
  boundary is where it is contained. Skips log via `dart:developer` at warning
  level by default; an injectable `onSkip` callback overrides the sink (tests use
  it to assert which indices were dropped).

### Things to Know

- **A wrong-typed value is always fatal, even in the `…OrNull` path.** Absent or
  explicitly-null keys are the only thing `readXOrNull` tolerates; anything
  present-but-malformed throws. This is the deliberate boundary between
  "optional field" and "broken contract".
- **The readers carry the no-raw-value invariant through `ParseException`.**
  They pass the offending value as `cause`, but `ParseException.toString()`
  redacts it to its runtime type — so the value never leaks through the
  exception's `toString()`. The `cause` field still holds the live object, so
  log `e` (or its `toString()`), never `e.cause` directly. See
  [../errors/docs.md](../errors/docs.md).
- **Safe-readers are the "how"; `parseList` is the "whether".** The readers
  decide *how* a field is read — pure, no logging, no side effects — not
  *whether* a bad record should fail the whole page. That skip-and-log-vs-fail
  page policy now lives in the element-isolating `parseList` and its call sites
  (per [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md)), which logs
  each skipped element on purpose — exactly the side effect the readers refuse.
- **The first wave is wired (ENG-148); migration is still partial.** Two
  complementary moves landed: the enumerated quick-win casts now route through
  these readers, so a malformed payload surfaces as a catchable `ParseException`
  instead of an uncatchable `Error`; and the persisted-cache read sites that
  still call un-migrated `fromJson` factories widened their catch to a broad
  `catch (_)`, so a corrupt cached record degrades to a cache-miss instead of
  crashing on the `Error` those factories still throw. That broad catch is the
  deliberate bridge until those factories adopt the readers.
- **Caches deliberately do not use `parseList`; they invalidate wholesale.** The
  persisted-cache read sites
  ([genre_cache.dart](../../features/genre/data/genre_cache.dart),
  [project_cache.dart](../../features/project/data/project_cache.dart)) wrap the
  *entire* decode in one broad `catch (_)` and return null on any malformed
  element — dropping the whole blob, not the bad row. This ENG-148 choice is
  distinct from `parseList`'s skip-and-log: a cache is a uniform format the app
  wrote itself, so one malformed element almost always means schema drift, which
  makes the whole cache suspect — better to refetch than surface a partial list.
  Skip-and-log is reserved for network **list** responses, where dropping one bad
  row keeps the rest of the server page visible.

Created and maintained by Nori.
