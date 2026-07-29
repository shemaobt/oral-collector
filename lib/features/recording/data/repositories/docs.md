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
    (`splitRecordingReplacingParent`, ENG-193), and `RecordingsListNotifier`
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
  `countRecordings`/`totalDuration`/`getLocalUnclassifiedStats`.
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
  `failed_conflict` (ENG-71) is deliberately absent from the matched set: a
  duplicate title is terminal until the user renames the recording, and the
  rename routes through `resetRetryCount`, which flips the row back to `local`
  and so back into this query.
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
  path gave, restated over the entity's fields.
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
- `deleteRecording(id)` is a plain physical row delete (a single Drift
  `delete().go()`); there is no tombstone column. It only removes the
  Drift row — it does **not** delete the audio file or call the server.
  The user-initiated hard-delete flow that combines the remote delete, this
  row delete, and the physical audio-file delete is orchestrated by
  `RecordingsListNotifier.deleteRecording` (ENG-120), not here — see
  [../../presentation/notifiers/docs.md](../../presentation/notifiers/docs.md).
  `deleteStaleRecordings(projectId)` is the separate user-triggered "clear
  stale" sweep that bulk-deletes `failed` and `uploading` rows for a project.
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
