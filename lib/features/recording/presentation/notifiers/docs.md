# Noridoc: Recording Presentation Notifiers

Path: @/lib/features/recording/presentation/notifiers

### Overview

- Riverpod notifiers that own the long-lived state for the recording
  feature's screens: the recording session (segmented capture), the
  recordings list (paginated server + local merge), input device
  selection, interrupted-session recovery prompts, the detail screen's
  audio playback, and the trim editor's editing + split-persist
  orchestration.
- Notifiers in this folder hold resources that must survive widget
  rebuilds — the active `Record` instance, the `AudioPlayer` for
  playback, paginator cursors, and crash-recovery state. The detail
  screen's `LayoutBuilder` swaps subtrees on rotation, so anything that
  must persist across that swap lives here, not in widget `State`.
- The trim editor's notifier is the other reason to be here: extracting
  the editing state and the split/save orchestration out of the screen
  isolates that logic so it can be unit-tested headlessly (ENG-193), and
  keeps the split commit alive even if the screen unmounts mid-save.
- `RecordingDetailNotifier` (ENG-194) is the same extraction applied to the
  detail screen — the app's largest, critical-path screen: it owns the
  multi-step load orchestration and all the metadata/audio mutations, so the
  screen at [../recording_detail_screen.dart](../recording_detail_screen.dart)
  is a thin consumer that only shows dialogs/sheets/snackbars and forwards to
  notifier methods.
- All providers are registered at the top of their respective notifier
  files and consumed from [/lib/features/recording/presentation/](../)
  screens and widgets.

### How it fits into the larger codebase

- Notifiers depend on the recording data layer at
  [../../data/](../../data/) — repositories via
  [../../data/providers.dart](../../data/providers.dart), the segmented
  recorder, recovery & finalization services, and the audio path
  resolver under
  [../../data/services/](../../data/services/).
- Cross-feature reads: sync state from
  [/lib/features/sync/presentation/notifiers/sync_notifier.dart](../../../sync/presentation/notifiers/sync_notifier.dart),
  project membership from
  [/lib/features/project/](../../../project/), and locale/auth providers
  from `/lib/core/`.
- Consumers: the recording screens and widgets in
  [../](../) and [../widgets/](../widgets/) read these notifiers via
  `ref.watch` / `ref.read`. The detail screen specifically calls
  `recordingPlayerProvider(id).notifier.load(...)` after a recording
  loads, so the player is hydrated by the screen but owned by the
  provider tree.
- The `RecordingPlayerNotifier` mirrors the long-standing pattern used
  by `RecordingSessionNotifier` for the audio recorder: native
  resources (the `Record` for capture, the `AudioPlayer` for playback)
  live outside the widget tree so they cannot be torn down by widget
  rebuilds.
- `TrimEditorNotifier` is **headless** — it holds no `BuildContext` and
  does no navigation or snackbars. It depends on the recording data
  layer through injectable seams under
  [../../data/services/](../../data/services/) (the per-segment ffmpeg
  exporter and the split persister factory) plus `fileExistsProvider` /
  `waveformLoaderProvider` in [../../data/](../../data/), reads sync
  state from
  [/lib/features/sync/presentation/notifiers/sync_notifier.dart](../../../sync/presentation/notifiers/sync_notifier.dart)
  to kick the upload queue, and returns a result type the screen acts on
  (see Core Implementation). The seams exist so the device-bound IO is
  driveable on the host in tests — they are documented under "the trim
  editor's injectable seams" in [../../data/docs.md](../../data/docs.md).
- `RecordingDetailNotifier` is **headless** for the same reason: no
  `BuildContext`, no navigation, no snackbars. Its metadata mutations return a
  `RecordingMutationResult { success, savedLocallyOnly, failed, forbidden,
  titleConflict }` the widget maps to a localized snackbar (see Core
  Implementation). Its writes go through typed
  repository methods on
  [../../data/repositories/local_recording_repository.dart](../../data/repositories/local_recording_repository.dart)
  (`setStoryteller`, `classify`, `moveCategory`, …) and through the
  `RecordingApiRepository`; its device-bound IO (GCS download, file import)
  lives behind injectable seams in
  [../../data/services/](../../data/services/) — documented under "the detail
  screen's injectable IO seams" in [../../data/docs.md](../../data/docs.md).
  It reads sync/role/member/storyteller/stats notifiers across the project to
  reproduce the screen's load and refresh behavior.

### Core Implementation

- `RecordingSessionNotifier` (in `recording_session_notifier.dart`) is
  the top-level controller for the segmented capture flow. It owns the
  microphone, runs the segmenter from
  [../../data/services/segmented_recorder.dart](../../data/services/segmented_recorder.dart),
  drives the foreground service / live activity, and reconciles crash
  recovery via the services at
  [../../data/services/](../../data/services/). Its 1 Hz elapsed-timer tick
  pushes the foreground-service notification and the iOS Live Activity through
  two `SingleFlightRunner` instances (`single_flight_runner.dart`) rather than
  bare `unawaited(...)` calls — see Things to Know.
- `RecordingPlayerNotifier` (`recording_player_notifier.dart`) is an
  `AutoDisposeFamilyNotifier<RecordingPlayerState, String>` keyed by
  recording id. Its `build(arg)` creates a `just_audio` `AudioPlayer`
  through `audioPlayerFactoryProvider` and registers an `onDispose`
  that releases the player and flags the notifier disposed (see Things
  to Know). The player is held in a private `_player` field and handed
  to the widget via an `audioPlayer()` **method**, not a public field:
  `riverpod_lint`'s `avoid_public_notifier_properties` flags any public
  instance field/getter on a notifier, but not methods (see Things to
  Know). Callers obtain the long-lived player via
  `ref.read(recordingPlayerProvider(id).notifier).audioPlayer()` and use
  the notifier's `load` / `togglePlay` / `seek` / `stop` methods. State is
  the immutable `RecordingPlayerState` in `recording_player_state.dart`
  (`isLoading`, `errorKind`, `hasAudio`); the error kind is one of
  `fileNotFound` (local missing and no fallback URL) or `loadFailed`
  (decoder/network error).
