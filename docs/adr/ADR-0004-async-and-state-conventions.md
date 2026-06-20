# ADR-0004: Async & state conventions

- Status: Accepted (execution conventions; state-exposure conventions deferred)
- Date: 2026-06-04
- Epic: E5 (Asynchrony)
- Related: ENG-90, ENG-137, ENG-138, ENG-154, ADR-0000, ADR-0007

## Context

Async patterns and Riverpod state conventions vary across features (how futures
are awaited or fired-and-forgotten, how notifiers expose state, how loading and
error states are represented). Wave 1 E5 standardizes these conventions.

This ADR is the home for the conventions behind two rules staged in ADR-0007:
`unawaited_futures` and `riverpod_lint`'s `avoid_public_notifier_properties`.

## Decision

This ADR is initially scoped to **async execution conventions** (ENG-137,
ENG-138). The Riverpod state-exposure conventions it will also own remain
governed for now by the lint rules staged in ADR-0007 (`unawaited_futures`,
`avoid_public_notifier_properties`).

### CPU-bound work runs off the UI isolate

CPU-bound work over non-trivial input (e.g. hashing a file up to a few MB) must
not run synchronously on the UI isolate. Use one helper that branches on
platform:

- **Native:** run it in a background isolate via `compute`
  (`package:flutter/foundation`). `compute` delegates to `Isolate.run` on
  native and — unlike a bare `dart:isolate` import — stays compilable for web,
  so a shared helper file remains web-safe.
- **Web (no isolates):** chunk the work and yield to the event loop between
  chunks with `await Future<void>.delayed(Duration.zero)`. Do **not** yield with
  a microtask (`await null` / `scheduleMicrotask`) — microtasks run before the
  browser renders, so a microtask loop still freezes the UI.

Reference: `lib/core/util/crc32c_async.dart` (off-isolate CRC32C for upload
integrity). When feeding the isolate, prefer passing a file *path* over a large
byte buffer so the bytes are read inside the isolate instead of being copied
across the boundary.

### Independent awaits run concurrently

A run of `await`s on operations that do not depend on one another should be
issued together with `Future.wait` instead of serialized (e.g. per-file or
per-record fan-out). Ordering-dependent steps — inputs the fan-out needs, or
consumers of its results — stay sequential before/after the `Future.wait`.

When the results are **consumed** (heterogeneous types fanned into a state
object), prefer the Dart-3 **record form** `final (a, b) = await (fa, fb).wait`
over `Future.wait([...])`. The record `.wait` recovers per-position static
typing, so the consumer drops the positional `results[i] as X` casts that
`Future.wait`'s `List<dynamic>` result forces. Reference:
`admin_notifier.fetchAll`
(`lib/features/admin/presentation/notifiers/admin_notifier.dart`).

The record form is **not** a drop-in replacement, because its failure model
differs: `(a, b).wait` raises a `ParallelWaitError` if any future fails, and
`ParallelWaitError` extends `Error` (it is **not** an `Exception`), whereas
`Future.wait` rethrows the first underlying error directly. So the record form
is only safe where either:

- each future is **individually error-guarded** before entering the record, so
  the aggregate never fails — `admin_notifier.fetchAll` wraps each future in
  `.catchError((_) => null)` and substitutes prior state per slot, so it cannot
  raise `ParallelWaitError`; or
- the surrounding `catch` handles `Error` (a bare `catch` / `on Object`), not
  just `Exception` subtypes.

This is why not every `Future.wait` site is convertible. A site whose
`try`/`catch` **discriminates `Exception` subtypes** must keep `Future.wait`:
`project_notifier.fetchProjects`
(`lib/features/project/presentation/notifiers/project_notifier.dart`) catches
`on UnauthorizedException` / `on Exception`, so a `ParallelWaitError` would slip
past both clauses — breaking the 401-refresh path and leaving `isLoading` stuck.

### Fan-out over unbounded collections is concurrency-limited

When the collection is caller- or DB-driven (unknown size) and each operation
hits an external resource (network/server), cap concurrency with `mapBounded`
(`lib/core/util/bounded_concurrency.dart`) rather than an unbounded
`Future.wait`, so a large batch cannot launch hundreds of simultaneous
requests. Local, fast operations (file stat/delete) may use an unbounded
`Future.wait`.

## Consequences

- The app gains its first background-isolate usage; `compute` is the sanctioned
  entry point — no direct `Isolate.run` / `dart:isolate` in shared or
  web-compiled code.
- Hashing a multi-MB upload no longer blocks frame rendering on native, and
  degrades gracefully via cooperative chunking on web.
- Batch operations (e.g. admin batch-clean) bound their pressure on the backend.
- The pre-existing de-facto concurrent-await sites are consistent with this ADR.
  Admin `fetchAll` consumes its results, so it uses the typed record form
  `(…).wait` (safe because each future is individually error-guarded); the
  project and home loaders keep `Future.wait` (the home loader fans out
  side-effecting `Future<void>`s with nothing to type, and `fetchProjects`
  cannot adopt the record form without losing its `Exception`-discriminating
  catch — see "Independent awaits run concurrently").
