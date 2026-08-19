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
  exists on the in-memory recording it came from (a `LocalRecording` row on the
  server-mapping/split paths, a `LocalRecordingEntity` on the detail
  cache-download path).
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
  - The recording presentation layer — increasingly through the feature's
    notifiers rather than from screens directly: `RecordingDetailNotifier` (the
    typed classification/metadata writes, ENG-194), `TrimEditorNotifier`
    (`splitRecordingReplacingParent`, ENG-193; `replaceAudioAndQueueResend` via
    `RecordingBoostPersister`, ENG-402), and `RecordingsListNotifier`
    (`getAllRecordings`, the hard delete) under
    [../../presentation/notifiers/](../../presentation/notifiers/), plus the
    screens still calling it directly
    ([../../presentation/widgets/confirmation_step.dart](../../presentation/widgets/confirmation_step.dart),
    [../../presentation/file_import_screen.dart](../../presentation/file_import_screen.dart)).
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
  both `LocalRecordingRepository.splitRecordingReplacingParent` and the
  server's `persist_split_segments` must implement the same propagation table.
- Test sites:
  [/test/features/recording/data/repositories/local_recording_repository_split_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_split_test.dart),
  [/test/features/recording/data/repositories/local_recording_repository_replace_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_replace_test.dart),
  and
  [/test/features/recording/data/repositories/local_recording_repository_cache_download_test.dart](../../../../../test/features/recording/data/repositories/local_recording_repository_cache_download_test.dart).

### Core Implementation

- `LocalRecordingRepository` wraps an `AppDatabase` and exposes focused
  query/update methods. Reads include `getRecordingById`,
  `getRecordingByServerId`, their row-decoupled entity siblings
  `getRecordingEntityById`/`getRecordingEntityByServerId` and
  `watchRecordingEntityById` (the entity stream behind
  `localRecordingStreamProvider`), `getPendingUploads`, `getPendingWebUploads`,
  and the aggregate helpers
  `countRecordings`/`totalDuration`/`getLocalUnclassifiedStats`/`getLocalOnlyStats`.
