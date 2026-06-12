# Noridoc: Recording Data Repositories

Path: @/lib/features/recording/data/repositories

### Overview

- Houses the repositories that read and write recording-related state:
  `LocalRecordingRepository` (Drift CRUD over `LocalRecordings`),
  `RecordingApiRepositoryImpl` (HTTP client for the server's recordings
  API), and `RecordingSessionRepository` (in-progress session rows used by
  the segmented recorder).
- The local repository is the single write site for the `LocalRecordings`
  table and enforces the cache-hydration invariant established by ENG-64:
  any persisted row must carry every recording-level metadata field that
  exists on the in-memory `LocalRecording` it came from.
- All three repositories are exposed by the providers in
  [../providers.dart](../providers.dart) and are constructor-injected with
  their dependencies (Drift `AppDatabase` and/or
  `AuthenticatedClient`).

### How it fits into the larger codebase

- `LocalRecordingRepository` is the only legitimate writer for the
  `LocalRecordings` table declared in
  [/lib/core/database/app_database.dart](../../../../core/database/app_database.dart).
  All UI code paths that mutate a recording row go through this class
  (detail screen, trim editor, classify dialog, confirmation step, file
  import).
- It is consumed by:
  - The recording presentation layer:
    [../../presentation/recording_detail_screen.dart](../../presentation/recording_detail_screen.dart),
    [../../presentation/trim_editor_screen.dart](../../presentation/trim_editor_screen.dart),
    [../../presentation/widgets/confirmation_step.dart](../../presentation/widgets/confirmation_step.dart),
    [../../presentation/file_import_screen.dart](../../presentation/file_import_screen.dart).
  - The upload pipeline:
    [../services/direct_recording_uploader.dart](../services/direct_recording_uploader.dart)
    and the resumable upload service under
    [/lib/features/sync/data/services/](../../../sync/data/services/).
  - The recovery & finalization services under
    [../services/](../services/) when a recording session has to be
    rescued (ENG-49, ENG-51).
- `RecordingApiRepositoryImpl` implements the abstract contract in
  [../../domain/repositories/recording_api_repository.dart](../../domain/repositories/recording_api_repository.dart);
  callers depend on the abstraction so the implementation can be mocked
  in tests.
- The split contract is shared with the backend (see
  [/docs/recording-split-semantics.md](../../../../../docs/recording-split-semantics.md));
  both `LocalRecordingRepository.splitRecording` and the server's
  `persist_split_segments` must implement the same propagation table.
- Test sites:
  [/test/features/recording/data/repositories/local_recording_repository_split_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_split_test.dart),
  [/test/features/recording/data/repositories/local_recording_repository_replace_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_replace_test.dart),
  and
  [/test/features/recording/data/repositories/local_recording_repository_cache_download_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_cache_download_test.dart).

### Core Implementation

- `LocalRecordingRepository` wraps an `AppDatabase` and exposes focused
  query/update methods. Reads include `getRecordingById`,
  `getRecordingByServerId`, `watchRecordingById` (used by
  `localRecordingStreamProvider`), `getPendingUploads`,
  `getPendingWebUploads`, and the aggregate helpers
  `countRecordings`/`totalDuration`/`getLocalUnclassifiedStats`.
- `getPendingUploads` / `getPendingWebUploads` define the **upload queue
  order**: they sort `createdAt ASC, id ASC`, and
  [the sync engine](../../../sync/data/repositories/sync_engine.dart) drains
  the returned list in that order (FIFO). `createdAt` is the row-insertion
  timestamp (true enqueue order); `id` is a stable tiebreaker. This is a
  load-bearing ordering invariant — see Things to Know.
- `getPendingUploads` matches `uploadStatus IN ('local', 'failed',
  'uploading')` — it intentionally still surfaces `uploading` rows so the
  upload-queue UI and the home counters can show in-flight work. The sync
  engine, however, excludes `uploading` from its own eligibility filter so it
  never re-dispatches a row that is in flight or was just reclaimed by
  `resetStuckUploading`. That filter lives only in the engine, not in this
  query — see Things to Know and
  [/lib/features/sync/docs.md](../../../sync/docs.md).