- `RecordingDetailNotifier` (`recording_detail_notifier.dart`) is an
  `AutoDisposeFamilyNotifier<RecordingDetailState, String>` keyed by recording
  id (`recordingDetailProvider`), mirroring `TrimEditorNotifier`. State is the
  immutable `RecordingDetailState` (`recording_detail_state.dart`): the resolved
  recording as a `LocalRecordingEntity` (the row→entity swap landed in
  ENG-199/ENG-200 / F5a, completing the detail tree migration —
  [../recording_detail_screen.dart](../recording_detail_screen.dart) and the
  child section widgets type their `recording` as the entity too), an
  `isLoading` flag, and the `resolvedStoryteller`. The notifier owns:
  - **Load orchestration** (`load`), reproducing the screen's old
    `_loadRecording`. The resolution stays **row-typed internally** because the
    heal path and the server fallback still operate on rows: native resolves a
    `LocalRecording` local-by-id → local-by-server-id, then (online, when the row
    has a serverId but is missing `gcsUrl`/`userId`) heals it via
    `buildHealMetadataCompanion`
    ([../../data/recording_heal_companion.dart](../../data/recording_heal_companion.dart)),
    then (online, still no row) falls back to a server fetch mapped through
    `serverRecordingToLocal`; web always fetches the server DTO. Since ENG-45,
    if that heal call 404s for a row that `serverHasRecording`
    ([../../domain/server_deletion_policy.dart](../../domain/server_deletion_policy.dart))
    accepts, the row and its audio file are erased and the server-fallback
    fetch above is skipped for this load — asking again would only re-confirm
    what the 404 already proved. The heal branch is reachable even for a row
    that never finished uploading, because `_needsUserRefresh` (unlike
    `_needsGcsRefresh`) does not check `uploadStatus`: there is a real window
    where a row has a `serverId` but is still `uploading`/`failed` (the id is
    written before `markAsUploaded`), and `serverHasRecording`'s status
    check is what keeps a stray 404 in that window from erasing it. The resolved row
    is mapped to the entity **exactly once at the state boundary** via
    `localRecordingToEntity`
    ([../../data/local_recording_to_entity.dart](../../data/local_recording_to_entity.dart)),
    so the entity is the only recording type that leaves the notifier — every
    mutation/IO method (`setStoryteller`, `saveDetails`, `toggleCleaningStatus`,
    `moveCategory`, `classify`, `saveSecondary`, `downloadAndCache`,
    `downloadForExport`, `replaceAudio`) and the private `_resolveStoryteller`
    take a `LocalRecordingEntity`. After the row lands it fetches the project
    role, resolves the storyteller (local cache then, online, the API), and warms
    the member cache. The post-fetch role and member steps end with an empty
    `copyWith()` so the widget re-reads role-derived permissions — the original
    screen's empty `setState`.
  - **The `localRecordingStreamProvider` listen** (native only), registered in
    `build`: the stream now carries `AsyncValue<LocalRecordingEntity?>`
    (ENG-199/ENG-200), and when it emits it patches an already-loaded recording
    into `state` (it does not seed the initial load), keeping the displayed
    entity fresh on sync/heal writes. This is the listen the detail screen used
    to own. Because the stream maps to the entity **before** its `.distinct()`
    (see [../../data/repositories/docs.md](../../data/repositories/docs.md)), a
    DB write that touches only the persistence-only columns the entity drops
    (`lastRetryAt`/`md5Hash`) is value-equal and never re-emits here, so the
    detail screen stops rebuilding on upload-bookkeeping churn.
  - **Metadata mutations** — `setStoryteller`, `saveDetails` (title via the
    `saveRecordingTitle` use-case, description via the typed repo write),
    `toggleCleaningStatus`, `moveCategory`, `classify`, `saveSecondary` — each
    calls the server first, mirrors to Drift through a typed
    `LocalRecordingRepository` write (native only), refreshes genre stats /
    kicks the sync queue where the screen did, then `await load()`s.
    `toggleCleaningStatus`/`moveCategory`/`classify`/`saveSecondary` (ENG-399)
    route the server call through the shared `_pushMetadata`/`_refusal` pair,
    which classifies the outcome as accepted, rejected (a non-200 response, or
    403 → `ForbiddenException`), or unreachable (offline, or any other thrown
    exception, except on web where a thrown exception is treated as rejected —
    there is no local row to fall back to) rather than collapsing every
    failure into one `failed`. A rejection still leaves the local row alone; an
    unreachable server mirrors the edit to Drift anyway and the method returns
    `RecordingMutationResult.savedLocallyOnly` instead of `success`. See the
    "Online-first" bullet in [../docs.md](../docs.md) for the full
    accepted/rejected/unreachable contract, why each method keeps its own
    (deliberately inconsistent) gate for whether the edit is owed to the
    server at all, and how the metadata outbox (ENG-403, below) resends a
    `savedLocallyOnly` edit once the connection returns. `saveDetails`
    gets the same fallback through the ENG-380 use-cases
    (`saveRecordingTitle`/`saveRecordingDescription` — see
    [../../data/docs.md](../../data/docs.md)) rather than `_pushMetadata`
    directly, since it does not call `updateRecording` itself; it tracks a
    single `localOnly` flag across the title and description halves — either
    one landing local-only makes the whole edit `savedLocallyOnly` — and binds
    both use-case results before returning, which a prior revision of this
    method did not do for the description half (a bug fixed by ENG-399, not a
    behavior this doc is describing as new). The four
    that can fail visibly (`toggleCleaningStatus`/`moveCategory`/`classify`/
    `saveSecondary`, plus `saveDetails`) return `RecordingMutationResult` so the
    widget picks the snackbar (see Things to Know). `titleConflict` comes only
    from `saveDetails`: the 409 the backend raises for a title already used in
    the project (ENG-71). Nothing is written when it fires, so the row keeps its
    old title and its `failed_conflict` status, and the rename banner stays up
    for another attempt. The other handlers treat it as a plain failure because
    only a title edit can produce it. `saveDetails` owns the symmetric exit for
    `failed_description` (ENG-354): after the description write it calls
    `resetAndRetry` when the row was parked there, so a lengthened description
    puts the recording back in the queue instead of leaving it stuck. Unlike the
    rename there is no server-side second refusal to guard against — the
    description is only sent at create time — so the requeue is unconditional.
  - **Each of the five metadata-mutation entry points also settles the
    metadata outbox (ENG-403), through the shared `_settleOutbox` helper.**
    `saveDetails` calls it once for `title` and once for `description`, right
    after each half's write; `toggleCleaningStatus` gates it behind the same
    `serverKnown` (`uploadStatus` in `{'uploaded', 'verified'}`) check that
    decides whether to call the server at all; `classify`/`saveSecondary`
    gate it behind `hasServerId`, matching the gate that decides whether
    *they* call the server. `moveCategory` is the odd one: it calls the
    server unconditionally, without checking for a server copy first (see
    [../../domain/docs.md](../../domain/docs.md)), so its outbox gate is new
    and different from the rest — a non-empty `serverId` check that exists
    purely to keep a recording the server has never seen from being marked
    pending in a queue that only drains rows with a `serverId`
    ([/lib/features/sync/docs.md](../../../sync/docs.md)); without it, that
    pendency would sit forever, filtered out of every pass. `_settleOutbox`
    marks the fields pending on the `savedLocallyOnly` branch and clears them
    (a no-op if nothing was owed) once the write reaches the server, through
    `LocalRecordingRepository.markMetadataPending`/`clearPendingMetadataFields`
    ([../../data/repositories/docs.md](../../data/repositories/docs.md)), so
    an edit that finally lands also clears whatever an earlier offline edit
    to the same field left owed. `setStoryteller` does not call
    `_settleOutbox` at all — its own error handling swallows every exception
    without telling "unreachable" apart from "refused", so it cannot decide
    which case the outbox contract needs.
  - **Audio mutations** behind the IO seams: `downloadAndCache` (GCS download +
    `cacheDownloadedAudio`, throws on failure so the widget dismisses its
    progress dialog and shows the error), `downloadForExport` (temp download for
    share, throws), and `replaceAudio` (import the picked file, update the row,
    sync new metadata + `resetAndRetry` when the recording was uploaded;
    returns `false` on failure).
