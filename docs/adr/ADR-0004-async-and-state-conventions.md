# ADR-0004: Async & state conventions

- Status: Accepted (execution conventions; state-exposure conventions deferred)
- Date: 2026-06-04
- Epic: E5 (Asynchrony)
- Related: ENG-90, ENG-137, ENG-138, ADR-0000, ADR-0007

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
- The pre-existing de-facto `Future.wait` sites (admin `fetchAll`, project/home
  loaders) are consistent with this ADR.
