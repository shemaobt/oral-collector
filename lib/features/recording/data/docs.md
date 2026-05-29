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
  it covers every column in the schema, including ones added later.
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
  extensions used by the file-import flow.
- The `repositories/` subfolder hosts `LocalRecordingRepository`,
  `RecordingApiRepositoryImpl`, and `RecordingSessionRepository`. See
  [./repositories/docs.md](repositories/docs.md).
- The `services/` subfolder hosts platform-specific audio probes, the
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
- The `localRecordingStreamProvider` is a Drift `watchSingleOrNull` query.
  Any update via `LocalRecordingRepository` (including the heal companion)
  will fire the stream, which the detail screen listens to. This is why
  a partial / hand-picked insert is dangerous: the stream re-pushes a
  `LocalRecording` with missing fields into `setState`, blanking the UI
  even if the user did not change anything.

Created and maintained by Nori.