- `getRecordingEntityById`/`getRecordingEntityByServerId` are the **one-shot,
  row-decoupled** analogue of `watchRecordingEntityById` (ENG-202): each wraps
  the matching row getter (`getRecordingById`/`getRecordingByServerId`) and
  projects through `_fromRow` (→ `localRecordingToEntity`), returning `null` on
  a miss. They exist so the trim editor's load path
  ([../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  resolves a `LocalRecordingEntity` and never holds a Drift row — the last
  presentation-layer row leak ENG-95 closed. The plain row getters were **not**
  removed: the sync engine, the resumable upload service, the sync notifier, and
  the recordings-list / detail notifiers still read raw rows through them, so
  both the row and entity reads share the same query and the same `_fromRow`
  projection.
- `getPendingWebUploadKeys` projects the same `web_uploading` rows down to the
  set of storage keys their audio can be resumed from, dropping the empty ones
  (rows written before ENG-427, and web imports whose bytes were never in
  storage — there is no key to spare). It is the whole reason the startup
  sweep in
  [../services/web_audio_sweeper.dart](../services/web_audio_sweeper.dart) can
  skip audio a resume still needs, and it is one query per sweep rather than
  one per key.
- `getPendingUploads` / `getPendingWebUploads` define the **upload queue
  order**: they sort `createdAt ASC, id ASC`, and
  [the sync engine](../../../sync/data/repositories/sync_engine.dart) drains
  the returned list in that order (FIFO). `createdAt` is the row-insertion
  timestamp (true enqueue order); `id` is a stable tiebreaker. This is a
  load-bearing ordering invariant — see Things to Know.
- `getPendingUploads` matches `uploadStatus IN ('local', 'failed',
  'uploading')` — it intentionally still surfaces `uploading` rows so the
  upload-queue UI can show in-flight work. The sync engine, however, excludes
  `uploading` from its own eligibility filter so it never re-dispatches a row
  that is in flight or was just reclaimed by `resetStuckUploading`. That
  filter lives only in the engine, not in this query — see Things to Know and
  [/lib/features/sync/docs.md](../../../sync/docs.md).
  `failed_conflict` (ENG-71), `failed_description` (ENG-354),
  `failed_exhausted` and `failed_missing_file` (both ENG-377) are all
  deliberately absent from the matched set: a duplicate title is terminal until
  the user renames the recording, a description the create rule rejects is
  terminal until the user lengthens it, an upload that spent its retry budget
  is terminal until the user asks for it again, and audio that is no longer on
  the device is terminal outright. The first three exits route through
  `resetRetryCount`, which flips the row back to `local` and so back into this
  query. `requeueFailedUploads` (ENG-404) is the bulk counterpart: it matches
  `failed` and `failed_exhausted` and, like `resetRetryCount`, writes the row
  back to `local` — but as one project-wide `UPDATE` instead of a per-row call.
  `failed_conflict` and `failed_description` stay outside its scope because a
  bare retry would repeat the same rejected request; `failed_missing_file`
  because there is no file left to resend. See Things to Know for the
  batch-write and three-column rationale.
  The generic `failed` therefore means one thing only: a retry is still coming.
  Before ENG-377 it also covered rows whose budget was spent, which this query
  called pending and the engine's eligibility filter refused — a recording no
  pass would ever move, counted by every badge that reads this query.
- `getLocalOnlyStats(projectId)` (ENG-355) is a single count/duration query
  for `uploadStatus NOT IN ('uploaded', 'verified')` — every recording of a
  project the server does not have yet, counted exactly once. It exists so the
  home screen's device-only addend
  ([../../../home/presentation/notifiers/docs.md](../../../home/presentation/notifiers/docs.md))
  can be one non-overlapping set; it deliberately differs from
  `getLocalUnclassifiedStats` (genre/register-scoped) and from
  `getPendingUploads` (a `List<LocalRecording>` scoped to the retryable subset
  `local`/`failed`/`uploading`, used to drive the actual upload queue, not to
  total a badge).
- `watchRecordingEntityById` is the **single detail watch stream** (ENG-195
  introduced it; ENG-199/ENG-200 made it the sole one by deleting the former
  row stream `watchRecordingById`). It is a `watchSingleOrNull` query that
  `.map()`s each row to a `LocalRecordingEntity` (via `_fromRow`) **before**
  `.distinct()`. Mapping first is the load-bearing detail — dedup keys on the
  entity's hand-written value equality, not the Drift row's generated equality.
  Drift invalidates query streams at the table level, so every write to
  `local_recordings` re-runs this query even when the row is byte-identical;
  `.distinct()` suppresses the duplicate downstream emission. Because the entity
  deliberately omits `lastRetryAt`/`md5Hash`, a write touching only those
  produces an equal entity and `.distinct()` suppresses the re-emission, so the
  detail screen no longer rebuilds on upload-bookkeeping churn; a change to any
  content/operational field the entity carries still re-emits. It backs
  `localRecordingStreamProvider` ([../docs.md](../docs.md)), which
  `RecordingDetailNotifier` listens to (native only). See
  [../../domain/docs.md](../../domain/docs.md) for the entity itself and Things
  to Know.
- `_fromRow(LocalRecording)` is the private row→entity hook backing the
  entity reads (`watchRecordingEntityById` and, as of ENG-202, the one-shot
  `getRecordingEntityById`/`getRecordingEntityByServerId`); as of ENG-197 it is
  a one-line delegate to the public `localRecordingToEntity` in
  [../local_recording_to_entity.dart](../local_recording_to_entity.dart), which
  is the **single source of truth** for the projection so the watch stream and
  the recordings-list notifier
  ([../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  cannot diverge on which fields they carry. It mirrors the Storyteller
  precedent (`_fromRow` private in
  [../../../storyteller/data/repositories/local_storyteller_repository.dart](../../../storyteller/data/repositories/local_storyteller_repository.dart),
  with a dual `getById`/`getRowById` read alongside the row read). The first
  write-path reverse mapper now exists (ENG-201): `localRecordingEntityToCompanion`
  in [../local_recording_entity_to_companion.dart](../local_recording_entity_to_companion.dart)
  projects an entity onto the **insert/save** companion and backs `saveRecording`
  (below). The split write path is still hand-built, however — ENG-198 re-typed
  `splitRecordingReplacingParent`'s `parent` to a `LocalRecordingEntity` (see
  above) but consumes it as a *read-only* parent input the child build reads off,
  so the per-segment child companions are still encoded explicitly there.
- `saveRecording(LocalRecordingEntity)` is the canonical entry point for
  persisting a **freshly captured** recording. As of ENG-201 it takes the domain
  entity (the F4b step of the ENG-95 row→entity migration, closing the reverse
  mapper the read-side `_fromRow` work deferred) and its body is a one-liner that
  hands the entity to `localRecordingEntityToCompanion`
  ([../local_recording_entity_to_companion.dart](../local_recording_entity_to_companion.dart))
  and delegates the result to `insertRecording`. Persisted columns are identical
  to the prior named-parameter version (ENG-192); the mapper reproduces that
  inline construction exactly. The sole caller is
  [../../presentation/widgets/confirmation_step.dart](../../presentation/widgets/confirmation_step.dart),
  which now constructs the entity on both its native and web-direct save paths.
  The mapper owns the column semantics — see the next bullet and Things to Know.
- `localRecordingEntityToCompanion(entity)` is the **insert/save** companion
  projection, the inverse of `localRecordingToEntity`
  ([../local_recording_to_entity.dart](../local_recording_to_entity.dart)) scoped
  to a fresh save (not a full entity serializer). Its contract:
  - empty-string **or** null optional metadata
    (`subcategoryId`/`registerId`/`description`) maps to `Value.absent()` (NULL),
    never a stored empty string; null `userId`/`serverId` likewise map to absent.
  - the core fields — including `uploadStatus` (the entity field is non-nullable)
    — are always `Value(...)`. The native save passes `uploadStatus: 'local'`
    explicitly (matching the schema default) and the web direct-upload save passes
    `'uploaded'` + the `serverId`.
  - `createdAt`, `retryCount`, `uploadedBytes`, and `cleaningStatus` are
    **deliberately left absent** so the Drift table defaults
    (`currentDateAndTime`, 0, 0, `'none'`) apply on insert, *even though the
    entity carries read-path values for them* — see Things to Know.
  - fields never set on a fresh save (`gcsUrl`, `secondary*`, `splitFrom*`,
    `resumableSessionUri`) are not mapped; the NULL result is unchanged.
- The **typed classification/metadata writes** (ENG-194) — `setStoryteller`,
  `updateDescription`, `updateCleaningStatus`, `moveCategory`, `classify`, and
  `updateSecondaryClassification` — replace the inline
  `LocalRecordingsCompanion` construction the detail screen's presentation layer
  used to do. Each takes named domain values and builds the narrow companion
  internally, so the presentation layer no longer imports `drift`'s `Value`.
  `RecordingDetailNotifier`
  ([../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  is the sole caller. The repository stays **Drift-only** — these writes add no
  http/file dependency; the GCS download and the file import that the same
  mutations need live behind seams under [../services/](../services/), not here.
  Their null handling is intentionally **not unified** — see Things to Know.
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
  entry point for the "download server audio for editing" path. As of
  ENG-199/ENG-200 `recording` is a `LocalRecordingEntity`
  ([../../domain/entities/local_recording_entity.dart](../../domain/entities/local_recording_entity.dart)),
  not the Drift row — the detail tree streams and holds the entity, so this
  write site takes it directly rather than the caller re-deriving a row. It runs
  inside a Drift transaction. If a row for `recording.id` already exists, only
  `localFilePath` is updated — pre-existing local edits to `description`,
  `storytellerId`, secondary classification, etc., are preserved. If no row
  exists, it inserts a `LocalRecordingsCompanion` built **inline from every
  entity field** so all metadata reaches the database — the ENG-64
  full-metadata-insert guarantee. The only columns left absent are the
  persistence internals the entity drops (`lastRetryAt`/`md5Hash`); absent →
  null is correct here because the recording is server-sourced with no prior
  local row. This is the same exhaustiveness the former `toCompanion(false)`
  path gave, restated over the entity's fields. As of ENG-374 the insert also
  encodes `recording.reviewFlags` into `reviewFlagsJson`; the update branch
  does not touch that column, so a recording this device already made and
  uploaded — which already has a local row and so always takes the update
  branch — keeps the `'[]'` default no matter what the server later reports.
  That write path is a follow-up (see Things to Know).
- `splitRecordingReplacingParent({parent, segments})` is the **atomic**
  replace used by the trim/split save (ENG-125): it inserts one child row per
  segment and deletes the parent row in **one** Drift transaction, so a partial
  failure can never strand orphaned children beside a surviving parent. As of
  ENG-198 `parent` is a `LocalRecordingEntity`
  ([../../domain/entities/local_recording_entity.dart](../../domain/entities/local_recording_entity.dart)),
  not the Drift `LocalRecording` row — so the entity's reach now extends past
  the read seam into this write path's parent input. The propagation is
  unchanged because the entity carries every field the child build reads
  (id, projectId, genreId, subcategory/register, secondary*, storyteller/user,
  description, format, recordedAt); the child companions are still
  `LocalRecordingsCompanion` built explicitly to encode the three-source rule
  (inherit / segment-specific / reset) defined in
  [/docs/recording-split-semantics.md](../../../../../docs/recording-split-semantics.md).
  **A split can mint rows that would not pass the ENG-354 description gate, and
  that is accepted.** The child companions copy `description` straight from the
  parent (`description: Value(parent.description)`), so splitting a *legacy*
  recording — one saved before ENG-354, whose description is null or too short —
  produces N children with the same insufficient description. Nothing here
  re-checks `isDescriptionSufficient`: the gate is an edit-time UI rule on
  create and edit (see
  [../../presentation/widgets/docs.md](../../presentation/widgets/docs.md)), not
  a repository invariant, and blocking a split would cost the user the trim they
  just made over a field they can fill in afterwards. The children surface in
  the list screen's `missingDescription` filter, which is exactly what that
  filter is for. So the rule "every recording created after ENG-354 has a
  description" holds for the *save* paths only — split children inherit
  whatever the legacy parent had. Such a child is not silently stranded: the
  sync engine pre-flights the same predicate before the create call and parks
  the row in `uploadStatus='failed_description'`, which the detail screen
  explains and the edit sheet clears (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)).
  Before inserting, validates that no child's **effective primary triple**
  (`register, genre, subcategory`, each override falling back to the parent's
  value) is identical to the secondary triple the child inherits from the
  parent — throws `SegmentClassificationCollisionException` if it is, since the
  server would reject the upload with 422; the UI is expected to block this
  case earlier. Only the whole triple collides (ENG-72): a child sharing the
  parent's secondary genre but under a different subcategory is legitimate, and
  the check is deliberately *not* made against the parent's primary triple — a
  child with no overrides inherits that triple verbatim, so such a check would
  reject every ordinary split. The predicate is the shared
  `secondaryEqualsPrimary(...)` in
  [../../domain/entities/classification.dart](../../domain/entities/classification.dart).
  The child-insert loop and the collision
  check live in the private helpers `_insertSplitChildren` and
  `_assertNoSecondaryCollision`, which likewise take the entity `parent`. The
  persister
  ([../services/recording_split_persister.dart](../services/recording_split_persister.dart))
  calls this — see Things to Know and [../docs.md](../docs.md).
- `replaceAudio` is used by the "replace audio" flow on the detail screen
  to swap the file and reset upload state (`md5Hash`, `uploadedBytes`,
  `resumableSessionUri`, `retryCount` → defaults; `uploadStatus` →
  `'local'`).
- `replaceAudioAndQueueResend({recordingId, newFilePath, newDurationSeconds,
  newFileSizeBytes})` (ENG-402) is `replaceAudio` plus, in the **same**
  transaction, `markMetadataPending({PendingMetadataField.audio})` when the
  row already has a `serverId`. It backs the trim editor's gain-only
  ("boost") save path
  ([../services/recording_boost_persister.dart](../services/recording_boost_persister.dart))
  rather than the detail screen's manual replace-audio flow, which uses the
  plain `replaceAudio` and its own `resetAndRetry` call instead. The two
  writes are one intent: the server confirms an uploaded blob against the
  `duration_seconds`/`file_size_bytes` it already has on file, so a row
  re-queued for upload without also owing the new duration/size would upload
  bytes the server then refuses. Nothing is marked pending for a recording the
  server has never seen — there is nothing on the server to correct, and the
  outbox drain only selects rows with a `serverId` anyway (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)).
- `deleteRecording(id)` is a plain physical row delete (a single Drift
  `delete().go()`); there is no tombstone column. It only removes the
  Drift row — it does **not** delete the audio file or call the server.
  The user-initiated hard-delete flow that combines the remote delete, this
  row delete, and the physical audio-file delete is orchestrated by
  `RecordingsListNotifier.deleteRecording` (ENG-120), not here — see
  [../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md).
  The same row-delete is also the one `RecordingsListNotifier`'s
  whole-project-sweep reconciliation and `RecordingDetailNotifier`'s
  metadata-heal 404 branch call to erase a row the server hard-deleted
  (ENG-45, gated by `serverHasRecording` — see
  [../../domain/docs.md](../../domain/docs.md)).
  `requeueFailedUploads(projectId)` (ENG-404) is the separate user-triggered
  bulk retry over the same project: one `UPDATE` that writes `uploadStatus`,
  `retryCount`, and `lastRetryAt` for every `failed`/`failed_exhausted` row —
  see Things to Know for why those two statuses and why all three columns. It
  replaced a hard delete of the same idea (ENG-46's `deleteStaleRecordings`,
  removed by ENG-404): the rows it touches are never deleted, only requeued.
  The list's bulk-retry button only shows when `hasRetryableFailedUploads`
  ([../../domain/docs.md](../../domain/docs.md)) finds a matching row, which
  mirrors this same filter.
- **The metadata-outbox lifecycle helpers (ENG-403)** — `markMetadataPending`,
  `clearPendingMetadataFields`, `getPendingMetadataSyncs`,
  `markMetadataSyncFailed`, `markMetadataSyncTerminal` — are
  `RecordingDetailNotifier`'s and the sync engine's only way to touch the four
  ENG-403 columns on `local_recordings`
  ([/lib/core/database/docs.md](../../../../core/database/docs.md)), and each
  does a read-modify-write inside a transaction so two mutations racing the
  same recording cannot drop each other's field. `markMetadataPending` unions
  the incoming fields into whatever is already owed and resets the retry
  budget — a new edit is a new intent, so it also lifts a terminal status,
  the same exit `resetRetryCount` gives a `failed_conflict` upload.
  `clearPendingMetadataFields` removes fields (the server just took them) and
  only flips the row back to `synced` once nothing remains, so a partial push
  never reads as complete. `getPendingMetadataSyncs` is what the sync engine
  drains: it matches `metadataSyncStatus = 'pending'` **and** a non-empty
  `serverId` — the `serverId` clause is a correctness condition, not a
  defence, because a recording with no server copy has nothing to PATCH; its
  metadata rides along on the eventual create call instead. Since ENG-418 it
  has a second caller, `SyncNotifier._refreshPendingCount`
  ([../../../sync/docs.md](../../../sync/docs.md)), which unions it with
  `getPendingUploads` for the header badge — sharing this query rather than
  writing a second condition is what makes the badge count exactly the edits
  the drain will pick up.
  `markMetadataSyncFailed` spends one retry and owns the ceiling
  (`kMaxUploadRetries`, the same constant `markAsFailed` reads), mirroring
  that method's shape; `markMetadataSyncTerminal` parks the row outside the
  queue for a refusal that was never about the budget (403/409) and spends
  the whole budget to match, so nothing downstream reads a retired row as
  still having attempts left. See
  [/lib/features/sync/docs.md](../../../sync/docs.md) for the drain and the
  error taxonomy that decides which of these each outcome calls.
- `deleteRecordingsByIds(ids)` (ENG-407) is a single `DELETE ... WHERE id IN
  (...)` statement, returning `0` without touching the database on an empty
  list. `SyncNotifier.clearLocalCache`
  ([../../../sync/docs.md](../../../sync/docs.md)) is the sole caller: it
  filters the local rows down to the subset `serverHasRecording`
  ([../../domain/docs.md](../../domain/docs.md)) says the server already has
  **and** that owes no unsent metadata edit (ENG-416), then deletes exactly
  those rows in one pass. It replaced
  `deleteAllRecordings` (a bare `DELETE` over the whole table), which had
  exactly one caller — the pre-ENG-407 cache clear, which deleted every row
  regardless of upload status — and was removed once that caller started
  filtering first. A per-row `deleteRecording` loop was rejected in favor of
  the single `IN (...)` statement, so a cache clear is one pass over the table
  and the row set either goes or stays as a unit. Partial failure is handled
  one level up instead: the caller passes only the ids whose *file* it managed
  to delete, so a row whose file survived survives with it rather than being
  orphaned.
- Lifecycle helpers: `markAsUploading`, `markAsUploaded(id, serverId,
  gcsUrl)`, `markAsFailed`, `resetRetryCount`, `resetStuckUploading`, and
  `normalizeExhaustedUploads`. These mutate only upload-state columns; they
  never touch user-content metadata, which is the contract that makes the
  offline-edit story safe. `markAsFailed(id)` records one failed attempt **and
  owns the retry ceiling** (ENG-377): it re-reads the row, increments
  `retryCount`, and writes `failed_exhausted` instead of `failed` when the new
  count reaches `kMaxUploadRetries`. It takes no `incrementRetry` flag — that
  branch existed for the missing-file case, which now writes its own terminal
  status. `resetStuckUploading` is the startup crash-recovery
  helper: it flips every row orphaned in `uploading` back to `local`,
  rewriting **only** `uploadStatus` so `retryCount`, `lastRetryAt`,
  `resumableSessionUri`, `serverId`, and `uploadedBytes` survive and the
  upload resumes from its saved offset. `normalizeExhaustedUploads()`
  (ENG-377) is its sibling startup fix: one `UPDATE` that
  retires every row still at (`uploadStatus: 'failed'`, `retryCount >=
  kMaxUploadRetries`) to `failed_exhausted`, so devices that already carry rows
  stuck in the old shape get healed, not just recordings created after the
  writer fix. Both are called once from
  [/lib/main.dart](../../../../main.dart), back to back, before the sync
  queue goes live — see Things to Know and
  [/lib/features/sync/docs.md](../../../sync/docs.md).
- `RecordingApiRepositoryImpl` translates between HTTP and the
  `ServerRecording` DTO from
  [../../domain/entities/server_recording.dart](../../domain/entities/server_recording.dart).
  Auth is supplied by `AuthenticatedClient` from
  [/lib/core/network/authenticated_client.dart](../../../../core/network/authenticated_client.dart).
  Its `updateRecording(serverId, request)` is the `PATCH /api/oc/recordings/{id}`
  partial update: as of ENG-205 the body comes from the request object's
  `toJson()` rather than being assembled inline from thirteen named parameters,
  but the wire payload, `guardResponse`, the 403→`ForbiddenException`, and the
  `statusCode == 200` return are all unchanged. **A 409 throws
  `ConflictException` (ENG-71)** instead of falling through to that boolean:
  the backend deduplicates on `(project_id, title)`, and a bare `false` is
  indistinguishable from any other failure, so `saveRecordingTitle` used to
  write the refused title into the local row and report success — device and
  server silently diverging. The body shape now lives on
  [`UpdateRecordingRequest`](../../domain/entities/update_recording_request.dart)
  (the rationale and the genre `GenreUpdate` precedent are in
  [../../domain/docs.md](../../domain/docs.md)). The
  [`saveRecordingTitle`](../use_cases/save_recording_title.dart) use-case and
  `RecordingDetailNotifier`
  ([../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  are the callers, each wrapping its update fields in the request object.
- `RecordingSessionRepository` manages the `recording_sessions` Drift
  table used by the segmented recorder for crash recovery (ENG-49/ENG-51).
  `completeWithFinalizedAudio(sessionId, {filePath, durationSeconds})`
  (ENG-420, slice 1) and its slice-2 sibling
  `recoverWithFinalizedAudio(sessionId, {filePath, durationSeconds})` both
  write the two anchor columns
  [added in schema v14](../../../../core/database/docs.md) —
  `finalizedAudioPath`/`finalizedDurationSeconds` — onto a session row and
  only then set its status (`completed` and `recovered` respectively), by
  delegating to a shared private `_anchorThen(sessionId, filePath,
  durationSeconds, status)`. `findFinishedSessions()` (ENG-420, slice 2)
  replaced `findCompletedSessions()`: it matches `status IN ('completed',
  'recovered')`, because both statuses can be reached with real finalized
  audio the sweep needs to consider (see Things to Know).

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
  every field verbatim from the in-memory `LocalRecordingEntity` (minus the
  dropped `lastRetryAt`/`md5Hash`). Choosing the right helper at the call site
  matters.
- **The typed writes' null handling is load-bearing and deliberately NOT
  unified (ENG-194).** Drift's `Value(null)` writes a literal SQL `NULL`
  (clears the column) while `Value.absent()` omits the column from the
  `UPDATE` (preserves whatever is stored). The typed writes encode the
  distinction the inline companions used to:
  - `classify` omits a null `registerId` (`Value.absent`, **preserve**) — a
    classify dialog that left the register blank must keep an existing
    register, not wipe it. A characterization test asserts exactly this.
  - `moveCategory` (when `clearSecondary` is true) and
    `updateSecondaryClassification` write the secondary fields as `Value(null)`
    (**clear**) — these flows intend to drop the secondary classification.
  - `setStoryteller` maps a `null` storyteller to `Value(null)` (clear) and a
    present one to `Value(it)`.

  Folding these into one "null means absent" (or one "null means clear") rule
  would silently break either the preserve case or the clear case. The choice
  lives in the repository now precisely so it is one auditable place, not
  re-derived at each presentation call site.
- **`completeWithFinalizedAudio`/`recoverWithFinalizedAudio` anchor before they
  change status, which is why each is one method (ENG-420, slice 1).** Before
  this, a session was marked `completed` the instant the finalized audio
  existed on disk, with nothing in the database recording where that file
  was. A crash in that window left a finished recording nothing pointed at.
  The callers (`RecordingSessionNotifier._stopNative`, on both its normal-stop
  and resume-then-stop branches, and `InterruptedSessionsNotifier.confirmRecovery`
  — see [../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  now anchor the row to the file first and flip its status second, so a
  `completed` or `recovered` row can never exist without a pointer to its
  artifact. The column is a **pointer, not a guarantee of existence**: nothing
  here checks the file is still on disk, before or after the write, and a
  reader must stat it itself. Two ordinary paths leave a stale anchor behind,
  and neither clears it: discarding from the save form deletes the finalized
  audio while the session row keeps pointing at it, and the sweep below flips
  a row from `completed`/`recovered` back to `crashed` with the anchor
  intact — so `crashed` does **not** imply "never anchored". `null` means
  "never anchored" — every session that predates schema v14, and any session
  that never reached a successful finalize. The v13→v14 migration does no
  back-fill; guessing which on-disk file belongs to which old session row
  would be a heuristic with real risk of pointing at the wrong audio.
- **The column got its first reader in slice 2: the startup sweep decides by
  the database, not by a race against fire-and-forget file deletes
  (ENG-420, slice 2).**
  [`RecoveryCoordinator._sweepFinishedSessionsWithUnsavedAudio`](../services/recovery_coordinator.dart)
  (renamed from `_sweepCompletedWithOrphanSegments`) now asks
  `findFinishedSessions()` for every `completed`/`recovered` row with no
  matching `LocalRecording`, and for each one its private `_hasUnsavedAudio`
  checks the row's anchor: if `finalizedAudioPath` is set, the answer is a
  plain `File(anchor).exists()` stat. This replaced a predicate that scanned
  the segments directory for files matching the session's id — a predicate
  that raced `RecordingFinalizationService.finalize`'s `unawaited` deletion of
  the source segments it just concatenated, so the same finished session could
  read as "has orphan segments" or not depending purely on scheduling, with no
  observable difference in outcome. The old substring scan was **not**
  removed — it is the fallback for every row with no anchor
  (`_hasUnsavedAudio` falls through to it only when `anchor == null`),
  whatever its status. Two populations land there, and neither is only
  historical: rows written before schema v14, and rows that reached a finished
  status *before* finalization ran — `recoverSessionFromDisk` marks a session
  `recovered` up front, so being killed during an 18-minute concat leaves a
  `recovered` row with no anchor and every segment still on disk. Restricting
  the fallback to `completed` would make exactly that session invisible
  forever. It can be deleted once no supported upgrade path can still be
  carrying a pre-v14 row and no path marks a session finished before it has
  audio.
  The anchor check is not a bare `File(anchor).exists()` either: it falls back
  to the same basename under the current documents directory, for the reason
  [`resolveRecordingPath`](../services/audio_path_resolver.dart) exists — the
  container moves on reinstall/restore, and reading a stored absolute path
  literally would declare live recordings audio-less.
- **Accepting a recovery prefers the finished file and only then falls back to
  the sources (ENG-420, slice 3).** `InterruptedSessionsNotifier.save` asks two
  questions in order. First: does the row name finalized audio that is still on
  disk? If so that file *is* the answer — it is handed over as-is, with the
  anchored duration, and nothing is reconcatenated. Only if there is no anchor,
  or the anchor names a file that is gone, does it fall back to re-finalizing
  from the surviving segments, which is the path that has always existed.
  Both halves are load-bearing and neither can be dropped:
  - Preferring the anchor is what makes the offer useful at all. The sessions
    the sweep newly surfaces are precisely the ones whose sources the
    fire-and-forget deletions already removed, so re-deriving has nothing to
    work from. It also saves reconcatenating minutes of audio into the same
    bytes for the sessions that *do* still have their sources.
  - Falling back to the sources is right whenever the finished file is missing
    or was never produced — a finalization that failed leaves the sources as
    the only real audio, and the anchor is a pointer, not a guarantee (it
    survives the user discarding from the save form, which deletes the file and
    never touches the row). The anchor is resolved through the same basename
    lookup `resolveRecordingPath` uses, so a stale absolute path from a moved
    iOS container still finds its file.
  **A session still holding finalized audio is never marked `discarded`.**
  `discarded` appears in no sweep query — neither `findFinishedSessions` nor
  `findCrashedSessions` — so a row that reaches it can never be surfaced again.
  Both paths that give up (`InterruptedSessionsNotifier.save` when neither the
  anchor nor a segment yields audio, and `RecoveryCoordinator.refresh` when a
  crashed row has no segments) skip the terminal write while
  `finalizedAudioPath` is set. That guard is still reachable after slice 3:
  it is what catches a row whose anchor names a deleted file and whose sources
  are gone too. The invariant is "a session that still points at a durable
  artifact never reaches a state no sweep looks at". A deliberate discard is
  the one intended way out, and it deletes the anchored file first.
- **The anchored duration overstates the audio on the degraded path.** When
  both concat routes fail, `RecordingFinalizationService` returns the whole
  session's duration alongside a `filePath` that is only the first segment, so
  `finalizedDurationSeconds` describes a recording longer than the file it
  names. `LocalRecordings` has carried the same overstatement since before
  these slices, and slice 3 inherits it: a recovery served from the anchor
  reports `finalizedDurationSeconds`. Re-deriving reports the same number from
  `totalDurationSeconds`, so this is not a cost of preferring the anchor — it
  is the pre-existing overstatement, now reached one step earlier.
- **`splitRecordingReplacingParent` is atomic (ENG-125).** The trim/split save
  must end with the children present and the parent gone. Doing those as two
  statements (insert in a transaction, then delete) left a failure window where
  a crash between them orphaned the children AND left the parent — both then
  appeared in the queue. `splitRecordingReplacingParent` folds both writes into
  a single transaction so a throw rolls back the children too.
- **`saveRecording`'s mapper omits the DB-managed columns on purpose (ENG-201).**
  `localRecordingEntityToCompanion` leaves `createdAt`, `retryCount`,
  `uploadedBytes`, and `cleaningStatus` absent so the Drift defaults win on
  insert — most importantly so `createdAt` is the DB clock (the true enqueue
  time the pending-upload order depends on), not an app-side timestamp the entity
  happens to carry. A `LocalRecordingEntity` is non-nullable for those fields, so
  the confirmation flow has to pass *something*; the mapper drops it rather than
  let it overwrite the DB clock/counters. A characterization test builds an entity
  with bogus values for all four and asserts the persisted row still carries the
  defaults.
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
  resumes rather than restarts. It has to move the row out of `uploading` at
  all because the sync engine's own eligibility filter skips that status (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)) — a row left there
  would never be re-dispatched. It targets `local`, not `failed`: `failed` is
  the status `requeueFailedUploads`/`hasRetryableFailedUploads` (ENG-404, see
  Things to Know and [../../domain/docs.md](../../domain/docs.md)) treat as a
  retryable failure, and a crash mid-transfer is not one — landing on `failed`
  would expose a resumable row to the bulk retry, which would reset the very
  budget and backoff state this method preserves. Because it matches only
  `uploading` (a native-only status;
  web uses `web_uploading`), it is a no-op on web. The drain's complementary
  exclusion of `uploading` rows and the startup invocation order live in
  [/lib/features/sync/docs.md](../../../sync/docs.md).
- **The retry ceiling is decided inside `markAsFailed`, not by its caller
  (ENG-377).** The sync engine used to read the row, add one, and pick
  between `markAsFailed` and a terminal write itself. That only worked when
  the engine had got far enough to read the row: a failure raised earlier —
  the platform-channel call inside `_resolveFilePath`, the `updateRecording`
  that rewrites a relocated path, the `getRecordingById` itself — reached the
  decision with no row in hand, counted from zero, and chose `markAsFailed`,
  which then incremented from the **database** value. A row at `retryCount: 4`
  came out as (`failed`, 5): the exact stuck shape ENG-377 exists to remove.
  Moving the decision here removes the category rather than patching the
  paths, because this is the method that already re-reads the count. `failed`
  now means "a retry is still coming" no matter what threw or where.
- **`normalizeExhaustedUploads` is a one-time data fix, run on every
  launch, not a schema migration (ENG-377).** Before ENG-377 the writers
  wrote a spent retry budget as `(uploadStatus: 'failed', retryCount:
  kMaxUploadRetries)` — a shape `getPendingUploads` still calls pending and the
  sync engine's own eligibility filter refuses, so the row sat in the badge
  count forever with nothing able to move it. Fixing the writers (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)) stops new rows from
  taking that shape but does nothing for rows already in it, so this method
  sweeps them to `failed_exhausted` at every startup. The ceiling comes from
  `kMaxUploadRetries` in
  [/lib/core/config/upload_retry_policy.dart](../../../../core/config/upload_retry_policy.dart),
  the one place the engine and this repository both read it from, so the
  sweep's filter and the writer's decision cannot drift apart.
  Nothing about the table changes — only rows an older build left behind —
  which is why this is a normal `UPDATE` rather than a Drift schema step;
  see [/lib/core/database/docs.md](../../../../core/database/docs.md) for
  the schema-migration path this deliberately is not.
- **`requeueFailedUploads` targets `failed`/`failed_exhausted` because those
  are the only two failures a bare retry can still resolve (ENG-404).** The
  other three terminal statuses — `failed_conflict`, `failed_description`,
  `failed_missing_file` — would be refused identically on the next attempt: a
  duplicate title, a description under the minimum, or no audio file at all.
  Each already has its own banner routing to its own fix (rename, edit the
  description; there is no fix for a missing file but delete). Requeueing
  them would only spend the user's tap on a request the server is going to
  reject the same way. This is exactly what
  `isRetryableFailure`/`hasRetryableFailedUploads` in
  [../../domain/upload_status_actions.dart](../../domain/upload_status_actions.dart)
  (see [../../domain/docs.md](../../domain/docs.md)) encode, so the list's
  bulk-retry button never appears over a row this write will not touch.
- **One `UPDATE`, not a loop over `resetAndRetry` (ENG-404).** The per-row
  alternative, `SyncNotifier.resetAndRetry`, ends in `syncOne`, which takes
  the same `_isProcessing` guard `processQueue` does (see
  [/lib/features/sync/docs.md](../../../sync/docs.md)) — whichever call
  arrives first wins the guard and every other call returns immediately, so
  calling `resetAndRetry` in a loop over N failed rows would fan out N passes
  against a guard built to admit exactly one, and silently drop the rest.
  `requeueFailedUploads` instead writes every matching row in the project
  with a single `UPDATE`; the caller
  (`RecordingsListNotifier.retryFailedUploads`, see
  [../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md))
  then calls `processQueue()` once for the batch rather than N times. One
  call is the whole claim — it is **not** a promise that the batch drains.
  The same guard applies to this call: if a pass is already in flight it
  returns immediately, and that pass read its `getPendingUploads()` snapshot
  before the `UPDATE`, so the requeued rows wait for the next trigger (a
  later `processQueue`, the offline→online transition, app start). That is
  acceptable because the requeue is what the action actually promises — the
  rows are queued and eligible from the moment the `UPDATE` commits, and the
  drain finds them whenever it next runs.
- **The write touches three columns because the status alone would leave a
  row queued but refused.** `uploadStatus: 'local'` on its own is not
  enough: a stale `retryCount` is still the exhausted budget
  `processQueue`'s eligibility filter checks against, and a stale
  `lastRetryAt` still falls inside the backoff window that same filter
  enforces (see [/lib/features/sync/docs.md](../../../sync/docs.md)).
  `requeueFailedUploads` resets `retryCount` to `0` and `lastRetryAt` to
  `null` in the same write, so the row is immediately eligible rather than
  just relabeled.
- **The action no longer shrinks the home screen's total (ENG-404).** The
  hard delete this replaced removed the row, so the total dropped every
  time it ran. The requeue only rewrites `uploadStatus`/`retryCount`/
  `lastRetryAt` — the row still exists and still satisfies
  `getLocalOnlyStats`'s `uploadStatus NOT IN ('uploaded', 'verified')`
  predicate before and after — so the home screen's count does not move
  when the user retries a batch of failures. This is the correct
  consequence of no longer destroying the row, not a regression; see
  [/lib/features/home/presentation/notifiers/docs.md](../../../home/presentation/notifiers/docs.md).
- **`/api/oc/recordings/clear-stale` is now an orphaned endpoint (ENG-404).**
  `RecordingApiRepository.clearStaleRecordings` and its implementation were
  deleted along with the hard-delete flow that was their only caller. The
  route itself was not removed from the server — anyone changing the backend
  should not assume it is dead on both sides, only that nothing in this app
  calls it anymore.
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
- **`watchRecordingEntityById` maps before `.distinct()`, so dedup keys on the
  entity, not the row (ENG-195; sole detail stream since ENG-199/ENG-200).** The
  former row stream `watchRecordingById` — which dedup'd on Drift's generated
  row equality and existed only to collapse table-level re-emissions — was
  deleted once the detail tree moved to the entity; this is now the only watch
  stream. It dedups on `LocalRecordingEntity`'s hand-written `==`, and because
  the entity drops `lastRetryAt`/`md5Hash`, a write that touches only those is
  invisible to it by design — so a pure upload-bookkeeping write no longer
  re-renders the detail screen. This is the reason the entity needs value
  equality at all: without it, mapping to a fresh object per emission would
  defeat `.distinct()` entirely. `.distinct()` still only collapses re-emissions;
  the query itself re-executes on every `local_recordings` write (table-level
  invalidation is inherent to Drift).
- **`cacheDownloadedAudio` only writes `reviewFlags` on the insert branch
  (ENG-374).** The update branch touches only `localFilePath` by design (see
  above), so a device that made and already uploaded a recording — and
  therefore already has a local row — never gets that column refreshed here;
  its `reviewFlagsJson` stays at the `'[]'` default regardless of what the
  server reports later. Writing flags on the update branch, and clearing a
  flag once the user fixes what it names, are both left to the UI-facing
  follow-up PRs — nothing in this repository invalidates a stale flag today.
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
