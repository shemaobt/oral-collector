# Noridoc: Recording Data

Path: @/lib/features/recording/data

### Overview

- Data layer for the `recording` feature: Riverpod wiring, server-to-local
  mapping, the cache-hydration / heal helpers, and the repositories &
  services subfolders.
- Owns the contract that every recording-level metadata field on an
  in-memory `LocalRecording` must reach the persisted Drift row. The split
  path, the trim path, and the "download for edit" path all funnel through
  helpers in this folder so they cannot silently drop columns.
- Provides typed entry points consumed by the recording presentation layer
  and by the sync feature: `localRecordingRepositoryProvider`,
  `recordingApiRepositoryProvider`, `recordingSessionRepositoryProvider`,
  `resumableUploadServiceProvider`, `directRecordingUploaderProvider`, and
  `localRecordingStreamProvider`.

### How it fits into the larger codebase

- The `LocalRecordings` Drift table lives in
  [/lib/core/database/app_database.dart](../../../core/database/app_database.dart);
  the generated Dart class `LocalRecording` and its `LocalRecordingsCompanion`
  are imported from there. `toCompanion(false)` is the canonical way to
  serialize an in-memory `LocalRecording` to a Drift insert/update payload —
  it covers every column in the schema, including ones added later. Adding a
  column is a schema migration: follow the snapshot + step-through
  migration-test workflow in
  [/lib/core/database/docs.md](../../../core/database/docs.md), which guards the
  upgrade path that carries un-uploaded recordings forward.
- Consumed by the recording presentation layer:
  [/lib/features/recording/presentation/recording_detail_screen.dart](../presentation/recording_detail_screen.dart),
  [/lib/features/recording/presentation/trim_editor_screen.dart](../presentation/trim_editor_screen.dart),
  [/lib/features/recording/presentation/recordings_list_screen.dart](../presentation/recordings_list_screen.dart),
  and notifiers under
  [/lib/features/recording/presentation/notifiers/](../presentation/notifiers/).
- The sync feature
  ([/lib/features/sync/](../../sync/)) reads
  `localRecordingRepositoryProvider` to enumerate pending uploads
  (`getPendingUploads`, `getPendingWebUploads`) and to mark rows as
  `uploading` / `uploaded` / `failed`. Those two queries also define the
  **order the upload queue is drained in** (`createdAt ASC, id ASC`, FIFO by
  enqueue time); the sync engine consumes the list in that order (applying its
  own eligibility filter, which skips `uploading` rows), so the ordering is a
  contract this folder owns on sync's behalf — see
  [./repositories/docs.md](repositories/docs.md). The startup crash-recovery
  reclaim of rows orphaned in `uploading` (`resetStuckUploading`, called from
  [/lib/main.dart](../../../main.dart)) also lives on this repository — see
  [./repositories/docs.md](repositories/docs.md). The resumable upload service is
  exported from this folder via `resumableUploadServiceProvider` but its
  implementation lives in
  [/lib/features/sync/data/services/resumable_upload_service.dart](../../sync/data/services/resumable_upload_service.dart).
- The server API contract — the `ServerRecording` DTO — lives in
  [/lib/features/recording/domain/entities/server_recording.dart](../domain/entities/server_recording.dart).
  `serverRecordingToLocal` and `buildHealMetadataCompanion` are the two
  legitimate places to translate server data into a local row or update.
- The cross-implementation invariants for split and cache hydration are
  documented in [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).
  That doc is the source of truth shared with the backend (`tripod-api`).
- Diagnostics from these services now flow through the app's logging facade
  (named `package:logging` loggers), not ad-hoc console prints; severe records
  reach the `ErrorReporter`. See
  [/lib/core/observability/docs.md](../../../core/observability/docs.md). This is
  distinct from the explicit best-effort `ErrorReporter` reports called out in
  Things to Know (finalization temp deletes, the foreground/Live-Activity tick).

### Core Implementation