- `watchRecordingById` is a `watchSingleOrNull` query with `.distinct()`
  appended. Drift invalidates query streams at the table level, so every
  write to `local_recordings` re-runs this query and re-emits even when the
  row is byte-identical; `.distinct()` suppresses those duplicate downstream
  emissions so the detail screen's `ref.listen` does not rebuild on unrelated
  writes. The query still re-executes — table-level invalidation is inherent
  to Drift and is not removed by `.distinct()`.
- `insertRecording` is a plain insert; `upsertRecording` is
  `insertOnConflictUpdate` (insert-or-update keyed on the primary key).
  Columns absent from the companion are left untouched on an update, so a
  partial upsert preserves whatever the existing row already holds. The
  web direct-upload path
  ([../services/direct_recording_uploader.dart](../services/direct_recording_uploader.dart))
  uses `upsertRecording` for its shadow row so a retry that reuses the same
  id (`web_<serverId>`) reconciles in place instead of hitting `UNIQUE
  constraint failed` — see Things to Know.
- `cacheDownloadedAudio({recording, localFilePath})` is the canonical
  entry point for the "download server audio for editing" path. It runs
  inside a Drift transaction. If a row for `recording.id` already exists,
  only `localFilePath` is updated — pre-existing local edits to
  `description`, `storytellerId`, secondary classification, etc., are
  preserved. If no row exists, it inserts via
  `recording.toCompanion(false).copyWith(localFilePath: Value(...))`, which
  forwards every column on the Drift schema. This eliminates the
  hand-picked-subset pattern that caused ENG-64.
- `splitRecording({parent, segments})` inserts one child row per segment
  inside a transaction. The companion is built explicitly to encode the
  three-source rule (inherit / segment-specific / reset) defined in
  [/docs/recording-split-semantics.md](../../../../../docs/recording-split-semantics.md).
  Before inserting, validates that no segment override collides with the
  parent's secondary classification of the same kind — throws
  `ArgumentError` if it does, since the server would reject the upload
  with 422. The UI is expected to block this case earlier.
- `replaceAudio` is used by the "replace audio" flow on the detail screen
  to swap the file and reset upload state (`md5Hash`, `uploadedBytes`,
  `resumableSessionUri`, `retryCount` → defaults; `uploadStatus` →
  `'local'`).
- Lifecycle helpers: `markAsUploading`, `markAsUploaded(id, serverId,
  gcsUrl)`, `markAsFailed`, `resetRetryCount`, and `resetStuckUploading`.
  These mutate only upload-state columns; they never touch user-content
  metadata, which is the contract that makes the offline-edit story safe.
  `resetStuckUploading` is the startup crash-recovery helper: it flips every
  row orphaned in `uploading` back to `local`, rewriting **only**
  `uploadStatus` so `retryCount`, `lastRetryAt`, `resumableSessionUri`,
  `serverId`, and `uploadedBytes` survive and the upload resumes from its
  saved offset. It is called once from
  [/lib/main.dart](../../../../main.dart) before the sync queue goes live —
  see Things to Know.
- `RecordingApiRepositoryImpl` translates between HTTP and the
  `ServerRecording` DTO from
  [../../domain/entities/server_recording.dart](../../domain/entities/server_recording.dart).
  Auth is supplied by `AuthenticatedClient` from
  [/lib/core/network/authenticated_client.dart](../../../../core/network/authenticated_client.dart).
- `RecordingSessionRepository` manages the `recording_sessions` Drift
  table used by the segmented recorder for crash recovery (ENG-49/ENG-51).

### Things to Know

- **`cacheDownloadedAudio` is transactional and idempotent.** Repeated
  calls with different `localFilePath` values converge to the latest
  path; metadata is established on first insert and never overwritten by
  subsequent calls. The transaction prevents racing the
  `localRecordingStreamProvider` listener mid-write.