- `TrimEditorNotifier` (`trim_editor_notifier.dart`) is a
  `NotifierProvider.autoDispose.family<…, String>` keyed by recording id
  (`trimEditorProvider`). State is the immutable `TrimEditorState`
  (`trim_editor_state.dart`), which holds the editing fields (split
  points, excluded segments, per-segment taxonomy, gain, the resolved
  recording as a `LocalRecordingEntity`, load flags) plus the pure
  derivations the screen used to compute inline as getters — segment
  boundaries/timing, the effective taxonomy, and the save `decision`
  (`TrimEditDecision` from
  [../trim_edit_decision.dart](../trim_edit_decision.dart)). As of ENG-202 the
  notifier holds **zero** Drift row type: the editing state, the load path, and
  the split/save chain all deal in the domain `LocalRecordingEntity` — ENG-198
  migrated the write side and ENG-202 closed the last leak by moving the load's
  row→entity mapping out of the notifier and into the data layer (see the
  entity-boundary bullet). The notifier owns:
  - **Load resolution** of the recording (`load`): it resolves a
    `LocalRecordingEntity` directly — web fetches the server DTO and maps it via
    `serverRecordingToEntity`
    ([../../data/server_to_recording_entity.dart](../../data/server_to_recording_entity.dart));
    native tries `getRecordingEntityById`, then `getRecordingEntityByServerId`
    ([../../data/repositories/docs.md](../../data/repositories/docs.md)), then an
    online fetch via `serverRecordingToEntity`. The fetch order, the null
    fall-through, and the `_disposed` guards are unchanged from the row version
    (ENG-193); only the row→entity projection moved into `data/`. A caught server
    error is "not found" only for a genuine 404 (`isRecordingNotFound` in
    [../trim_load_error.dart](../trim_load_error.dart)); anything else is stored
    as a real `loadError`. The deliberate split: a resolved recording leaves
    `isLoading` **true** so the widget can finish the load (see the load-split
    bullet).
  - **Editing mutations**: `setSplitPoints` (re-derives boundaries and
    remaps per-segment taxonomy via the top-level `remapTaxonomyBySig`
    so a small edit keeps a segment's overrides while a re-split drops
    them), `toggleExclude` (returns `false` when the "at least one
    segment" guard blocks the exclusion so the widget surfaces the
    snackbar), `setSegmentTaxonomy`/`copyFromPrevious`, `setGain`,
    `clearAllSplits`/`restoreAllExcluded`.
  - **`saveSplit`**, which returns a sealed `TrimSaveOutcome`
    (`TrimSaveSucceeded` / `TrimSaveAborted` / `TrimSaveFailed`) so the
    **widget**, not the notifier, picks the snackbar and navigates. Its
    private `_saveServerSide` / `_saveLocally` take the
    `LocalRecordingEntity` straight off state. Web delegates to
    `RecordingApiRepository.splitRecording`; native exports each kept
    segment through the `LocalSegmentExporter` seam — wrapping the source
    path, the `SegmentExportSpec`s, gain, boost-only flag, title, and parent
    genre id in a single `ExportLocalSegmentsRequest` value object (ENG-209;
    see [../../data/docs.md](../../data/docs.md)) — and hands the resulting
    specs plus the entity `parent` to a `RecordingSplitPersister` built from
    `recordingSplitPersisterProvider` (the persister and the repository's
    `splitRecordingReplacingParent` consume the entity as the parent as of
    ENG-198 — see [../../data/repositories/docs.md](../../data/repositories/docs.md);
    see Things to Know for why every dependency is captured before the
    first `await`).
