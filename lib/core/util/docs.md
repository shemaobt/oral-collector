# Noridoc: Core Util

Path: @/lib/core/util

### Overview

- Cross-cutting, feature-agnostic helpers with no Riverpod or platform
  dependencies: the GCS upload-integrity CRC32C primitives and the bounded
  concurrency primitive for fanning work out.
- This folder is the sanctioned home for the async-execution conventions in
  [/docs/adr/ADR-0004-async-and-state-conventions.md](../../../docs/adr/ADR-0004-async-and-state-conventions.md):
  CPU-bound work runs off the UI isolate, and unbounded network fan-out is
  concurrency-limited. The helpers here are the reference implementations the
  ADR points coding agents at.

### How it fits into the larger codebase

- `crc32c_async.dart` / `crc32c.dart` are consumed by the upload transport to
  validate that bytes landed in GCS intact: the resumable/single-PUT service
  ([/lib/features/sync/data/services/docs.md](../../features/sync/data/services/docs.md))
  and the web direct uploader
  ([/lib/features/recording/data/docs.md](../../features/recording/data/docs.md)).
  The computed client CRC is checked against the GCS `x-goog-hash` header after
  the PUT; `parseGcsCrc32cHeader` (in `crc32c.dart`) extracts the server value.
- `bounded_concurrency.dart` (`mapBounded`) is consumed where a caller- or
  DB-driven batch hits the network/server — e.g. the admin batch-clean fan-out
  in `admin_notifier.dart`. Local, fast fan-out (file stat/delete in the sync
  notifier) uses a plain `Future.wait` instead.
- This is the app's **first background-isolate usage**. The off-isolate entry
  point is `compute` from `package:flutter/foundation`; per ADR-0004 there is no
  direct `Isolate.run` / `dart:isolate` in shared or web-compiled code. The
  observability layer
  ([/lib/core/observability/docs.md](../observability/docs.md)) notes that a
  `compute` failure propagates back through the caller's `Future` rather than
  escaping to the global error handlers.

### Core Implementation

- `Crc32c` (in `crc32c.dart`) is an incremental Castagnoli register: callers
  feed it chunks with `add` and read `base64BigEndian` (the format GCS reports).
  Because it is a running register, the result is independent of where chunk
  boundaries fall — which is what lets the same hash be produced one-shot, in
  cooperative chunks, or by streaming a file.
- `crc32cBytesBase64` (in `crc32c_async.dart`) hashes an in-memory buffer off
  the UI isolate, branching on platform: native delegates to a background
  isolate via `compute`; web (no isolates) falls back to
  `crc32cBytesBase64Chunked`, which hashes a chunk at a time and yields to the
  event loop between chunks.
- The path-based file hash used by the resumable transport reads **and** hashes
  the file inside the background isolate from its path, so a multi-MB byte
  buffer is never copied across the isolate boundary.
- `mapBounded(items, limit, action)` runs `action` over a collection with at
  most `limit` actions in flight, preserving input order. A fixed pool of worker
  futures pulls indices from a shared cursor; results are written back by index.

### Things to Know

- **Web yields with `Future.delayed(Duration.zero)`, not a microtask.**
  Microtasks (`await null` / `scheduleMicrotask`) run before the browser
  renders, so a microtask loop would still freeze the UI; only an event-loop
  yield lets a frame paint between chunks. Native uses a real isolate, so it has
  no such constraint.
- **`compute` is chosen over `dart:isolate` for web-compilability.** `compute`
  delegates to `Isolate.run` on native but stays compilable for web, so one
  shared helper file remains web-safe (the web branch never reaches the isolate
  path). A function sent to `compute` must be a top-level or static function.
- **`mapBounded` is for bounded network/server batches; unbounded `Future.wait`
  is for fast local ops.** The distinction is deliberate (ADR-0004): a
  caller/DB-driven batch could otherwise launch hundreds of simultaneous
  requests, while local file stat/delete is cheap enough not to need a cap.
  `limit` must be `>= 1`.
- **The two CRC paths must agree.** The chunked web path and the one-shot native
  path are required to produce byte-identical output; this holds only because
  `Crc32c` is boundary-independent. Changing the chunking must not change the
  result.

Created and maintained by Nori.
