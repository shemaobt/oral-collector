# Noridoc: Core Platform

Path: @/lib/core/platform

### Overview

- Platform abstraction layer: each capability that differs between native
  and web ships as a `*_native.dart` / `*_web.dart` pair behind a thin
  conditional-import facade (`disk_space.dart`, `file_ops.dart`,
  `ffmpeg_ops.dart`, `file_source.dart`, `web_file_picker.dart`), so feature
  code imports one symbol and the right implementation is linked per target.
- [./web_file_store.dart](web_file_store.dart) is durable IndexedDB-backed
  byte storage for the web build, used by `file_ops_web.dart` (ENG-421).
- Also hosts cross-feature process-state primitives that are not a
  native/web split: `recording_active_flag.dart` and
  [./foreground_service_arbiter.dart](foreground_service_arbiter.dart).
- Consumed broadly by the recording and sync features for file IO, disk
  reporting, FFmpeg, file import, and (Android) the shared foreground
  service.

### How it fits into the larger codebase

- The conditional-import facades are the only thing feature code should
  import; they re-export the native or web variant via Dart's
  `if (dart.library.html)` mechanism. Callers never reference the `_native`
  / `_web` files directly.
- `ForegroundServiceArbiter` is the single source of truth for who owns the
  one Android foreground service that the `flutter_foreground_task` plugin
  exposes. The plugin allows exactly one foreground service in the process,
  but two features want it: recording (declared service id `1002`, type
  `microphone`) and upload (service id `1003`, type `dataSync`). Both
  service types are declared on the single native `ForegroundService` in
  [/android/app/src/main/AndroidManifest.xml](../../../android/app/src/main/AndroidManifest.xml)
  (with `stopWithTask=true`).
- Two callers go through the arbiter:
  - [/lib/features/recording/data/services/recording_foreground_service.dart](../../features/recording/data/services/recording_foreground_service.dart)
    (owner `recording`).
  - [/lib/features/sync/data/services/upload_foreground_service.dart](../../features/sync/data/services/upload_foreground_service.dart)
    (owner `upload`).
- The arbiter does not import `flutter_foreground_task`. Both callers inject
  the plugin's `isRunningService` / `startService` / `stopService` as
  callbacks, which keeps the ownership logic unit-testable without the
  native singleton (see
  [/test/core/platform/foreground_service_arbiter_test.dart](../../../test/core/platform/foreground_service_arbiter_test.dart)).

### Core Implementation

- `file_source.dart` defines `FileSource`, the read-only handle the
  file-import and audio-probe paths use to read a candidate file without
  caring whether it is a native path, a `cross_file` `XFile`, or an in-memory
  buffer. Its core method is `readRange(start, end)`; `readHead(max)` is a
  thin wrapper. The whole point of the abstraction is **ranged reads**: the
  web variant (`file_source_web.dart`) implements `readRange` as
  `Blob.slice(start, end).arrayBuffer()`, and the native variant
  (`file_source_native.dart`) as a `RandomAccessFile` seek + read, so a caller
  can read the tail or an interior box of a multi-gigabyte file without
  loading it whole. The container-header parsers under
  [/lib/features/recording/data/services/audio_metadata/](../../features/recording/data/services/audio_metadata/)
  depend on this to probe arbitrarily large imports cheaply.
- `file_ops.dart` (facade over `file_ops_native.dart` / `file_ops_web.dart`)
  is the file-IO surface every feature imports for reading, writing, and
  probing recording audio: `fileExists`, `fileLength`, `readFileBytes`,
  `writeFileBytes`, `deleteFile`, `copyFile`, `readFileChunk`, plus
  `createDir`/`dirExists` and the `isAndroidPlatform`/`isIOSPlatform` flags.
  The native variant is a thin wrapper over `dart:io`'s `File`/`Directory`.
  The web variant (ENG-421) delegates to `WebFileStore`
  ([./web_file_store.dart](web_file_store.dart)), a small IndexedDB-backed
  key-value store (database `oral_collector_files`, object store `files`,
  separate from the Drift database — see
  [/lib/core/database/docs.md](../database/docs.md)) that keys bytes by the
  same path string the caller already uses as an id. `createDir`/`dirExists`
  are no-ops/`true` on web since there is no directory concept to model.
- `ffmpeg_ops.dart` (facade over `ffmpeg_ops_native.dart` /
  `ffmpeg_ops_web.dart`) exposes `compressToM4a(input, output)` — the WAV→M4A
  transcode the finalization and file-import paths run before deleting the
  source WAV. The native variant runs the ffmpeg command, then **verifies the
  output exists and is non-empty** (`file_ops.fileExists` + `fileLength > 0`)
  before returning `true`; a success return code alone is not trusted. The web
  variant throws `UnsupportedError`. A `runner` parameter (default = the real
  `executeFFmpegCommand`) is a test seam.
- `ForegroundServiceArbiter` is all static state: a single `_owner`
  (`none` / `recording` / `upload`) plus a `_queue` mutex.
- `takeOver(owner, isRunning, stop, start)` is the hand-off primitive: it
  stops whatever is currently running (awaiting until it actually stops),
  then starts the new service, then records the new owner. A recording that
  starts over an active upload therefore becomes a single deterministic
  stop-then-start instead of two independent objects racing
  `startService` / `stopService`.
- `release(owner, isRunning, stop)` stops the service only if `owner` still
  matches `_owner`; otherwise it is a no-op. This is what lets one feature's
  stop never tear down the other feature's notification after a hand-off.