- `providers.dart` registers all data-layer providers and stays free of
  business logic. `localRecordingStreamProvider` is a family stream keyed
  by recording id; as of ENG-199/ENG-200 it is a
  `StreamProvider.family<LocalRecordingEntity?, String>` backed by
  `LocalRecordingRepository.watchRecordingEntityById` (the former row stream
  `watchRecordingById` was deleted with the detail tree's row→entity migration).
  `metadataOutboxProvider` (ENG-405) is the second stream here: a
  non-family `StreamProvider<Map<String, MetadataOutboxEntry>>` over
  `LocalRecordingRepository.watchMetadataOutbox`, carrying every recording that
  still owes the server a metadata write, keyed by **both** the local id and
  the server id so a caller can look one up whichever it holds. One stream for
  the whole list rather than one per card — the answer is almost always an
  empty map, and a subscription per row would pay a Drift query each. The entry
  is a record of two `String`s (`status`, `fieldsJson`) rather than a decoded
  `Set`, because a `Set` inside a record compares by identity and the stream
  dedups on `==`; `watchMetadataOutbox` needs that dedup, since a Drift `watch`
  over `localRecordings` re-runs on every unrelated write to the table, an
  upload's byte counter included. `RecordingsListNotifier` is its consumer
  ([../presentation/docs.md](../presentation/docs.md)).
  `RecordingDetailNotifier`
  ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md))
  listens to it (native only, ENG-194) so any write through
  `LocalRecordingRepository` flows back into the detail UI — and because the
  entity drops `lastRetryAt`/`md5Hash`, an upload-bookkeeping-only write no
  longer re-emits (see Things to Know). It also exposes
  `fileExistsProvider` — a one-line wrapper over `file_ops.fileExists` —
  injected so the trim editor's load-path file check is driveable in
  widget tests (a real `dart:io` future never resolves under the
  fake-async test zone). See "the trim editor's injectable seams" below.
- `server_to_local_recording.dart` exposes `serverRecordingToLocal(server)`,
  the single mapper from `ServerRecording` to `LocalRecording`. It exists
  precisely so callers like the detail screen and the trim editor cannot
  silently diverge on which fields they carry — divergence is the ENG-64
  root cause. As of ENG-374 it also carries `reviewFlags`, JSON-encoding the
  list into the `reviewFlagsJson` column via `encodeReviewFlags`
  ([../domain/entities/review_flag.dart](../domain/entities/review_flag.dart)).
  As of ENG-403 it also sets the four metadata-outbox columns to their
  synced defaults (`metadataSyncStatus: 'synced'`, `pendingMetadataJson:
  '[]'`, `metadataRetryCount: 0`) — a recording projected straight from the
  server owes it nothing, by construction; this mapper never reads or writes
  a pre-existing local row, so any real pendency stays wherever that row
  already is.
- `local_recording_to_entity.dart` exposes `localRecordingToEntity(row)`, the
  single mapper from the Drift `LocalRecording` row to the domain
  `LocalRecordingEntity`
  ([../domain/entities/local_recording_entity.dart](../domain/entities/local_recording_entity.dart)),
  deliberately dropping the persistence internals `lastRetryAt`/`md5Hash`. As
  of ENG-374 it decodes `row.reviewFlagsJson` back into `List<ReviewFlag>` via
  `decodeReviewFlags`, which reads an empty or invalid string as no flags
  rather than throwing — a row from a build older than the column, or one
  whose text is somehow no longer valid JSON, must not take the whole
  recording down with it. It is
  the one source of truth for the row→entity projection (ENG-195): the
  repository's `_fromRow` (the entity watch stream, see
  [./repositories/docs.md](repositories/docs.md)), the recordings-list notifier,
  and `RecordingDetailNotifier.load` (which resolves a row internally for the
  heal path, then maps once at the state boundary, ENG-199/ENG-200) all delegate
  to it, so the watch stream, the list, and the detail screen cannot carry
  different fields (see
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)). The
  server side composes the two — `localRecordingToEntity(serverRecordingToLocal(s))`
  — to land server data as the same entity type the local side produces. The
  entity it produces also feeds *write* paths now: the split path as a read-only
  parent input (ENG-198 — `splitRecordingReplacingParent({parent})` and the trim
  editor's split/save chain take a `LocalRecordingEntity`) and the detail
  cache-download write `cacheDownloadedAudio` (ENG-199/ENG-200, see
  [./repositories/docs.md](repositories/docs.md)) — so the projection is no
  longer used only by the read/watch streams.
- `server_to_recording_entity.dart` exposes `serverRecordingToEntity(server)`,
  the one-line composition `localRecordingToEntity(serverRecordingToLocal(s))`
  promoted to a named mapper (ENG-202). It lands a `ServerRecording` straight as
  the domain `LocalRecordingEntity` for the server-only load case, so the
  server→entity projection cannot drift from the two row mappers it composes. The
  trim editor's load path
  ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)) uses it
  for recordings that exist only on the server (web load, plus the native
  server-fetch fallback).
- `local_recording_entity_to_companion.dart` exposes
  `localRecordingEntityToCompanion(entity)`, the write-path inverse of
  `localRecordingToEntity` added by ENG-201 (the F4b step of the row→entity
  migration). It projects a freshly captured entity onto the **insert/save**
  `LocalRecordingsCompanion` and backs `LocalRecordingRepository.saveRecording`
  (see [./repositories/docs.md](repositories/docs.md)). It is scoped to a fresh
  save, not a full entity serializer: it drops empty optional metadata to NULL,
  and **deliberately omits** `createdAt`/`retryCount`/`uploadedBytes`/
  `cleaningStatus` so the Drift column defaults apply on insert (protecting the
  DB-assigned `createdAt` from an app-side value — see Things to Know there). The
  split write path keeps building child companions by hand because each child
  mixes inherited / segment-specific / reset fields (the propagation table in
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md)),
  so this mapper is not used there.
