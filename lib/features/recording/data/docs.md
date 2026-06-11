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
  `uploading` / `uploaded` / `failed`. The resumable upload service is
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

### Core Implementation

- `providers.dart` registers all data-layer providers and stays free of
  business logic. `localRecordingStreamProvider` is a family stream keyed
  by recording id; the detail screen listens to it so any write through
  `LocalRecordingRepository` flows back into the UI.
- `server_to_local_recording.dart` exposes `serverRecordingToLocal(server)`,
  the single mapper from `ServerRecording` to `LocalRecording`. It exists
  precisely so callers like the detail screen and the trim editor cannot
  silently diverge on which fields they carry — divergence is the ENG-64
  root cause.
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
  before the GCS PUT; a non-https URL throws `_UploaderException`, consistent
  with how this uploader reports every other failure. The resumable branch
  delegates that validation to `ResumableUploadService`. The scheme policy and
  the app-wide no-cleartext-PUT invariant are documented in
  [/lib/core/network/docs.md](../../../core/network/docs.md).
- The `services/` subfolder hosts the audio probe, the
  segmented recorder, the foreground task, recovery & trash services, the
  resumable / direct uploaders, the audio path resolver used by the
  detail-screen player, and `RecordingSplitPersister` — the post-FFmpeg
  pipeline of a trim/split save (writes children, trashes parent,
  deletes parent locally + remotely, triggers upload queue). It is the
  one place that wires the "split is saved → children start uploading"
  causation, so the trim editor never has to think about sync.
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
  that originates from an in-memory `LocalRecording` must go through
  `LocalRecordingRepository.cacheDownloadedAudio` (server → local cache) or
  `serverRecordingToLocal` (server → in-memory). Hand-built
  `LocalRecordingsCompanion` payloads in caller code are the anti-pattern
  that caused ENG-64; do not reintroduce them at cache-hydration sites.
- **Heal is best-effort and additive only.** `buildHealMetadataCompanion`
  uses `Value.absent()` (not `Value(null)`) for fields it chooses not to
  touch. A local edit, even an empty string written intentionally by the
  user, can never be clobbered by a server refresh.
- **The split write path** (`LocalRecordingRepository.splitRecording`)
  still hand-builds child rows because each child has a mix of inherited,
  segment-specific, and reset fields. It follows the propagation table in
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md);
  divergence between that table and the implementation breaks ENG-64-class
  invariants.
- **Adding a new nullable metadata column to `LocalRecordings`** requires
  four updates in lockstep: extend `serverRecordingToLocal`,
  `LocalRecordingRepository.splitRecording`, `buildHealMetadataCompanion`,
  and the tests under
  [/test/features/recording/data/](../../../../test/features/recording/data/).
  The checklist is reproduced at the bottom of
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).
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
- **`RecordingFinalizationService.finalize` can keep its sources alive.**
  The `deleteSources` flag (default `true`) controls whether the segment
  files and the intermediate `sourcePath` are deleted after a successful
  assemble. The normal stop path leaves it `true`; crash recovery
  (`InterruptedSessionsNotifier.save`) passes `false` so the segments
  survive until the user confirms the save on the confirmation screen —
  only then are they cleaned up by `confirmRecovery`. This is the
  data-layer half of the ENG-80 no-data-loss invariant; the flow is
  documented in
  [../presentation/notifiers/docs.md](../presentation/notifiers/docs.md).
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
- The `localRecordingStreamProvider` is a Drift `watchSingleOrNull` query.
  Any update via `LocalRecordingRepository` (including the heal companion)
  will fire the stream, which the detail screen listens to. This is why
  a partial / hand-picked insert is dangerous: the stream re-pushes a
  `LocalRecording` with missing fields into `setState`, blanking the UI
  even if the user did not change anything.

Created and maintained by Nori.
