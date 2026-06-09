# Noridoc: Core Serialization

Path: @/lib/core/serialization

### Overview

- Home of the E8 serialization toolkit ([ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md)),
  holding two layers with deliberately different contracts: the pure
  **safe-readers** in [safe_read.dart](safe_read.dart) (ENG-147) and the
  **page-policy** list parser `parseList` in [parse_list.dart](parse_list.dart)
  (ENG-146).
- The **safe-readers** pull a single field out of an already-decoded
  `Map<String, dynamic>` and throw a catchable
  [`ParseException`](../errors/app_exception.dart) instead of the uncatchable
  `TypeError`/`NoSuchMethodError` a raw cast (`json['x'] as String`) would. They
  are the typed replacement for the hand-written force-casts in every `fromJson`;
  migration is incremental and **no factory has migrated yet**, so they ship
  fully unit-tested with no inbound callers.
- **`parseList<T>`** maps a decoded list element-by-element and
  **skips-and-logs** any element that fails, so one malformed record cannot blank
  a whole page. Unlike the safe-readers it is **already consumed** — the list
  repositories, the offline caches, and the user-search UI route their list
  decoding through it (see How it fits). Still-future E8 siblings are tolerant
  `fromWire` enum mapping (ENG-150) and decode/leaf-read helpers (ENG-153).

### How it fits into the larger codebase

- The single dependency is [../errors/app_exception.dart](../errors/app_exception.dart):
  every contract violation — a safe-reader's wrong-typed field, or `parseList`
  handed a non-`List` container — surfaces as `ParseException`, a `final` leaf of
  the `sealed AppException`. See [../errors/docs.md](../errors/docs.md).
- The motivating problem is shared by both layers: a raw cast throws an `Error`,
  not an `Exception`, so it escapes the `on Exception` handlers used everywhere
  and can blank a list page, fail login, or crash sync. The safe-readers fix this
  *per field*; `parseList` contains it *per element* at the collection boundary
  while the `fromJson` factories still force-cast.
- **`parseList` is the only consumed surface in this folder.** Its callers are
  the list-shaped data paths across features: the list methods of the feature
  repositories (e.g. genre, project, and admin list endpoints under
  `lib/features/*/data/repositories/`), the `read()` of the offline caches
  ([../../features/genre/data/genre_cache.dart](../../features/genre/data/genre_cache.dart),
  [../../features/project/data/project_cache.dart](../../features/project/data/project_cache.dart)),
  and the user-search UI
  ([../../shared/widgets/invite_dialog.dart](../../shared/widgets/invite_dialog.dart)).
  Single-object reads (`getProject`, login, create/update) deliberately do
  **not** use it and stay fail-fast.
- The **safe-readers'** intended consumers are those same `fromJson` factories,
  which today still force-cast; they migrate toward the readers in later waves
  and have no inbound callers until then.
- Both layers operate strictly **after** JSON decoding: they take a decoded
  `Map`/value, never bytes, and contain no `dart:convert` and no l10n. Their
  `ParseException` is mapped to copy at the UI boundary by
  [../../shared/utils/error_helpers.dart](../../shared/utils/error_helpers.dart)
  (it maps to `error_generic`).
- Rationale, the rejected codegen alternatives (`freezed`, `json_serializable`),
  the verified backend wire contract, and the **page policy** (collections
  skip-and-log, single objects fail) live in
  [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md).

### Core Implementation

- **Safe-readers — two variants per type.** `readX` requires the key **present,
  non-null, and of the expected type**; `readXOrNull` returns `null` for an
  absent/null key but still **throws** on a present value of the wrong type — a
  malformed value is a contract violation, not an optional miss (equivalent to
  `as T?`, only the thrown type changes from `Error` to `Exception`).
- **Safe-reader edge cases.** Numerics (`readInt`/`readDouble`) accept any `num`
  and convert; `readInt` additionally guards non-finite doubles, since
  `NaN`/`Infinity` would make `toInt()` throw an uncatchable `UnsupportedError`.
  `readDate` parses ISO-8601 via `DateTime.parse` and wraps the `FormatException`.
  `readMap` is load-bearing for nested access: it converts the `NoSuchMethodError`
  of a chained `data['x']['y']` into a `ParseException` and returns a typed map so
  reads chain.
- **`parseList` — element-isolating map.** Takes the decoded raw value, a
  per-element `parse` function, an optional `context` label, and an optional
  `onSkip` sink. It iterates, runs `parse` on each element inside a **broad**
  try/catch, collects the successes, and routes each failure to the sink — so the
  returned list is whatever parsed cleanly.
- **`parseList` catches `Error` and `Exception` per element.** This breadth is
  required because the `fromJson` factories still force-cast and surface a bad
  element as an `Error`; it is forward-compatible for when they migrate to
  throwing `ParseException`.
- **`parseList` shape fail-fast.** A non-`List` `raw` is a broken container, not
  a bad row, so it throws `ParseException(expected: 'List')` instead of
  skipping — converting the old `as List` cast (an uncatchable `Error`) into a
  catchable `Exception`. The `context` argument becomes that exception's `field`.
- **`parseList` logging.** With no `onSkip`, a default sink logs each skip via
  `dart:developer` at warning level, tagged with `context`; `onSkip` is
  injectable for tests and observability.

### Things to Know

- **Two contracts share one folder.** The safe-readers decide *how* a field is
  read (pure, fail on a broken contract); `parseList` decides *whether* a bad
  record fails the page (skip per element, fail only on a broken container). Per
  [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md), collection
  endpoints skip-and-log and single-object reads fail-fast.
- **`parse_list.dart` is the deliberate exception to this folder's purity.** The
  safe-readers have no side effects; `parseList` intentionally writes a
  `dart:developer` warning for every skipped element, because a silently dropped
  record needs a breadcrumb. It is the only logging in the folder.
- **A wrong-typed value is always fatal to a safe-reader, even in the `…OrNull`
  path** — absent or explicitly-null keys are the only thing tolerated. Inside
  `parseList` that same throw is caught and the element skipped: same reader,
  different blast radius.
- **No-raw-value invariant.** Both layers pass the offending value as
  `ParseException.cause`, but `toString()` redacts it to its runtime type, so the
  value never leaks; log `e`, never `e.cause`. See
  [../errors/docs.md](../errors/docs.md).
- **The offline caches layer a two-level policy on `parseList`.** Their `read()`
  wraps the parse in `try { … } on Exception { return null; }`: a corrupt
  container (unparseable JSON, or a non-`List` that makes `parseList` throw
  `ParseException`) invalidates the whole cache (null → refetch), while an
  isolated bad element is skipped and a partial list is returned. This also closed
  a latent bug — that outer `on Exception` never caught the `Error` the old
  force-cast `.map(... as ...)` threw. See
  [../../features/genre/data/docs.md](../../features/genre/data/docs.md) and
  [../../features/project/data/docs.md](../../features/project/data/docs.md).

Created and maintained by Nori.