- `RecordingsListNotifier` (`recordings_list_notifier.dart`) owns the
  paginated list. As of ENG-197 the state holds `List<LocalRecordingEntity>`
  (see [./recordings_list_state.dart](recordings_list_state.dart)), not the
  Drift `LocalRecording` row: every row read from
  `LocalRecordingRepository.getAllRecordings` (its signature is unchanged — it
  still returns rows) is mapped through `localRecordingToEntity`
  ([../../data/local_recording_to_entity.dart](../../data/local_recording_to_entity.dart))
  at the notifier boundary, and `_convertServerRecordings` composes
  `serverRecordingToLocal` then `localRecordingToEntity` (server →
  in-memory row → entity) so the server and local sides land as the same
  type before merging. `fetchRecordings` loads page zero — the server list
  merged with local-only entities, deduped by `serverId` — and `loadMore`
  appends later pages from the `_serverOffset` cursor; offline or on an API
  error both fall back to the full local set (see the review-flag exception
  below). Since ENG-45 the list also reconciles a hard delete made
  on the server, and as of ENG-400 that reconciliation spans pagination and
  ends in a per-recording confirmation. A **sweep** is the union of the server
  ids seen across an unfiltered pass: `_fetchAndMerge` opens it with page zero
  (`_sweep`, stamped with its `projectId`; a filtered fetch opens none, and a
  fetch a newer one already superseded opens none either), each `loadMore`
  page joins it through `_advanceSweep`, and the last page — the one shorter
  than `_pageSize` (50) — closes it. Only then are the local rows absent from
  the union considered, and they are *candidates*, not verdicts: each is put
  through `serverHasRecording` (see
  [../../domain/docs.md](../../domain/docs.md)) and then confirmed with a
  direct `getRecording(serverId)`, and only a 404 — read with the shared
  `isRecordingNotFound` — erases the row and its audio file. Anything else the
  server says, including an unreachable one, leaves the row alone. The union
  decides *who gets asked about*, which is why the sweep still refuses to
  close mid-pagination, under a filter, on another project's pages, or on an
  empty first page: not because the answer would be unsafe (the confirmation
  handles that) but because each of those would put most of the project on
  trial and turn one listing into a request storm. `_advanceSweep` does not
  re-check the filters itself, and that rests on an invariant that lives in
  this class rather than in it: **every server-side filter setter
  (`setUserFilter`, `setStorytellerFilter`, `setReviewFlagFilter`,
  `clearAllFilters`) refetches**, and a fetch installs a fresh sweep — a
  filtered one installs none at all. Break that (a filter that mutates `state`
  without refetching) and a filtered pagination could close a sweep opened
  unfiltered; the cost is a storm of confirmations, not lost recordings, since
  each candidate is still confirmed individually. The confirmations themselves
  run through `mapBounded` (`_confirmDeletedConcurrency`) and are cut short by
  a generation change, so a refresh abandons the queued ones instead of waiting
  them out; the deletions they authorise stay serial. A project of 50 or more
  recordings now heals as the user pages to the end of the list, which is what
  ENG-400 fixed — before it, only a short first page reconciled and a large
  project never self-healed at all (see Things to Know). Status / genre /
  subcategory / search filtering is computed client-side by
  `RecordingsListState.filteredRecordings` (`StatusFilter.uploaded` matches
  `uploadStatus` in `{'uploaded', 'verified'}` (ENG-376), not just
  `'uploaded'` — a `verified` recording already shows the same
  `recording_statusUploaded` badge on its card, so excluding it from the
  `filter_uploaded` chip looked like a missing-recording bug rather than a
  filter bug; `unclassified` reads the entity's
  `isUnclassified` extension; `missingDescription`, added by ENG-354, negates
  `isDescriptionSufficient` from
  [../../../../shared/utils/recording_description.dart](../../../../shared/utils/recording_description.dart)
  — the same predicate the save gates use, so a recording the filter surfaces
  is exactly one the editor would reject; recordings predating ENG-354 keep
  their local row untouched, but they **cannot upload** until the description is
  fixed — the sync engine pre-flights the same predicate and parks them in
  `uploadStatus='failed_description'`, so this filter is how the user finds them
  and the detail banner is how they clear them) and never refetches, so only
  `setUserFilter`, `setStorytellerFilter`, `setReviewFlagFilter`,
  `clearAllFilters`, `retryFailedUploads`, and
  pull-to-refresh re-hit the server. `patchRecordingTitle` rerenders after an
  edit without a full refetch, using the entity's sentinel `copyWith(title: …)`
  rather than Drift's `Value(...)` wrapper.
- `setReviewFlagFilter(PendencyKind?)` (ENG-381) is the one narrowing filter
  that is **server-side**, unlike genre/status/subcategory/search: the API
  accepts exactly one `review_flag` code from the closed
  [`PendencyKind`](../../domain/entities/review_pendency.dart) enum and 422s on
  anything else, and there is no "has any pendency" filter to ask for — the
  headline pendency counter on
  [project settings](../../../project/presentation/project_settings_screen.dart)
  stays untappable for the same reason (see
  [../../../project/data/docs.md](../../../project/data/docs.md) for why the
  two review counters on that screen must never be summed as a substitute).
  Setting a flag routes through `_reviewFlagCode` into every `listRecordings`
  call (`fetchRecordings` and `loadMore`), and while it is set: local-only rows
  are excluded from the merge (the server's counts only cover
  `uploaded`/`verified` recordings, so a row that never left the device was
  never part of the number tapped), and the offline fallback returns an empty
  list instead of the device's local set (`_localFallback`) — the screen at
  [../recordings_list_screen.dart](../recordings_list_screen.dart) renders a
  dedicated "not available offline" empty state rather than either the full
  local set or the ordinary "no recordings" state. `refresh: false` lets the
  screen's `initState` apply the filter without double-fetching, since
  `_refreshAll` fetches immediately after.
- `RecordingsListState.fetchFailed` (ENG-381) records whether the last
  `fetchRecordings` ended in the `catch`. It exists because the local fallback
  returns the same empty list for "offline under a pendency filter" and "the
  request threw", which left the screen unable to tell *no recordings* from *I
  could not find out* — and it picked the reassuring one, painting "no
  recordings yet / 0 recordings" under a chip saying "No classification" on
  any 5xx, timeout or 401. Set in the `catch`, cleared on a successful fetch
  **and** on the offline branch (offline is a separate story the screen tells
  differently). `loadMore` deliberately does not touch it: a failed second
  page leaves the first page on screen and still a valid answer. Consumers:
  the empty state at
  [../recordings_list_screen.dart](../recordings_list_screen.dart) only.
- `deleteRecording(LocalRecordingEntity)` is the single owner of the
  user-initiated **hard delete** for both the list and detail screens
  (ENG-120). It takes the entity as of ENG-197: the list screen already holds
  entities, and the detail screen converts its Drift row at the call site via
  `localRecordingToEntity`
  ([../../data/local_recording_to_entity.dart](../../data/local_recording_to_entity.dart)).
  It deletes remotely via the recording API *only* when the
  row has a `serverId` (local-only rows skip the API), hard-deletes the
  Drift row through
  [../../data/repositories/local_recording_repository.dart](../../data/repositories/local_recording_repository.dart),
  best-effort deletes the physical audio file via
  [/lib/core/platform/file_ops.dart](../../../../core/platform/file_ops.dart)'s
  `deleteFile`, then optimistically removes the item from `state` (no
  refetch). It returns `DeleteRecordingResult { ok, forbidden, failed }`
  so the screen picks the snackbar without re-deriving it from an
  exception. See Things to Know for the web-orphan fix and the
  remote-failure semantics.
