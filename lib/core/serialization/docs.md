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
  incremental and behavior-preserving; **no call site is migrated in this
  change** — the helpers ship fully unit-tested first.
- This folder is where future E8 siblings land: an element-isolating
  `parseList<T>` (ENG-146), tolerant `fromWire` enum mapping (ENG-150), and
  decode/leaf-read helpers (ENG-153).

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
- The intended consumers are the feature `fromJson` factories under
  `lib/features/*/data/`, which today still force-cast. They migrate toward
  these readers in later waves; until then this folder has no inbound callers.
- The readers operate strictly **after** JSON decoding: they take a decoded
  `Map`, not bytes. They contain **no** `dart:convert`, no logging, and no l10n —
  pure functions with no side effects.
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
- **These are pure replacements, not a policy layer.** They decide *how* a field
  is read, not *whether* a bad record should fail the whole page. The
  skip-and-log-vs-fail page policy belongs to the element-isolating `parseList`
  and the call sites (per [ADR-0008](../../../docs/adr/ADR-0008-data-serialization.md)),
  not here.
- **No call sites consume these yet.** Adding the helpers does not change any
  runtime behavior on its own; the value is realized only as `fromJson`
  factories migrate to them in subsequent tickets.

Created and maintained by Nori.