- `recording_heal_companion.dart` exposes the pure function
  `buildHealMetadataCompanion(local, server)`. It is used in the detail
  screen's online-refresh path to repair rows already corrupted on a device
  before the cache-hydration fix landed. Detection uses `userId IS NULL` on
  the local row as the corruption marker — the pre-fix bug omitted userId
  along with the other user-content fields, so any local row missing userId
  paired with a server row that has one is treated as corrupted and gets
  every user-content field (`description`, `storytellerId`, `userId`,
  `secondaryGenreId`, `secondarySubcategoryId`, `secondaryRegisterId`)
  rehydrated from the server. When userId is already populated locally, no
  user-content field is touched — an intentional clear (`description=''` or
  `storytellerId=null`) survives a refresh. Server-controlled fields
  (`gcsUrl`, `uploadStatus`) are adopted whenever the server reports a
  `gcsUrl`, independent of the corruption marker.
- `supported_audio_formats.dart` is a static list of mime types and file
  extensions used by the file-import flow, plus `kMaxImportFileBytesWeb` (the
  10 GB web import ceiling enforced in
  [../presentation/file_import_screen.dart](../presentation/file_import_screen.dart)).
- The `repositories/` subfolder hosts `LocalRecordingRepository`,
  `RecordingApiRepositoryImpl`, and `RecordingSessionRepository`. See
  [./repositories/docs.md](repositories/docs.md).
- `services/direct_recording_uploader.dart` (`DirectRecordingUploader`) is
  the web file-import upload path: it creates the server metadata, then
  branches on a 5 MB threshold. Files under the threshold PUT in a single
  shot with **no Drift row**. Files at or above it go resumable via
  `ResumableUploadService.uploadFromSource`, and for the duration of that
  upload a `web_<serverId>` shadow row (`uploadStatus='web_uploading'`)
  exists in Drift to carry resume state; it is deleted on success and left
  in place on failure for the resume banner. That shadow row is written with
  `LocalRecordingRepository.upsertRecording` (not `insertRecording`) so a
  retry of a failed large import reuses the row instead of colliding on its
  primary key — see ENG-80 in Things to Know. The single-shot path computes its
  client-side CRC32C **off the UI isolate** via the shared helper in
  [/lib/core/util/docs.md](../../../core/util/docs.md) (background isolate on
  native, cooperative chunked yield on web; see ADR-0004), then validates
  the server's presigned `upload_url` with `isHttpsUrl`
  ([/lib/core/config/url_policy.dart](../../../core/config/url_policy.dart))
  before the GCS PUT; a non-https URL throws `_UploaderException`. The
  resumable branch delegates that validation to `ResumableUploadService`.
  **Failure classification (ENG-354).** Every call this uploader makes to
  *our own* API — create, upload-url, confirm-upload — routes a non-success
  status through `throwForResponse`
  ([/lib/core/network/error_boundary.dart](../../../core/network/error_boundary.dart)),
  the same status table `SyncEngine` gets for free via `decodeObject`. So a
  4xx the server will keep rejecting (409 dedupe, 422 missing description)
  surfaces as a typed non-retryable `AppException`, and a 5xx surfaces as a
  retryable `ServerException`. Callers branch on `AppException.retryable`
  (ENG-103), never on the exception subtype, so a create the backend refuses
  ends the attempt instead of being requeued as a transient fault. The
  private `_UploaderException` remains only for failures that are *not* an
  API status: the GCS PUT, a CRC32C mismatch, a non-https upload URL, and a
  failed resumable transfer — all genuinely transient, all correctly retried.
  **A 409 is only a taken title when it comes from the create call.** The
  backend deduplicates `POST /api/oc/recordings` on `(project_id, title)`, so
  that one 409 is a name clash the user can resolve by renaming; it is tagged
  inline at that call site with `code: kDuplicateRecordingTitleCode` and read
  back through the top-level predicate `isDuplicateRecordingTitle`. A 409 from
  upload-url or confirm-upload means something else entirely (typically
  "already confirmed") — the bytes are already in GCS and the recording is
  already registered, so offering a rename would advertise an exit that leads
  nowhere. Those fall through to the generic non-retryable handling as a plain
  `ConflictException`. This is the same discrimination `SyncEngine` makes at
  the same call site, and for the same reason
  ([/lib/features/sync/docs.md](../../sync/docs.md)); routing all three calls
  through `throwForResponse` briefly erased it, because it made every 409 a
  `ConflictException` and `ConfirmationStep._saveWebDirect` caught that type
  around the whole upload. Callers must use the predicate, never
  `on ConflictException`.
  The scheme policy and
  the app-wide no-cleartext-PUT invariant are documented in
  [/lib/core/network/docs.md](../../../core/network/docs.md).