- `retryFailedUploads()` (ENG-404) is the bulk counterpart the recordings
  list offers over `failed`/`failed_exhausted` rows. It replaced a hard
  delete of the same set (the former `clearStaleRecordings`), which
  destroyed the only copy of audio the server had never received. It calls
  `LocalRecordingRepository.requeueFailedUploads` (one `UPDATE`; see
  [../../data/repositories/docs.md](../../data/repositories/docs.md) for the
  scope and batch-write rationale), fires `SyncNotifier.processQueue()`
  **unawaited** — the caller only needs the rows queued, not the uploads
  finished — and refetches. Unlike `deleteRecording`, there is no
  confirmation dialog and no online pre-check: requeueing destroys nothing
  and is idempotent, so a confirmation would only cost a second tap, and the
  write needs no network — the rows drain on their own once the device is
  back online. The visible consequence: the home screen's total no longer
  drops when the user runs this, because the row survives and still counts
  toward `getLocalOnlyStats` under its new status (see
  [/lib/features/home/presentation/notifiers/docs.md](../../../home/presentation/notifiers/docs.md)).
- `InputDeviceNotifier` tracks the currently selected microphone for
  capture; `InterruptedSessionsNotifier` powers the "you have an
  unsaved recording" prompt on app open by reading recovery rows from
  `RecordingSessionRepository`. It exposes a **two-phase save** plus a
  one-shot discard for resolving that prompt:
  - `save` re-runs the finalization pipeline against the surviving
    segments with `deleteSources: false` and returns the
    `RecordingResult` *without* resolving the session — it does **not**
    call `markRecovered` and does **not** clean up segments. The
    session stays `crashed` and the produced file is the input to the
    confirmation screen (see ENG-80 below).
  - `confirmRecovery(sessionId, keepPath:)` is the second phase: it
    runs only after the user confirms metadata on
    [../recovery_confirm_screen.dart](../recovery_confirm_screen.dart),
    marks the session recovered, and deletes every segment except
    `keepPath`. `keepPath` is the finalized file, which in the
    single-segment / degraded fallbacks *is itself one of the segments*
    — hence the exception rather than a blanket delete.
  - `discardRecovered(sessionId, filePath:)` deletes the finalized file
    then defers to `discard`, used by the confirmation screen's discard
    action.
  - `discard` deletes the segments and marks the session discarded.
  All paths end by calling
  [../../data/services/recovery_coordinator.dart](../../data/services/recovery_coordinator.dart)'s
  `refresh()`, which re-derives the prompt list from `findCrashedSessions()`;
  a session left `crashed` therefore re-appears in the banner.
- `PendingRecovery` + `pendingRecoveryProvider` (a `StateProvider`)
  carry the finalized `RecordingResult` and the session's classification
  from `save` to the confirmation screen. They exist because go_router's
  `extra` is lossy across redirects and on web — the finalized file path
  must survive the navigation, so it is parked in a provider instead.

### Things to Know

- **Audio playback must survive widget rebuilds.** The detail screen
  at [../recording_detail_screen.dart](../recording_detail_screen.dart)
  uses a `LayoutBuilder` that swaps the entire subtree at the 700 dp
  width threshold. Prior to ENG-69 the `AudioPlayer` lived inside a
  `StatefulWidget` State, so any rotation across that threshold
  disposed the player and stopped playback. The fix was to hoist the
  player into `RecordingPlayerNotifier`, which lives at the
  `ProviderScope` root and is unaffected by widget rebuilds.
- **AutoDispose + family is the lifecycle contract.** `autoDispose`
  ensures the underlying player is released when the detail screen
  unmounts (no listeners remain on the family entry). The `family`
  argument is the recording id, so two different recordings' players
  are isolated — opening recording A then B does not steal A's
  playback state.
- **Post-await writes are guarded by a `_disposed` flag (ENG-134).**
  Because the autoDispose provider can be torn down mid-load — the
  detail screen unmounts while `_doLoad` is suspended on path
  resolution or `setFilePath` / `setUrl` — the `onDispose` callback
  sets `_disposed = true` alongside `_player.dispose()`, and every
  `await` in `_doLoad` (including the top of the `on Object catch`) is
  followed by an early return when disposed. The guard is hand-rolled
  because Riverpod 2.6.1 has no `ref.mounted`, and a post-dispose
  `state =` does **not** throw: it is a silent stale write plus a
  spurious `didUpdateProvider` to observers, and on the file path it
  could call `setFilePath` / `setUrl` on the already-disposed player.
- **`load` is idempotent for the same source.**
  `RecordingPlayerNotifier.load` caches the last `filePath|url` key
  and skips re-running `setFilePath` / `setUrl` if the same source is
  requested again while `hasAudio` is true. This is what makes a
  re-call after a heal, edit, or rotation cheap.
- **The trim load is deliberately split between notifier and widget
  (ENG-193).** `TrimEditorNotifier.load` resolves the recording and, on
  success, leaves `isLoading` true; the screen then wires the
  `AudioPlayer`, runs the file-availability check
  (`fileExistsProvider`), and resolves the waveform/duration, finishing
  the load by calling back into the notifier — `completeLoad` (player
  wired, duration known), `setUnavailable` (audio missing; stores one of
  the two hardcoded "audio unavailable" messages), or `loadFailed`
  (player/waveform setup threw). `loadFailed` drops `recording` back to
  null, matching the screen's original outer-catch contract that a
  recording was only committed on a fully successful load. The player,
  the file probe, and the ffmpeg-backed waveform are device-bound and do
  not resolve under the fake-async widget-test zone, so they stay in the
  widget behind injectable providers rather than in the headless
  notifier.