- `isOwner(owner)` is the guard the callers use for `update` /
  `updateProgress` and for their own `isRunning` getters, so a feature only
  touches the notification while it owns the service.
- `_serialized` chains every `takeOver` / `release` onto `_queue` so they
  run one at a time and never interleave.

### Things to Know

- **`file_ops`'s web and native variants share a signature but not
  edge-case semantics for a missing path, and the divergence is
  deliberate (ENG-421).** Native's `readFileBytes` and `fileLength` throw
  `dart:io`'s `PathNotFoundException` for a path that never existed (only
  `fileExists` answers `false`). Web's `readFileBytes` returns
  `Uint8List(0)`, `fileLength`
  returns `0`, and `fileExists` returns `false` for the same case — an empty
  file and a missing file are only distinguishable via `fileExists`, never
  via `readFileBytes` alone. This was preserved on purpose when
  `file_ops_web.dart` was rewritten onto `WebFileStore`: callers like
  [/lib/features/recording/presentation/widgets/confirmation_step.dart](../../features/recording/presentation/widgets/confirmation_step.dart)
  branch on `bytes.isEmpty` for both the player load and the save path, so
  making the web variant throw would break that production caller.
  `readFileChunk` on web truncates at the end of the stored bytes instead of
  throwing `RangeError` for an offset/length past the end, matching how a
  native `RandomAccessFile.read` past EOF behaves.
- **`WebFileStore`'s `IdbFactory` is the only test seam for the web file
  path.** Production wires `idbFactoryNative` from `idb_shim`, which throws
  where IndexedDB is unavailable (private browsing, storage blocked by
  policy) rather than silently falling back to memory —
  `idbFactoryBrowser` was deliberately not used because a silent in-memory
  fallback recreates the exact defect ENG-421 fixed: audio that looks saved
  and disappears on reload. Tests inject `idb_shim`'s
  `newIdbFactoryMemory()`, a complete implementation of the same API that
  runs on the plain Dart VM, so
  [/test/core/platform/web_file_store_test.dart](../../../test/core/platform/web_file_store_test.dart)
  exercises the real storage logic without a browser. This is also why
  [/test/core/platform/file_ops_native_test.dart](../../../test/core/platform/file_ops_native_test.dart)
  is named for native only — `flutter test` runs on the Dart VM, so
  `file_ops.dart`'s conditional export always resolves to
  `file_ops_native.dart` there; a web-named test in that file would have
  been exercising the wrong implementation. There is no browser test
  infrastructure in this project's CI
  ([/.github/workflows/test.yml](../../../.github/workflows/test.yml) runs
  `flutter test` without `--platform chrome`), so the VM-backed in-memory
  IndexedDB proves the storage logic, not the real browser IndexedDB or the
  compiled js_interop glue — `flutter build web` is the only automated gate
  on that.
- **`FileSource.readRange` is a true ranged read, not a slice of a
  preloaded buffer** (except for the in-memory variant, which already holds
  the bytes). Web goes through `Blob.slice`, native through a seeked
  `RandomAccessFile`. All variants guard `end <= start` to an empty result;
  reads past EOF return fewer bytes (`Blob.slice`/`RandomAccessFile` truncate;
  the in-memory variant clamps), so a parser reading near EOF cannot overrun.
  Callers
  rely on this to read a file's tail (e.g. an MP4 `moov` or an Ogg last page)
  without paying for the whole file — see
  [/lib/features/recording/data/docs.md](../../features/recording/data/docs.md).
- **Serialization closes a TOCTOU window.** `release` re-checks ownership
  and then awaits `isRunning` / `stop`. If a hand-off could run during those
  awaits, a stale release could stop the service the hand-off just claimed.
  The `_queue` mutex forces a release queued during a take-over to run
  strictly after it, so it sees the new owner and no-ops. The gated test in
  [/test/core/platform/foreground_service_arbiter_test.dart](../../../test/core/platform/foreground_service_arbiter_test.dart)
  pins this ordering.
- **`_owner` is process-global static state.** It mirrors the single native
  service, so there is intentionally one arbiter for the whole app, not one
  per Riverpod scope. `resetForTest` clears `_owner` and `_queue` between
  tests.
- **`compressToM4a == true` is a license to delete the source (ENG-140
  F18).** Both callers treat a `true` return as proof a real m4a landed and
  then delete the source WAV:
  [/lib/features/recording/data/services/recording_finalization_service.dart](../../features/recording/data/services/recording_finalization_service.dart)
  deletes the intermediate `sourcePath`, and
  [/lib/features/recording/presentation/file_import_screen.dart](../../features/recording/presentation/file_import_screen.dart)
  deletes the copied `destPath`. ffmpeg can exit 0 with a missing or empty
  output (release-mode / permission edge cases), which previously caused
  permanent audio loss. The post-run `fileExists` + `fileLength > 0` check
  makes the contract `compressToM4a == true` ⇒ a non-empty m4a exists on disk.
  This mirrors the identical guard in
  [/lib/features/recording/data/services/recording_concat_service.dart](../../features/recording/data/services/recording_concat_service.dart),
  which already verified its concat output before returning a path.
- **The arbiter only tracks ownership; the plugin tracks liveness.** Callers
  pass `FlutterForegroundTask.isRunningService` as `isRunning`, so the
  arbiter never assumes the service is up just because it recorded an owner
  — a swipe-away (`stopWithTask`) that kills the service out from under the
  arbiter is reconciled on the next `takeOver`.

Created and maintained by Nori.