- The `services/` subfolder hosts the audio probe, the
  segmented recorder, the foreground task, recovery & trash services, the
  resumable / direct uploaders, the audio path resolver used by the
  detail-screen player, and `RecordingSplitPersister` — the post-FFmpeg
  pipeline of a trim/split save. It is the one place that wires the "split is
  saved → children start uploading" causation, so the trim editor never has to
  think about sync. The pipeline is ordered for crash safety (ENG-125): it
  **atomically** inserts the children and deletes the parent row via
  `LocalRecordingRepository.splitRecordingReplacingParent` (one Drift
  transaction), then **archives the parent's audio** (`trashParent`, a file
  move that can't be rolled back — running it after the commit means a split
  failure never strands a trashed file), then runs the best-effort remote
  delete and `triggerUpload()` **outside** the transaction. See Things to Know
  and [./repositories/docs.md](repositories/docs.md).
- `services/recording_boost_persister.dart` (`RecordingBoostPersister`) is the
  sibling pipeline for a trim-editor save with **no cut points** — a gain-only
  edit (ENG-402). It is a deliberately separate class, not a mode inside
  `RecordingSplitPersister`: a boost keeps the recording's identity (same
  local id, same `serverId`), so it points the row at the re-encoded audio and
  queues a resend via `LocalRecordingRepository.replaceAudioAndQueueResend`
  ([./repositories/docs.md](repositories/docs.md)), archives the file it
  replaced (`trashPrevious`, run after the write commits, same rollback
  reasoning as `trashParent` below), then kicks the upload queue. It holds no
  `RecordingApiRepository` — unlike the split persister, it has nothing to
  retire on the server, which is the fix: a `boostOnly` save that went through
  the split persister deleted the local row and best-effort deleted the
  server's copy, and that remote delete swallows its failure and fails every
  time offline, so the server ended up holding both recordings. See
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md#what-counts-as-a-split)
  for the full boost-vs-split contract.
- **The trim editor's injectable seams (ENG-193).** The trim editor's
  editing + split orchestration moved into `TrimEditorNotifier` (see
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)),
  and the device-bound IO the notifier drives was extracted into three
  seams here so the orchestration is host-testable and the widget is
  driveable in widget tests:
  - `services/local_segment_exporter.dart` (`LocalSegmentExporter`
    typedef + `localSegmentExporterProvider`) wraps the per-segment
    ffmpeg loop. For each kept segment it runs one of three command
    variants — boost-only (re-encode the whole file with a volume
    filter), trim+gain (seek/trim + volume, re-encode to aac), or a
    plain `-c copy` stream trim — then reads the output file length and
    returns `List<SplitSegmentSpec>`. Which variant a plain trim (no gain
    change) gets is decided **per segment**, not once for the whole call
    (ENG-66): `segmentNeedsReencode` re-encodes instead of stream-copying
    when the segment is shorter than `_minStreamCopySeconds` (1 s), because
    `-c copy` on an AAC/m4a container can only cut on a frame boundary and
    still carries the encoder's priming samples. This app records at 16 kHz
    mono, where those are 64 ms and 132 ms respectively — roughly 200 ms of
    fixed error on every stream copy, which dominates a sub-second segment and
    can leave the output empty or badly offset. That threshold is four times
    the trim editor's own floor, `kMinTrimSegment`
    ([../../presentation/trim_edit_decision.dart](../../presentation/trim_edit_decision.dart),
    see [../../presentation/docs.md](../../presentation/docs.md)), not a
    measured failure point — before ENG-66 lowered that floor, a segment
    this short could not be created, so the stream-copy path never needed to
    branch. The exporter itself does not branch on
    `boostOnly` vs a real split — that decision is the caller's, in
    `TrimEditorNotifier._saveLocally`
    ([../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)),
    which sends the single resulting spec to `RecordingBoostPersister` when
    there were no cut points and to `RecordingSplitPersister` otherwise
    (ENG-402).
    Its per-call data inputs (source path, the `SegmentExportSpec`s, gain,
    boost-only flag, original title, parent genre id) are grouped into a
    single `ExportLocalSegmentsRequest` value object passed as the lone
    positional argument — the same params-object pattern as
    `UpdateRecordingRequest`/`SplitSegmentRequest`
    ([../domain/docs.md](../domain/docs.md)), adopted to keep the function's
    parameter count under the `dart_code_linter` `number-of-parameters` gate
    (ENG-209; the threshold ratchet itself is ENG-208). The four injectable
    IO seams — the ffmpeg runner, file-length, clock, and documents-dir —
    deliberately stay as named parameters (they are test seams, not caller
    data) so it still runs without a device. It is kept free of a direct
    `dart:io` import so the web bundle still compiles, even though the
    native save path is its only runtime caller.
  - `services/waveform_loader.dart` (`WaveformLoader` typedef +
    `waveformLoaderProvider`) wraps `WaveformExtractor.extractPeaks`. The
    widget calls it during load so the ffmpeg-backed peak extraction can
    be faked in widget tests (which cannot run ffmpeg); an empty result
    lets the caller fall back to a synthetic waveform.
  - `services/recording_split_persister.dart` additionally exposes a
    `RecordingSplitPersisterFactory` typedef + `recordingSplitPersisterProvider`
    so the notifier hands off to a fake persister in tests. The persister
    pipeline itself is unchanged — only the factory seam is new.
    `services/recording_boost_persister.dart` mirrors this exactly:
    `RecordingBoostPersisterFactory` typedef + `recordingBoostPersisterProvider`
    (ENG-402), used the same way for the boost-only save path.