- **The trim editor holds no Drift row anymore, and the row→entity map is
  one-way (ENG-198 + ENG-202 / ENG-95-F4).** `TrimEditorState.recording`, the
  load path, and the whole split/save chain (`_saveServerSide` / `_saveLocally`,
  the `RecordingSplitPersister`, and `splitRecordingReplacingParent`) all use the
  `LocalRecordingEntity`, never the Drift `LocalRecording` row — the trim editor
  was the **last** place the presentation layer touched a raw row, and ENG-202
  closed it. The row→entity projection now lives entirely in `data/`: `load`
  calls the repository's entity getters
  (`getRecordingEntityById`/`getRecordingEntityByServerId`,
  [../../data/repositories/docs.md](../../data/repositories/docs.md)) and
  `serverRecordingToEntity`
  ([../../data/server_to_recording_entity.dart](../../data/server_to_recording_entity.dart)),
  both of which funnel through the single canonical `localRecordingToEntity`
  ([../../data/local_recording_to_entity.dart](../../data/local_recording_to_entity.dart)),
  so the mapping the notifier used to do inline moved down a layer. The
  dependency flows one way for the split path (presentation depends on the
  entity, never the row). The split write path has no reverse mapper — it still
  builds `LocalRecordingsCompanion` children from the entity's fields in the data
  layer, because each child mixes inherited / segment-specific / reset fields;
  the entity carries every parent field the child-propagation contract reads, so
  the behavior is unchanged. (The separate *save* path did get a reverse mapper
  in ENG-201 — `localRecordingEntityToCompanion`, backing `saveRecording` — but
  that is the fresh-capture insert, a different write than the split.) This is
  the same migration that re-typed the recordings list (ENG-197) extended to the
  trim editor's load and split-persist paths.
- **`saveSplit` returns an outcome; the widget owns the UI (ENG-193).**
  Because the notifier is headless, `saveSplit` resolves to a sealed
  `TrimSaveOutcome` and never touches `BuildContext`. The screen
  `switch`es on it: `TrimSaveSucceeded` (carrying `mode` / `keptCount` /
  `excludedCount`) drives the confirmation snackbar and navigation,
  `TrimSaveFailed` surfaces the typed error, and `TrimSaveAborted`
  (recording null, or `decision.canSave` false) is a no-op. This keeps
  the orchestration unit-testable without pumping a widget.
- **The native split captures every dependency before the first `await`
  (ENG-193).** `_saveLocally` reads the exporter, the persister factory,
  both repositories, and the sync `processQueue` tear-off into locals
  *before* awaiting the ffmpeg export. The notifier is `autoDispose`, so
  if the user navigates away mid-export the family entry can be torn
  down; reading `ref` after the suspension could throw "Cannot use Ref
  after it has been disposed", yet the split must still commit. Capturing
  up front decouples the in-flight save from the notifier's lifecycle —
  the same reasoning behind the `_disposed` guard, applied to the
  dependencies instead of the state writes.
- **The trim editor reuses the `_disposed` + `ref.onDispose` guard.**
  Like `RecordingPlayerNotifier` and
  [../../data/services/recovery_coordinator.dart](../../data/services/recovery_coordinator.dart),
  `TrimEditorNotifier` sets `_disposed = true` in `ref.onDispose` and
  bails after each `await` in `load` before writing `state`, because
  Riverpod 2.6.1 has no `ref.mounted` and a post-dispose `state =` is a
  silent stale write. `saveSplit`'s `isSaving` reset on failure is
  likewise guarded so the captured-dependency split (above) can finish
  even after disposal.
- **`RecordingDetailNotifier` is headless; the widget owns every snackbar
  (ENG-194).** The notifier has no `BuildContext`, so its metadata mutations
  resolve to a `RecordingMutationResult { success, savedLocallyOnly, failed,
  forbidden, titleConflict }` and the screen `switch`es on it to pick the
  localized message and color (e.g. `forbidden` → `recording_updateNoPermission`
  in `AppColors.of(context).warning`; `failed` → the action's generic failure;
  `savedLocallyOnly` → `recording_savedOnDeviceOnly`, also in the warning
  color, via the shared `_showSavedOnDeviceOnly` helper (ENG-399); `success` →
  the success snackbar or nothing). This is the same headless →
  result → widget-owns-UI boundary as the trim editor's `TrimSaveOutcome`. The
  audio paths instead **throw** (`downloadAndCache`, `downloadForExport`) or
  return a `bool` (`replaceAudio`) because the screen wraps them in a progress
  dialog it must dismiss; the screen maps those to its own snackbars too.
- **`RecordingDetailState` has no value `==`/`hashCode` (ENG-194), even though
  it now holds a `LocalRecordingEntity` (ENG-199/ENG-200).** The entity carries
  value equality but the state wrapping it uses identity equality. The dedup that
  matters lives **upstream** in `watchRecordingEntityById`'s `.distinct()` (which
  keys on the entity's `==`), so the state has no `.distinct()` consumer of its
  own; identity equality reproduces the screen's original `setState`, which
  rebuilt on every mutation — so the empty `copyWith()` calls after the
  role/member fetches re-render exactly as the old empty `setState`s did, and the
  rebuild cadence is unchanged. Do **not** add value equality here expecting it
  to be inert; it would suppress those intentional no-field rebuilds.
- **`RecordingDetailNotifier` reuses the `_disposed` + `ref.onDispose` guard
  (ENG-194).** Like `RecordingPlayerNotifier` and `TrimEditorNotifier`, the
  autoDispose family entry can be torn down mid-load (the detail screen unmounts
  while `load` is suspended on a server fetch or a storyteller resolve), so
  `build` registers `ref.onDispose(() => _disposed = true)` and every `await` in
  `load`/the mutations bails before the next `state =`. Riverpod 2.6.1 has no
  `ref.mounted`, and a post-dispose `state =` is a silent stale write plus a
  spurious observer notification.
- **Path resolution lives in data, not in the notifier.**
  `audioPathResolverProvider` defaults to
  [../../data/services/audio_path_resolver.dart](../../data/services/audio_path_resolver.dart)'s
  `resolveRecordingPath`, which probes the stored path, the
  application documents directory, and a `recordings/` subdirectory in
  order. If none match it returns `null` and the notifier falls back
  to the `gcsUrl` (if any) or surfaces `fileNotFound`.
- **Two test seam providers exist intentionally.**
  `audioPlayerFactoryProvider` and `audioPathResolverProvider` exist so
  the notifier can be unit-tested without `just_audio` plugin channels
  or the filesystem. Production code never overrides them.
