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
  loading it whole. Alongside `filePath` (a native filesystem path, null
  everywhere else) it carries `storageKey` (ENG-427): the durable address the
  bytes can be read back from after a reload, which on web means a
  `WebFileStore` key. Only the in-memory variant can answer it, and only when
  the caller that built it knew the key — `ConfirmationStep._saveWebDirect`
  passes the key it just read the bytes from. Every other variant answers
  null, including the browser `File` a picker hands over, whose bytes die with
  the page. `storageKey` is deliberately not `name`: `name` is a label to show,
  so hanging a storage contract on it would let a cosmetic rename break a
  resume in silence. The container-header parsers under
  [/lib/features/recording/data/services/audio_metadata/](../../features/recording/data/services/audio_metadata/)
  depend on this to probe arbitrarily large imports cheaply.
- `file_ops.dart` (facade over `file_ops_native.dart` / `file_ops_web.dart`)
  is the file-IO surface every feature imports for reading, writing, and
  probing recording audio: `fileExists`, `fileLength`, `readFileBytes`,
  `writeFileBytes`, `deleteFile`, `copyFile`, `readFileChunk`, plus
  `createDir`/`dirExists` and the `isAndroidPlatform`/`isIOSPlatform` flags.
  `listStoredKeys` is the one entry that is not symmetric: it enumerates the
  whole store and only the web variant can answer it, because only there is
  every file in one flat keyspace. The native variant throws
  `UnsupportedError` rather than returning an empty list — native audio is
  spread over directories a caller lists individually, so an empty list would
  be a false answer rather than a degenerate one. This is the same shape
  `web_file_picker_native.dart` uses for a capability only one target has, and
  it keeps `file_ops.dart` compiling for both targets while the single caller
  (the startup sweep, below) stays inside a `kIsWeb` branch. It returns keys
  and nothing else, deliberately: neither IndexedDB nor `idb_shim` can report a
  record's size without reading the whole value, so a listing that carried
  sizes would have to materialize every audio blob to answer. If sizes are ever
  needed, the way there is writing the size as metadata at write time.
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
- **Abandoned web bytes are collected at startup, not by a handle (ENG-426).**
  On web the `LocalRecordings` row is written only *after* the upload succeeds,
  so two paths leave bytes in `oral_collector_files` with no handle: someone
  records, reaches the confirmation step and reloads before saving; or the
  upload fails and they close the tab. These orphans are not purely a defect —
  they are the side effect of the very thing this storage exists to guarantee,
  that the audio outlives a reload. The two paths that *do* have a handle are
  cleaned directly: `ConfirmationStep` deletes after a successful upload and on
  discard, and the export temp key is deleted after the share. Everything else
  is collected by `sweepOrphanWebAudio`
  ([/lib/features/recording/data/services/web_audio_sweeper.dart](../../features/recording/data/services/web_audio_sweeper.dart)),
  which runs unawaited in the web branch of startup in
  [/lib/main.dart](../../main.dart) — the browser's counterpart to
  `RecordingTrash.pruneOldTrash` on device. It enumerates the store through
  `listStoredKeys`, keeps only keys carrying the recorder's `web_record_`
  prefix, reads each recording's start instant out of the key itself, and
  deletes the ones older than 24 hours, skipping any key a pending upload can
  still resume from. No metadata and no schema was added for this: the key
  already carries the timestamp. The surface that offers a recording *back* to
  the person before the cutoff collects it is the resume banner, which since
  ENG-427 reads the bytes out of storage and finishes the upload without asking
  for anything (see
  [/lib/features/recording/presentation/widgets/docs.md](../../features/recording/presentation/widgets/docs.md)).
  It offers only what an interrupted *upload* left behind, though: audio
  abandoned on the confirmation form has no row pointing at it, so the sweep is
  still the only thing that ever touches those bytes.
- **"Never collect what a pending upload needs" used to be true for free; now
  it is enforced (ENG-427).** Until the resumable path recorded where its bytes
  were, the promise held vacuously: an interrupted web upload's shadow row
  carried a `web_import_<millis>_<serverId>` name that addressed nothing, so no
  stored bytes were reachable from it and resuming meant asking the person for
  the file again. Now the row carries the real storage key, so the sweep takes
  a third dependency — `keysInUse`, wired in [/lib/main.dart](../../main.dart)
  to `LocalRecordingRepository.getPendingWebUploadKeys` — and skips every key
  it names. The set is built **once per sweep**, not queried per key, and it is
  matched key for key: sparing the whole store because *some* upload is pending
  would leave the sweep running and collecting nothing, which is the failure
  mode that looks identical to working. Two tests hold the two edges apart in
  [/test/features/recording/data/services/web_upload_resume_test.dart](../../../test/features/recording/data/services/web_upload_resume_test.dart)
  — one where the pending row points at the swept key, one where a pending row
  exists but points somewhere else and the abandoned bytes must still go. A key
  in use that no longer exists in storage is not an error and does not stop the
  sweep; the set is only ever consulted, never dereferenced.
- **A live session is the second source of "in use" (ENG-519, slice 1).**
  Browser capture now opens a session row before recording and anchors it to
  the storage key when it stops, so those bytes stop being abandoned the
  moment they are written — and a sweep that did not know it would collect
  them 24 hours later, taking with it the recording the row had just
  registered. `keysInUse` in [/lib/main.dart](../../main.dart) is therefore the
  union of two queries, one scan each:
  `LocalRecordingRepository.getPendingWebUploadKeys` and
  `RecordingSessionRepository.getLiveAudioAnchors`
  ([/lib/features/recording/data/repositories/docs.md](../../features/recording/data/repositories/docs.md)).
  The same "key for key, never the whole store" rule applies, and the pair of
  tests in
  [/test/features/recording/data/services/sweeper_spares_live_session_test.dart](../../../test/features/recording/data/services/sweeper_spares_live_session_test.dart)
  holds the edges apart: one where a live session's audio must survive, one
  where abandoned bytes must still go *while other live sessions exist*. A
  session that reaches `discarded` drops out of the set and its audio becomes
  collectable again. A session with no anchor — still recording, or a tab
  closed mid-recording — names no key at all, so it can neither protect bytes
  nor switch the sweep off; the browser writes to storage only at stop, so
  that session has no bytes in the store either.
- **The 24-hour cutoff is also what makes the sweep safe with two tabs open.**
  A recording in progress, or one sitting on the confirmation form, is minutes
  old and never in range, so the sweeper needs no Web Locks and no
  `BroadcastChannel` to avoid collecting audio another tab is still writing.
  The cost of that choice is the far edge: someone who leaves a tab parked on
  the confirmation form for more than a day loses those bytes from under them.
  That is a deliberate trade (before ENG-421 the bytes died with the tab
  anyway), not an oversight. A key that carries the prefix but whose timestamp
  cannot be parsed is left alone rather than collected on suspicion, and a
  timestamp in the future — a clock that moved back — is not older than the
  cutoff either, so it stays. The whole sweep is wrapped in one catch: browser
  storage can refuse to enumerate or to delete (quota, private browsing, a
  database blocked by another tab), and housekeeping must never be the reason
  for a blank first screen. Note that the sweeper's agreement with the recorder
  on the key format is held by exactly one test — the one that drives the real
  capture path and sweeps the key it produced. The three tests around it spell
  keys out by hand and would stay green through a rename.
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
  exercises the real storage logic without a browser — the same factory backs
  the sweeper's tests, so what they observe is the real store's answer, not a
  stand-in's. This is also why
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