- **The detail screen's injectable IO seams (ENG-194).** The detail screen's
  orchestration moved into `RecordingDetailNotifier` (see
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)), and
  the device-bound IO it used to do inline was extracted into two seams here so
  the notifier is host-testable. Both mirror the trim-editor seam style
  (function-typedef + `Provider` returning the default impl) and stay free of a
  direct `dart:io` import so the web bundle still compiles — all filesystem
  access goes through the `file_ops` facade
  ([/lib/core/platform/file_ops.dart](../../../core/platform/file_ops.dart)):
  - `services/audio_downloader.dart` exposes two function-typedef providers —
    `audioCacheDownloaderProvider` (`AudioCacheDownloader`) and
    `audioExportDownloaderProvider` (`AudioExportDownloader`). Each wraps the
    package-global `http.get` the screen used to call inline (which cannot be
    intercepted in a unit test) plus the `file_ops` write: the cache downloader
    fetches the GCS audio and writes it under the app documents dir (for
    `cacheDownloadedAudio`); the export downloader fetches to a temp file for
    sharing. Both throw on a non-200 response.
  - `services/recording_file_importer.dart` exposes
    `recordingFileImporterProvider` (`RecordingFileImporter`). It copies a
    picked file into the docs `recordings/` dir and returns `(path, sizeBytes)`;
    when an `oldPath` is supplied it also trashes the previous file via
    `RecordingTrash` (`services/recording_trash.dart`) and invalidates its
    waveform cache via `WaveformExtractor.invalidate`
    (`services/waveform_extractor.dart`). It backs the notifier's `replaceAudio`.
- `services/web_audio_sweeper.dart` exposes `sweepOrphanWebAudio`, the
  browser's counterpart to `RecordingTrash.pruneOldTrash` — same 24-hour
  window, same unawaited call from the startup microtask in
  [/lib/main.dart](../../../main.dart), opposite side of its `kIsWeb` branch
  (ENG-426). It exists because on web the audio is written to browser storage
  when capture stops while the `LocalRecordings` row is only written after a
  successful upload, so a reload on the confirmation step, a closed tab, or a
  failed upload leaves bytes nothing will ever ask for again. It takes the
  store's enumerate and delete as parameters (`file_ops.listStoredKeys` and
  `file_ops.deleteFile` in production) rather than importing the web facade, so
  it compiles on native and can be driven against a real in-memory IndexedDB in
  a VM test. **The key format is a contract it shares with the recorder**: the
  sweeper reads a recording's start instant out of the `web_record_<millis>`
  key that `_startWeb` in
  [../presentation/notifiers/recording_session_notifier.dart](../presentation/notifiers/recording_session_notifier.dart)
  builds, and nothing but a test holds the two ends together — see
  [/lib/core/platform/docs.md](../../../core/platform/docs.md) for the cutoff's
  consequences and for why keys it cannot parse are left alone.
- `services/audio_path_resolver.dart` exposes the pure async
  `resolveRecordingPath(storedPath)`. It returns the first existing path
  among: the stored path itself, the application documents directory
  with the same basename, and a `recordings/` subdirectory of the docs
  dir. The detail-screen's playback notifier
  ([../presentation/notifiers/recording_player_notifier.dart](../presentation/notifiers/recording_player_notifier.dart))
  consumes it through `audioPathResolverProvider` and falls back to
  `gcsUrl` when resolution returns `null`. On `kIsWeb` it short-circuits
  to `null` because the playback notifier always uses URLs on web.