- **Never re-introduce a hand-picked `LocalRecordingsCompanion` for cache
  hydration.** The `_ensureLocalFile` insert in the detail screen used to
  do exactly that and silently dropped `description`, `storytellerId`,
  `userId`, the secondary classification fields, and the
  `splitFromId`/`splitIndex`/`splitSegmentCount` lineage. The
  `localRecordingStreamProvider` then pushed those nulls back into the
  detail screen and the UI rendered an "edited" record even when the user
  did not touch anything. See
  [/docs/recording-split-semantics.md#cache-hydration-server--local](../../../../../docs/recording-split-semantics.md#cache-hydration-server--local).
- **The split write path differs from the cache write path on purpose.**
  Split children inherit some parent fields, override others per segment,
  and reset upload-state fields. `cacheDownloadedAudio` instead carries
  every field verbatim from the in-memory `LocalRecording`. Choosing the
  right helper at the call site matters.
- **Repositories never read Riverpod.** All dependencies come through the
  constructor. This keeps them testable with an in-memory
  `AppDatabase.forTesting(NativeDatabase.memory())`, which is how the
  repository test suites are wired.
- **`markAsUploaded` writes `serverId` and `gcsUrl` but not other
  metadata.** After upload, server-side enrichment (e.g. `user_id`
  resolution) is reconciled later by the detail screen's heal path
  (`buildHealMetadataCompanion`), not by the upload pipeline.
- **`resetStuckUploading` is the non-destructive crash-recovery path, and it
  lands on `local` for a reason (ENG-119).** A mid-upload crash strands a row
  in `uploading`. The helper rewrites only `uploadStatus`, leaving the
  resumable offset (`resumableSessionUri`, `uploadedBytes`), `serverId`, and
  the retry budget (`retryCount`, `lastRetryAt`) intact so the next drain
  resumes rather than restarts. It deliberately targets `local`, not
  `failed`, because `deleteStaleRecordings` (the user-triggered "clear stale"
  cleanup) deletes both `failed` and `uploading` rows — landing on `local`
  keeps a recoverable recording out of that destructive sweep. Because it
  matches only `uploading` (a native-only status; web uses `web_uploading`),
  it is a no-op on web. The drain's complementary exclusion of `uploading`
  rows and the startup invocation order live in
  [/lib/features/sync/docs.md](../../../sync/docs.md).
- **The pending-upload order is `createdAt ASC, id ASC`, and the queue is
  drained in that order (ENG-122).** Ordering by `recordedAt` (wall-clock
  recording time) is wrong for a FIFO queue: a batch import stamps many rows
  with the same `DateTime.now()`, split segments inherit the parent's
  `recordedAt`, and `recordedAt` can move backward relative to enqueue order.
  `createdAt` (row insertion time) is the true enqueue order. `id` is the
  tiebreaker because `createdAt` is persisted at 1-second granularity (Drift
  stores `dateTime()` as unix seconds), so a same-second batch import would
  otherwise drain nondeterministically. This sort is intentionally **not
  index-covered**: the index on `local_recordings` is
  `(uploadStatus, recordedAt)` (see
  [/lib/core/database/app_database.dart](../../../../core/database/app_database.dart)),
  and the pending set is small enough that the uncovered sort is negligible —
  no schema change or new index was added.
- **`watchRecordingById` carries `.distinct()` (ENG-121).** It exists only to
  collapse Drift's table-level re-emissions, not to change what the stream
  reports. Any consumer that needs to observe a write which produces an
  identical `LocalRecording` value (there is none today) would not see it.
- **`upsertRecording` is what makes a failed web import retryable
  (ENG-80).** A large web import inserts a `web_<serverId>` shadow row to
  track resume state; on failure that row is intentionally left behind for
  the resume banner
  ([../../presentation/widgets/pending_web_uploads_banner.dart](../../presentation/widgets/pending_web_uploads_banner.dart)).
  Re-importing the same file from the import screen re-derives the same
  `serverId` (the create is server-idempotent) and re-writes the shadow row;
  with a plain `insertRecording` that second write threw on the duplicate
  primary key and the import could never finish. Because `upsertRecording`
  leaves `resumableSessionUri`/`uploadedBytes` absent on the second write,
  those columns survive and the resumable upload service continues from the
  persisted offset rather than restarting.

Created and maintained by Nori.