- **Notifiers expose no public fields/getters (ENG-158).**
  `riverpod_lint`'s `avoid_public_notifier_properties` is body-blind: it
  flags *any* public instance field or getter on a `Notifier` subtype,
  regardless of what it reads. As of ENG-158 `dart run custom_lint` is a
  blocking CI + pre-commit gate (final stage of
  [/docs/adr/ADR-0007-lint-baseline.md](/docs/adr/ADR-0007-lint-baseline.md)),
  so anything a widget needs off a notifier must flow through `state`,
  through a derived top-level provider, or through a **method**. That is
  why the long-lived `AudioPlayer` is reached via `audioPlayer()` rather
  than the former public `player` field — derived audio state already
  lives on `RecordingPlayerState`, but the player object itself (needed
  for the widget's `StreamBuilder`s) has nowhere to live but a method.
- **A failed finalize keeps the recording recoverable — on both stop
  paths.** Finalization (FFmpeg concat + IO under
  [../../data/services/recording_finalization_service.dart](../../data/services/recording_finalization_service.dart))
  can throw or return null. The main stop path
  (`RecordingSessionNotifier._finalizeOrCrash`) and the recovery save
  path (`InterruptedSessionsNotifier.save`) both swallow the failure,
  refresh the recovery coordinator, and return `null` — leaving the
  session `crashed` so it stays listed by `recovery_coordinator.dart`'s
  `refresh()` and can be retried. This is why neither caller may surface
  the exception:
  [../widgets/unsaved_recordings_sheet.dart](../widgets/unsaved_recordings_sheet.dart)'s
  save handler has no try/catch, so an escaping exception (one half of
  the original ENG-80 bug) would crash the recovery UI and half-handle
  the session.
- **The 1 Hz platform updates are coalesced, and their errors are
  reported (ENG-139 F5).** The elapsed-timer tick used to fire
  `unawaited(_updateForegroundNotification())` / `unawaited(_updateLiveActivity())`
  every second — a platform channel call slower than the 1 s interval would
  stack, and any throw became an unhandled async error. Each now runs through a
  `SingleFlightRunner` (`single_flight_runner.dart`), which holds an `_inFlight`
  bool and **drops** further `run()` calls while a run is outstanding
  (at-most-one in flight; coalescing), and routes failures to an `onError` sink
  wired to `errorReporterProvider`
  ([/lib/core/observability/docs.md](../../../../core/observability/docs.md))
  instead of dropping them. The runner is deliberately drop-on-busy, not queue:
  a missed tick is harmless because the next tick re-pushes the current elapsed
  value.
- **`stopRecording` is guarded by a synchronous `_isStopping` reentrancy
  flag (ENG-139 F6).** A user-initiated stop and a background stop (the Android
  FGS notification action, or an iOS Live Activity deep-link) can fire
  near-simultaneously. The guard is set **before any `await`** — `if (_isStopping
  || !state.isRecording || state.isFinalizing) return null;` then `_isStopping =
  true;` — so a second entrant bails regardless of how far the first has advanced
  the state machine, and it is cleared in a `finally` (the web and native stop
  paths are `await`ed inside the `try` so the flag spans the whole finalize).
  This is what keeps the two stop sources from double-finalizing the same
  session. The `state.isRecording`/`isFinalizing` checks alone are insufficient
  because they can both still read `true` in the window before the first call
  flips them.
- **A recovered session is only resolved after the user confirms — no
  silent data loss (ENG-80).** The materialization of a `local_recording`
  row happens *only* in `ConfirmationStep._save` (see
  [../widgets/confirmation_step.dart](../widgets/confirmation_step.dart));
  nothing else creates one. The original recovery "Save" path discarded
  the finalized `RecordingResult` and routed straight to `/recordings`,
  so the assembled audio was left orphaned on disk and no row was ever
  created. The flow now mirrors a normal recording: recovery `save`
  finalizes and parks the result, the home banner routes to
  [../recovery_confirm_screen.dart](../recovery_confirm_screen.dart),
  and only the user's Save there (`confirmRecovery` → `markRecovered`)
  or Discard (`discardRecovered` → `markDiscarded`) resolves the
  session. The two preconditions that make this safe live in `save`:
  it must **not** `markRecovered` (or the abandoned-confirmation session
  would vanish from the banner), and it must finalize with
  `deleteSources: false` (or the segments would be gone before the user
  decides). Leaving the confirmation screen without deciding keeps the
  session `crashed` with segments intact, so it simply re-surfaces in
  the banner on the next open.
- **The confirmation result is passed via a provider, not go_router
  `extra`.** `pendingRecoveryProvider` holds the finalized
  `RecordingResult` + classification across the
  [../widgets/unsaved_recordings_sheet.dart](../widgets/unsaved_recordings_sheet.dart)
  → `/recovery-confirm` navigation. The sheet captures
  `GoRouter.of(context)` **before** `Navigator.pop` (the modal's context
  is defunct after the pop) and the confirmation screen reads the
  provider. `extra` is avoided because it is dropped on redirect and on
  web, and the finalized file path cannot be lost.
- **`RecordingsListNotifier` discards stale fetches with a generation
  guard (last-write-wins).** Switching filters quickly — e.g.
  `setUserFilter('A')` then `setUserFilter('B')` — fires overlapping
  `fetchRecordings` calls, and a slow earlier one could otherwise
  resolve last and overwrite the newer result (and corrupt shared
  fields mid-flight). `fetchRecordings` bumps a monotonic
  `_fetchGeneration` on entry and, after every await, returns early if
  its generation is no longer current before touching `state` or
  `_serverOffset`. For this to hold, `_fetchAndMerge` is
  side-effect-free: it returns the merged list, `hasMore`, and the next
  offset as a record, and the caller applies `state` and `_serverOffset`
  together with no await between the generation check and the apply.
  `loadMore` *captures* the current generation (it does not bump it) and
  drops its page if a newer `fetchRecordings` superseded it, so a stale
  page is never appended and `_serverOffset` is not corrupted;
  `fetchRecordings` also clears `isLoadingMore` synchronously on entry so
  a superseded `loadMore` that bails cannot leave the spinner stuck.
  `_serverOffset` is the only mutable field shared across these methods —
  everything else lives on `state` or as a local.
- **The fetch-generation guard does not cover the ENG-45 sweep erase.** It
  discards a stale *list* — the `state`/`_serverOffset` assignment after the
  generation check in the caller — but the erase inside `_fetchAndMerge` has
  already run by then, on the way to building that list. This is why
  `_fetchAndMerge` captures `projectId` and the three filters once, before
  the `listRecordings` await, instead of re-reading `state` afterwards:
  re-reading let a slow filtered response outlive the user clearing the
  filter and get judged against no filter at all, putting rows the filter had
  merely excluded on trial rather than rows the server had actually dropped.
  On the paginated path (ENG-400) the ordering is the other way round and the
  check *is* load-bearing: `_advanceSweep` re-reads the generation after its
  `_loadLocal` and before erasing anything, because `_fetchGeneration` moves
  synchronously at the top of `fetchRecordings` while the erase runs on for a
  local read plus one round trip per candidate. Without it a refresh that
  starts mid-erase leaves `loadMore` bailing at its own generation check and
  never updating `state`: the rows would be gone from Drift and still on
  screen. Erasing is left to the next sweep instead.
- **A sweep is a suspicion, not a verdict — neither set holds still while it
  runs (ENG-400).** Three independent paths end with a recording absent from
  every page of a completed sweep while the server still has it: an upload
  that lands after page zero was read (the server sorts newest first, so the
  row belongs to a window already consumed, and the queue only updates
  `lastSyncAt` when it drains, which is what triggers the refetch); a delete
  on the server between two requests, which shifts everything down one
  position so the next `offset` window skips a live row; and a sweep left open
  across screen visits, since the provider is not `autoDispose` and the list
  screen reuses its `State` (tab bar, deep link, back navigation — see
  `didUpdateWidget`), so `initState` does not refetch and the page that closes
  a sweep can be visits away from the one that opened it. Narrowing the sweep
  cannot fix any of them, which is why the erase confirms each candidate with
  `getRecording` instead. Since ENG-399 a false positive is not a cache
  eviction: a metadata edit made offline lives only on the local row until
  the metadata outbox drains it (ENG-403 added the drain; before it, nothing
  ever resent the edit), so `serverHasRecording` no longer implies the
  row is a redundant copy of what the server has — an erroneous erase before
  the drain runs would lose the edit outright, not merely evict a cache
  entry.
- **Delete is a hard delete on every platform — the row delete is never
  `kIsWeb`-gated (ENG-120).** Each screen previously owned a duplicated
  delete that ran the local Drift delete inside `if (!kIsWeb)`. On web
  that guard skipped the row delete, so the server delete left an orphan
  Drift row that reappeared on the next `fetchRecordings` merge
  (resurrection). `deleteRecording` removes the guard and always deletes
  the row, then the audio file. On web `file_ops.deleteFile` clears the
  in-memory cache entry rather than touching disk (see
  [/lib/core/platform/docs.md](../../../../core/platform/docs.md)); on
  native it removes the file. The audio delete is best-effort —
  a missing or locked file must not abort the row delete, so it swallows
  the exception and still returns `ok`.
- **On a remote-delete failure for a synced row, nothing local is
  touched (ENG-120).** A `ForbiddenException` maps to
  `DeleteRecordingResult.forbidden` and any other error to `failed`, and
  in both cases the row, the file, and `state` are left intact so the
  user can retry. This is a deliberate semantics change from the old
  per-screen code, which (on non-web) deleted the local row even when the
  remote delete failed.
- **Delete resolves the real local row, never trusting the list item's
  `id` (ENG-120).** The list holds the server-converted entity of a synced
  recording — `localRecordingToEntity(serverRecordingToLocal(s))`, where
  `serverRecordingToLocal` in
  [../../data/server_to_local_recording.dart](../../data/server_to_local_recording.dart)
  sets `id == serverId` and an empty `localFilePath`, both carried verbatim onto
  the entity — but a row that was created locally and then uploaded keeps its
  original uuid `id` and only gains a `serverId` (`markAsUploaded` never rewrites
  `id`). So deleting by `recording.id` would miss that uuid row — orphaning it
  (resurrects on the next merge) and leaking its audio file (the list copy's
  path is empty). `deleteRecording` first resolves the true Drift row via
  `getRecordingById` then `getRecordingByServerId`, and deletes that row's real
  `id` and real `localFilePath`. This is what makes the hard delete actually
  remove the row + audio for a list-synced recording on every platform,
  generalizing the web-orphan fix above. Note the entity is the *presentation*
  identity; the row delete still goes through the Drift repository by id.
- **`RecordingsListNotifier`'s fallback catches report, they don't swallow
  (ENG-102).** The paths that intentionally degrade rather than fail the screen —
  the offline/error fall-back to the full local set in `fetchRecordings`, the
  `loadMore` pagination error, the local-read fall-backs, the remote-delete
  failure that maps to `DeleteRecordingResult.failed`, and the best-effort audio
  file delete — route their error through a private `_reportUnexpected(error, st)`
  to `errorReporterProvider`
  ([/lib/core/observability/docs.md](../../../../core/observability/docs.md)) with
  the stack preserved, *then* take the fallback. The fallback behavior is
  unchanged; the report is the only visibility, since these paths deliberately do
  not surface to the UI. `_reportUnexpected` skips `UnauthorizedException` (the
  expected token-refresh flow). Do not reintroduce a bare `catch (_)` here — a
  silently-swallowed failure on these paths is invisible to telemetry.
- **This is a hard delete, not a tombstone — and, as of ENG-45, the absence
  of a tombstone is what lets a server-side delete propagate across
  devices.** `deleteRecording` removes the row and audio outright when the
  user asks for it, and the server row too when there is a `serverId`
  (ENG-120); there is no soft-delete/tombstone marker anywhere. Because
  nothing marks a deletion, device B cannot tell "the server deleted this"
  from "this just fell off the page" by looking at a listing alone — which is
  why, since ENG-400, it does not try to: absence from a completed sweep only
  nominates a row, and `getRecording` is asked about that one recording before
  anything is destroyed. A delete made on device A therefore reaches a synced
  device B the next time B completes a sweep and the server answers 404, with
  no server-side delete contract and no push. This is the ENG-45 fix as
  extended by ENG-400; the remaining limits are the `uploaded`/`verified`-only
  gate and the fact that the sweep completes only when the user pages to the
  end of the list (the 50-recording page-size ceiling is gone), not a
  cross-device scope carve-out.
- **A benign race between the list sweep and downloading/caching the same
  recording (ENG-45).** If a complete sweep runs while
  `RecordingDetailNotifier.downloadAndCache` is mid-flight for a recording
  the server no longer has, the sweep can erase the row while the detail
  screen is still writing to it. It is left self-correcting rather than
  guarded: `cacheDownloadedAudio`'s insert branch
  ([../../data/repositories/docs.md](../../data/repositories/docs.md))
  resurrects the row on its next write, and the following sweep erases it
  again since the server still doesn't have it.

Created and maintained by Nori.