- `services/audio_probe.dart` exposes `AudioProbe`, the duration + codec +
  playability detector the file-import flow
  ([../presentation/file_import_screen.dart](../presentation/file_import_screen.dart))
  runs on every candidate before accepting it. `probeFromSource` is a
  two-stage pipeline: a cheap **header probe** that reads only container
  metadata, then a **player fallback** that instantiates a real platform
  decoder. The header probe wins (returns early, no player) only when it
  yields a positive duration AND a browser-playable codec; otherwise the
  player result is merged in (`_merge` prefers the player's duration and the
  header's codec). The platform halves live in `audio_probe_native.dart` /
  `audio_probe_web.dart`, selected by conditional import; the web player
  reads only the first 5 MB of the file before handing it to an HTML5
  `<audio>` element via `just_audio`.

  ```
  probeFromSource(extension)
    ├─ wav  → _probeWavHeader (RIFF/fmt /data, in-process bytes)
    ├─ m4a  → audio_metadata/mp4_box_probe.probeMp4Duration
    ├─ mp3  → audio_metadata/mp3_frame_probe.probeMp3Duration
    ├─ ogg  → audio_metadata/ogg_page_probe.probeOggDuration
    └─ (header has duration + playable codec?)
         yes → return header result      (no decoder spun up)
         no  → probeWithPlayer*FromSource → _merge(header, player)
  ```
- `services/audio_metadata/` holds the container-header parsers used by the
  header-probe stage. Each reads duration and codec straight from the file's
  structure using ranged reads
  ([/lib/core/platform/file_source.dart](../../../core/platform/file_source.dart),
  `readRange` = `Blob.slice` on web, `RandomAccessFile` seek on native), so a
  multi-gigabyte file is probed without ever being loaded whole.
  `mp4_box_probe.dart` walks ISO-BMFF top-level boxes to locate `moov` (front
  OR end of file), reading duration from `mvhd`/`mdhd` and codec from `stsd`;
  `mp3_frame_probe.dart` skips ID3v2 and reads the first frame header plus
  Xing/Info or size÷bitrate; `ogg_page_probe.dart` reads codec/sample-rate
  from the first page and total samples from the last page's
  `granule_position` in the tail. `AudioProbeResult` lives in
  `services/audio_probe_result.dart` (re-exported from `audio_probe.dart`) so
  these parsers and `AudioProbe` can share the type without an import cycle.
- `RecordingForegroundService` (in `services/`) keeps the Android process
  alive while recording. It does not own the foreground service outright:
  recording and upload share the single foreground service the
  `flutter_foreground_task` plugin exposes, arbitrated by
  [/lib/core/platform/foreground_service_arbiter.dart](../../../core/platform/foreground_service_arbiter.dart)
  (recording is owner `recording`, upload is owner `upload`). `start` is a
  `takeOver` — it stops an active upload's service and switches the
  notification to recording; `stop` is an owner-aware `release` that no-ops
  if upload has since taken over. It re-runs `FlutterForegroundTask.init`
  before each start because the recording (`recording_foreground`) and
  upload (`upload_foreground`) notification channels differ.

### Things to Know

- **Cache-hydration invariant (ENG-64):** every write into `LocalRecordings`
  that originates from an in-memory recording must go through
  `LocalRecordingRepository.cacheDownloadedAudio` (server → local cache; it takes
  a `LocalRecordingEntity` as of ENG-199/ENG-200 and builds the full-metadata
  companion internally) or `serverRecordingToLocal` (server → in-memory row).
  Hand-built `LocalRecordingsCompanion` payloads in caller code are the
  anti-pattern that caused ENG-64; do not reintroduce them at cache-hydration
  sites.
- **Heal is best-effort and additive only.** `buildHealMetadataCompanion`
  uses `Value.absent()` (not `Value(null)`) for fields it chooses not to
  touch. A local edit, even an empty string written intentionally by the
  user, can never be clobbered by a server refresh.
- **The split write path** (the `LocalRecordingRepository`
  `splitRecordingReplacingParent` writer and its `_insertSplitChildren` core)
  still hand-builds child rows because each child has a mix of
  inherited, segment-specific, and reset fields. It follows the propagation
  table in
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md);
  divergence between that table and the implementation breaks ENG-64-class
  invariants. `RecordingSplitPersister` saves through the **atomic**
  `splitRecordingReplacingParent` (insert children + delete parent in one
  transaction) — see [./repositories/docs.md](repositories/docs.md).
- **The split persister's step order is load-bearing for crash safety
  (ENG-125).** `RecordingSplitPersister.persist` runs the
  insert-children-and-delete-parent step as a single transaction first, so a
  throw leaves neither orphaned children nor a surviving parent. It then
  archives the parent file (`trashParent`) **after** the commit — a file move
  can't be rolled back, so doing it post-commit means a split failure never
  moves the audio out from under a surviving row (the trash callback only reads
  the parent object/file, never the child rows or the DB). The best-effort
  remote delete and `triggerUpload()` stay **outside** the transaction —
  neither is rollback-safe, and a remote-delete failure is swallowed so the
  local replace still stands.
- **Adding a new nullable metadata column to `LocalRecordings`** requires
  four updates in lockstep: extend `serverRecordingToLocal`,
  `LocalRecordingRepository.splitRecordingReplacingParent`,
  `buildHealMetadataCompanion`, and the tests under
  [/test/features/recording/data/](../../../../test/features/recording/data/).
  The checklist is reproduced at the bottom of
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).
  `reviewFlagsJson` (ENG-374) and the four ENG-403 metadata-outbox columns
  are not this kind of column — they are server-owned advisory state or
  device-sync bookkeeping, not device-entered metadata, so both are exempt
  from healing and from split propagation (a split child gets the Drift
  defaults on the outbox columns — `synced`, no owed fields — the same way
  it resets `reviewFlagsJson` to `'[]'`; see the propagation table in that
  doc).
- **The header probe exists to survive the web player's 5 MB cap.** On web
  the player slices only the first 5 MB; progressive phone recorders
  (Samsung/Android) write the MP4/M4A `moov` index at the END of the file, so
  for a long recording the slice has no index and the browser rejects it with
  `MediaError` code 4. The container parsers locate `moov` wherever it sits
  and report duration directly, so import no longer depends on the index
  landing in the first 5 MB. Native was never affected — it decodes the whole
  file — and still works because the parser falls back to the player.
- **A non-playable codec is reported WITHOUT a duration on purpose.** When a
  parser sees a codec a browser cannot decode (e.g. ALAC in MP4), it returns
  the codec but no duration, so the `hasDuration && playable` gate fails and
  the platform player still runs. This preserves native playback of formats
  the browser refuses, and lets `file_import_screen.dart` distinguish
  `unsupportedCodec` from `unreadableContainer` in its rejection message.
- **The ffmpeg concat scratch list path is per-invocation unique (ENG-139
  F7).** `RecordingConcatService.concatSegments` writes the ffmpeg
  `-f concat` input list to a temp file named `concat_<ms>_<rand>.txt` — a
  cryptographically-random 6-hex suffix on top of the millisecond timestamp.
  Two concats that start in the same millisecond (back-to-back recordings, a
  retry) would collide on a timestamp-only name and corrupt each other's
  ffmpeg input; the suffix removes that race. The service takes injectable
  `tempDirPath` / `now` / `ffmpegExec` seams purely for test isolation —
  production passes none and falls back to `getTemporaryDirectory` /
  `DateTime.now` / `ffmpeg_ops.executeFFmpegCommand`.
- **Finalization's best-effort temp deletes are fire-and-forget but
  observable (ENG-139 F20).** `RecordingFinalizationService._deleteFileSafe`
  still swallows a delete failure so cleanup never blocks or aborts finalize
  (`file_ops.deleteFile` already tolerates a missing file), but a genuine
  failure — permission, I/O — is now routed to the injected `ErrorReporter`
  ([/lib/core/observability/docs.md](../../../core/observability/docs.md))
  instead of a silent `catch (_) {}`. The constructor takes
  `reporter` (defaults to `NoopErrorReporter`) and an injectable `deleteFn`;
  `recordingFinalizationServiceProvider`
  ([../presentation/notifiers/recording_session_notifier.dart](../presentation/notifiers/recording_session_notifier.dart))
  wires the real `errorReporterProvider`.
- **`RecordingFinalizationService.finalize` keeps *originals* alive but
  reclaims its *derived* WAV temp (ENG-176).** The `deleteSources` flag
  (default `true`) governs only the **original** recordings — the segment
  files, or the single source segment on the one-segment path. A **derived**
  concat temp (the file the service itself produces when it combines
  multiple segments) is never an original; on the WAV path the compress step
  supersedes it with the final m4a, so it is reclaimed after a successful
  compress regardless of `deleteSources` (a multi-segment m4a concat needs no
  compress and is returned as the product itself). The service tracks this
  with an explicit `derived` flag set true **only** on the branch that
  assigns `sourcePath` to a concat output (both the ffmpeg and the pure-Dart
  WAV fallback produce one); the deletion guard is `deleteSources || derived`.
  The normal stop path leaves `deleteSources` `true`, so everything is
  cleaned up; crash recovery (`InterruptedSessionsNotifier.save`) passes
  `false` so the **original** segments — including the lone segment on the
  single-segment path — survive until the user confirms the save on the
  confirmation screen, only then cleaned up by `confirmRecovery`. ENG-176
  was a bug where the old guard keyed off `degraded` (see the WAV-deletion
  bullet) as a proxy for "derived": on the single-segment path it deleted
  the original source even with `deleteSources: false`, breaking the
  re-derive contract, and on the multi-segment pure-Dart fallback it leaked
  the derived temp. This is the data-layer half of the ENG-80 no-data-loss
  invariant; the flow is documented in
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md).
- **WAV deletion only happens after `compressToM4a` proves a real output
  (ENG-140 F18), and only for a source the caller authorized (ENG-176).**
  When `sourcePath` is a WAV, `finalize` deletes it only on a `true` return
  from `compressToM4a`
  ([/lib/core/platform/ffmpeg_ops.dart](../../../core/platform/ffmpeg_ops.dart)).
  That contract is load-bearing: `compressToM4a` verifies the m4a exists and
  is non-empty before returning `true`, so an ffmpeg exit-0-but-empty edge
  can no longer make `finalize` delete the only copy of the audio. The
  *which-file-to-delete* decision is separate and gated on
  `deleteSources || derived` (ENG-176): `derived` is "this WAV is a concat
  temp the service created, not an original recording", so a derived temp is
  reclaimed even while keeping sources, but an original WAV survives a
  successful compress whenever `deleteSources` is `false`. This supersedes
  the earlier `!degraded`-as-derived reasoning, which mis-classified the
  single-segment source as derived. See
  [/lib/core/platform/docs.md](../../../core/platform/docs.md).
- **`RecoveryCoordinator.refresh()` never touches a torn-down ref (ENG-140
  F22).** `refresh()` reads `findCrashedSessions()` and other providers across
  several awaits, then writes the derived list to
  `interruptedSessionsProvider.notifier.state`. Because the coordinator's
  backing provider can be disposed mid-await (the recovery UI unmounts), the
  constructor registers `_ref.onDispose(() => _disposed = true)`, the method
  captures the `interruptedSessionsProvider` notifier **before** the awaits,
  and the final state write is guarded by `if (_disposed) return`. flutter_riverpod
  2.6.1 has no `ref.mounted`, and a post-dispose `ref.read` throws "Cannot use
  Ref after it has been disposed"; this is the same hand-rolled `_disposed`
  pattern `RecordingPlayerNotifier` uses (see
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md)).
- **64-bit container fields are read as two uint32 halves.** dart2js has no
  native 64-bit int / `ByteData.getUint64`, so `mp4_box_probe.dart` and
  `ogg_page_probe.dart` reconstruct large durations/granules from two 32-bit
  reads — required for the parsers to behave identically on web and native.
- **The web resumable import shadow row is upserted, and survives a retry
  (ENG-80).** `DirectRecordingUploader._uploadResumable` inserts a
  `web_<serverId>` shadow row and only deletes it on success — its `catch`
  rethrows without cleanup on purpose, because the resume banner
  ([../presentation/widgets/pending_web_uploads_banner.dart](../presentation/widgets/pending_web_uploads_banner.dart))
  enumerates these `web_uploading` rows via `getPendingWebUploads`. The
  small-file (single-shot) path never creates this row. Retrying a failed
  large import from the import screen re-derives the same `serverId` (the
  metadata create is idempotent server-side) and re-writes the shadow row;
  because the write is an `upsertRecording` that omits
  `resumableSessionUri`/`uploadedBytes`, the prior resume state is kept and
  the resumable service continues from the persisted offset instead of
  restarting or throwing on the duplicate key.
- The `localRecordingStreamProvider` streams the **domain entity**
  `LocalRecordingEntity?` as of ENG-199/ENG-200 — it is backed by
  `LocalRecordingRepository.watchRecordingEntityById`
  ([./repositories/docs.md](repositories/docs.md)), which `.map()`s the row to the
  entity **before** the `.distinct()` (ENG-121). Drift invalidates query streams
  at the table level, so any write through `LocalRecordingRepository` — even to
  an unrelated row — re-runs the query; `.distinct()` drops the re-emission when
  the resulting *entity* is value-equal. Because the entity deliberately omits
  the persistence internals `lastRetryAt`/`md5Hash`, a write that touches only
  those is value-equal and dropped, so the detail screen no longer re-renders on
  upload-bookkeeping churn — a behavioral change from the prior row stream, not
  just a re-emission collapse. As of ENG-194 the `ref.listen` on this provider
  lives in `RecordingDetailNotifier.build` (native only), not in the detail
  screen — it patches the changed entity into `RecordingDetailState`
  (`state.copyWith(recording: …)`) rather than calling the screen's old
  `setState`, but the rebuild contract is unchanged (the state has identity
  equality, so the patch re-renders). A write that *does* change a content or
  operational field the entity carries still fires: this is why a partial /
  hand-picked insert is still dangerous — the stream re-pushes an entity with
  missing fields into the displayed state, blanking the UI even if the user did
  not change anything (the heal companion fills, never blanks).

Created and maintained by Nori.
