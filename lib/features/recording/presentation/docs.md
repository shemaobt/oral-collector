# Noridoc: Recording Presentation

Path: @/lib/features/recording/presentation

### Overview

- Holds the user-facing screens for the recording feature: the recordings
  list, the detail screen, the recording flow / quick recording, the trim
  editor, the file import flow, and the supporting notifiers and widgets.
- The detail screen is the central hub for editing a recording's metadata.
  As of ENG-194 it is a thin consumer: its load orchestration and mutations live
  in `RecordingDetailNotifier` (see [./notifiers/docs.md](notifiers/docs.md)),
  which is also the home of the ENG-64 fix — a server-only recording opened for
  edit must download the audio and persist the row without dropping any metadata
  field.
- All persistence happens through the recording data layer at
  [../data/](../data/). Screens never write directly to Drift; the feature's
  notifiers read through providers in
  [../data/providers.dart](../data/providers.dart) and call typed repository
  methods, and screens forward to the notifiers.

### How it fits into the larger codebase

- Screens are wired into navigation by the top-level router in
  [/lib/core/router/](../../../core/router/) (e.g. `/recording/:id`,
  `/recording/:id/trim`, the recording flow, the file-import screen).
- The detail screen is now a thin consumer of `RecordingDetailNotifier`
  (ENG-194), which owns the load orchestration, the metadata/audio mutations,
  and the `localRecordingStreamProvider` listen (see
  [./notifiers/docs.md](notifiers/docs.md)). The screen's former direct
  dependencies — the heal companion
  ([../data/recording_heal_companion.dart](../data/recording_heal_companion.dart)),
  `serverRecordingToLocal`
  ([../data/server_to_local_recording.dart](../data/server_to_local_recording.dart)),
  the repository writes
  ([../data/repositories/local_recording_repository.dart](../data/repositories/local_recording_repository.dart)),
  and `localRecordingStreamProvider`
  ([../data/providers.dart](../data/providers.dart)) — all moved into the
  notifier. The screen reads `ref.watch(recordingDetailProvider(id))` for state;
  the user-initiated delete is still delegated to
  `RecordingsListNotifier.deleteRecording` (see Core Implementation and
  [./notifiers/docs.md](notifiers/docs.md)).
- The trim editor at
  [./trim_editor_screen.dart](./trim_editor_screen.dart) is now a thin
  widget: its editing state and split/save orchestration live in
  `TrimEditorNotifier` (see [./notifiers/docs.md](notifiers/docs.md)),
  which writes split children through
  `LocalRecordingRepository.splitRecordingReplacingParent`, following the
  propagation contract documented in
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).
  The screen keeps only the audio player, transport playback, and the
  waveform viewport.
- Cross-feature dependencies: storyteller resolution
  ([/lib/features/storyteller/](../../storyteller/)), member loading and
  roles
  ([/lib/features/project/](../../project/),
  [/lib/features/auth/data/providers/role_provider.dart](../../auth/data/providers/role_provider.dart)),
  sync state for online/offline gating
  ([/lib/features/sync/presentation/notifiers/sync_notifier.dart](../../sync/presentation/notifiers/sync_notifier.dart)),
  and audio playback via `just_audio` — wrapped by
  `RecordingPlayerNotifier` (see
  [./notifiers/docs.md](notifiers/docs.md)) so the underlying
  `AudioPlayer` survives widget rebuilds.

### Core Implementation

- `recording_detail_screen.dart` is a thin `ConsumerStatefulWidget`
  (ENG-194). `build` reads `ref.watch(recordingDetailProvider(id))`; `initState`
  kicks `_notifier.load`. Every write handler is the same shape: show the
  dialog / sheet / file picker / progress spinner, call a `RecordingDetailNotifier`
  method, then map the returned `RecordingMutationResult` (or thrown error /
  `bool`) to a localized snackbar. The load orchestration, the metadata/audio
  mutations, and the `localRecordingStreamProvider` listen all live in the
  notifier (see [./notifiers/docs.md](notifiers/docs.md)) — the screen no longer
  imports `drift`'s `Value`, `http`, `dart:io`, the heal companion, or
  `serverRecordingToLocal`.
- What stays in the widget: the dialogs / bottom sheets, the snackbar mapping,
  the `file_picker` invocation, the share/export UI (`AudioExporter`),
  `_probeDuration` (it spins up a real `AudioPlayer` to read the picked file's
  duration), and `_ensureLocalFile`. `_ensureLocalFile` is now only the
  **confirmation-dialog + progress-spinner shell**: it asks the user
  (`recording_downloadAudio`), shows a blocking spinner, and delegates the
  actual GCS download + cache write to `_notifier.downloadAndCache` — the
  hand-built insert it used to do was the ENG-64 corruption site, and the inline
  `http.get` is now behind the `audioCacheDownloaderProvider` seam
  ([../data/services/audio_downloader.dart](../data/services/audio_downloader.dart)).
- The `_canEditRecording` getter and the per-action client-side authorization
  it gates are unchanged (see below); it now reads the recording off
  `ref.read(recordingDetailProvider(id)).recording` instead of a screen field.
- **Delete is the one action both screens delegate, not inline (ENG-120).**
  The list and detail screens each only show the confirm dialog, call
  `RecordingsListNotifier.deleteRecording(recording)` (which takes a
  `LocalRecordingEntity` as of ENG-197 — the list already holds entities, the
  detail screen converts its Drift row at the call site via
  `localRecordingToEntity`), and `switch` on the
  returned `DeleteRecordingResult` to pick the snackbar (`forbidden` →
  permission warning in `AppColors.of(context).warning`, `failed` → generic
  failure, `ok` → no snackbar). The notifier owns the whole flow — remote
  delete, the local Drift row, the audio file, and optimistic state removal
  — so the screens no longer touch `recordingApiRepositoryProvider`,
  `localRecordingRepositoryProvider`, `kIsWeb`, or `ForbiddenException` for
  delete. On `ok` *only*, the detail screen then refreshes genre stats and
  pops / navigates to `/recordings`; the list screen does nothing more
  because the notifier already removed the item from state (no refetch). See
  [./notifiers/docs.md](notifiers/docs.md) for the hard-delete semantics
  and the web-orphan fix.
- `trim_editor_screen.dart` is notifier-backed (ENG-193). It
  `ref.watch`es `trimEditorProvider(recordingId)` for the editing state
  and delegates every mutation and the save to `TrimEditorNotifier`
  (see [./notifiers/docs.md](notifiers/docs.md)). The widget retains
  only the device-bound pieces: it owns the `AudioPlayer` (built from
  `audioPlayerFactoryProvider`), the transport playback/seek listeners,
  and the waveform viewport (zoom/pan). The load is split deliberately —
  the notifier resolves the recording *row* (web fetch + map, or local
  resolution with a 404-vs-error fallback), then the widget wires the
  player, runs the `fileExistsProvider` availability check, loads the
  waveform peaks (`waveformLoaderProvider`) or synthesizes bars, and
  finishes the load by calling the notifier's `completeLoad` /
  `setUnavailable` / `loadFailed`. On save, the notifier exports the
  segments (native) or calls the server (web), runs the
  [../data/services/recording_split_persister.dart](../data/services/recording_split_persister.dart)
  pipeline (which writes the children, archives the parent, deletes it
  locally and best-effort remotely, and kicks `SyncNotifier.processQueue`
  so the new children start uploading), and returns a `TrimSaveOutcome`
  the screen `switch`es on to show the snackbar and navigate.
- The detail screen's audio playback is owned by
  `RecordingPlayerNotifier` at
  [./notifiers/recording_player_notifier.dart](notifiers/recording_player_notifier.dart).
  Once `RecordingDetailNotifier.load` resolves the row into state, the hero
  widget `RecordingHeroPlayer`
  ([./widgets/recording_hero_player.dart](widgets/recording_hero_player.dart))
  — handed that `recording` — calls
  `ref.read(recordingPlayerProvider(id).notifier).load(filePath, url)` and
  watches the provider to render the play controls / loading / error sub-views;
  the replace-audio and storyteller-change paths re-resolve the row (notifier
  `load`) which re-drives the hero. Path resolution (stored path → docs dir →
  `recordings/` subdir) is delegated to
  [../data/services/audio_path_resolver.dart](../data/services/audio_path_resolver.dart).
- `file_import_screen.dart` is the multi-file import flow: it picks /
  drops candidates, probes each via
  [../data/services/audio_probe.dart](../data/services/audio_probe.dart),
  collects per-entry metadata, and saves the batch. The per-batch save
  delegates to the pure
  [./import_save_runner.dart](import_save_runner.dart) seam, which walks
  the entries and invokes a per-entry callback. That callback branches on
  `kIsWeb`: web uploads bytes straight to the server through
  `DirectRecordingUploader.upload`; native copies the file into the docs
  `recordings/` dir, optionally compresses WAV→M4A via FFmpeg, then writes a
  row through `LocalRecordingRepository.insertRecording` and lets the sync
  queue pick it up. The native compress step deletes the copied WAV
  (`destPath`) only when `compressToM4a` returns `true`, which now means a
  verified non-empty m4a exists on disk — the ENG-140 F18 delete-on-success
  contract documented in
  [/lib/core/platform/docs.md](../../../core/platform/docs.md). The web path is only "no Drift row" for small
  (single-shot, <5 MB) files; a large web import goes resumable and
  `DirectRecordingUploader` inserts a temporary `web_<serverId>` shadow row
  (`uploadStatus='web_uploading'`) to carry resume state, deleting it on
  success — see
  [../data/services/direct_recording_uploader.dart](../data/services/direct_recording_uploader.dart).
  Pure-logic seams like this and
  [./trim_edit_decision.dart](trim_edit_decision.dart) exist because
  `kIsWeb` is always false under test, so the branch-selecting orchestration
  is extracted to a headless-testable function while the screen keeps only
  the platform calls.
- The `_canEditRecording` getter on the detail screen is the single
  client-side authorization chokepoint for the recording. It gates the
  "⋮" popup menu (split/trim, export, replace, move, classify, delete)
  and is passed as `canEdit:` into the section widgets
  (`RecordingAboutSection`, `RecordingQuickActions`,
  `RecordingStorytellerSection`), which hide their own controls when it
  is false. The getter is now a thin delegate to the pure policy
  `canEditRecording` in
  [../domain/recording_edit_policy.dart](../domain/recording_edit_policy.dart);
  it feeds the policy the current `User`, the boolean from
  `RoleNotifier.canManageProject(recording.projectId)`, and
  `recording.userId`. See [../domain/docs.md](../domain/docs.md) for the
  rule and its rationale.
- **Duplicate titles are handled at both ends of the save (ENG-71).** The
  backend deduplicates `POST /api/oc/recordings` by `(project_id, title)`, so
  before saving, `ConfirmationStep._save` asks the server whether the resolved
  title is already taken (`listRecordings(..., title:, limit: 1)` plus
  `isTitleTaken` from
  [../../../shared/utils/recording_title.dart](../../../shared/utils/recording_title.dart))
  and stops with a snackbar so the user can rename. **That lookup is
  best-effort by contract**: offline, with no active project, or on any API
  failure it answers `false` and the save proceeds exactly as before — losing a
  recording to a flaky lookup would be far worse than a late 409. That includes
  a **30 s timeout** on the call, matching the upload paths' `_apiTimeout`: the
  save blocks on this answer and the shared HTTP client bounds only the connect
  phase, so a connected-but-silent server would otherwise hold the saving
  spinner up forever. The web
  direct-upload path additionally catches `ConflictException` from the create
  call and shows the same message. On native the create happens later in the
  sync engine, which parks the row in `uploadStatus='failed_conflict'`; the
  detail screen then renders a `RecordingActionBanner` whose action opens the
  edit-details sheet, and `RecordingDetailNotifier.saveDetails` requeues the
  row via `resetAndRetry` once the title actually changes. **If the new title is
  taken as well**, the `PATCH` 409s, `saveDetails` returns
  `RecordingMutationResult.titleConflict` and `_openEditDetails` shows
  `recording_duplicateTitleMessage` for the attempted name; nothing is written,
  so the row stays `failed_conflict` and the banner keeps offering another
  rename. The inline "already used" warning compares
  `resolveRecordingTitle(text)` — the string the save actually persists — so a
  trailing space cannot slip a duplicate past it. `RecordingCard` and
  `RecordingStatusSection` give `failed_conflict` its own label
  (`recording_statusNameConflict`) instead of the generic failure label, and
  `RecordingsListState`'s *pending* filter includes it so a conflicted
  recording stays visible and actionable.
- `notifiers/` holds the Riverpod notifiers for the recording list,
  recording flow, and detail-screen playback (see
  [./notifiers/docs.md](notifiers/docs.md)); `widgets/` holds the
  dialogs and section widgets shared by the detail and list screens
  (see [./widgets/docs.md](widgets/docs.md)).

### Things to Know

- **The recordings list and its leaf cards are end-to-end entity-typed
  (ENG-196).** `recordings_list_screen.dart` reads
  `RecordingsListState.recordings` as `List<LocalRecordingEntity>` and passes
  each entity straight into `RecordingCard`
  ([./widgets/recording_card.dart](widgets/recording_card.dart)), whose
  `recording` prop is now a `LocalRecordingEntity`. ENG-196 deleted the
  temporary `_entityToCardRow` shim that ENG-197 used to re-hydrate a Drift row
  for the card, and dropped the screen's orphaned `app_database.dart` import.
  The card body is unchanged (the entity carries the same field names); its
  `isUnclassified` / `hasSecondary` reads now resolve through the entity's
  classification extension (see [../domain/docs.md](../domain/docs.md)) instead
  of the row's. As of ENG-199/ENG-200 the **detail tree is migrated too**: the
  detail-screen section widgets (status / info-grid / quick-actions / hero player
  / classification section) type their `recording` as `LocalRecordingEntity`, the
  screen's own `_ensureLocalFile` / `_persistSecondary` / `_deleteRecording`
  paths deal in the entity (`_deleteRecording` no longer wraps with
  `localRecordingToEntity` — the state already holds the entity), and the screen
  imports the entity's classification extension
  ([../domain/entities/local_recording_entity_classification.dart](../domain/entities/local_recording_entity_classification.dart))
  rather than the row's. With this the recording feature's UI is entity-typed
  end to end except where the data layer still needs a row (the heal/server
  resolution inside `RecordingDetailNotifier.load`, the split child-companion
  build).
- **Listener-driven re-renders (now in the notifier, ENG-194).** The
  recording shown is `RecordingDetailState.recording`, a `LocalRecordingEntity`
  (ENG-199/ENG-200), and `RecordingDetailNotifier.build` (native only)
  `ref.listen`s `localRecordingStreamProvider(id)`, which now carries
  `LocalRecordingEntity?`; a write that changes a content/operational field the
  entity carries patches the entity into `state`, which re-renders the watching
  screen. A write touching only the persistence-only columns the entity drops
  (`lastRetryAt`/`md5Hash`) is deduped upstream and never re-emits, so the screen
  no longer rebuilds on upload-bookkeeping churn (see
  [../data/repositories/docs.md](../data/repositories/docs.md)). The re-render
  hazard is otherwise identical: this is what makes the ENG-64 bug user-visible —
  a corrupt cache insert immediately blanks the description on screen even though
  the user did not edit anything, so cache writes still have to be exhaustive.
- **Heal runs at most once per online open.** The heal companion in the
  notifier's `load` is gated on the resolved row having a non-empty
  `serverId` *and* either missing its `gcsUrl` (while uploaded/verified) or
  missing its `userId`; rows that already have `gcsUrl` and `userId` are
  not heal-refreshed, which avoids redundant API calls. Inside the heal
  companion itself the corruption marker is `userId IS NULL`: only rows
  that lost userId to the original bug get user-content fields filled
  from the server. Healthy rows never get their description / storyteller
  / secondary classification touched — intentional clears survive.
- **Web vs native divergence.** On `kIsWeb`, the detail flow does not use
  Drift at all — `RecordingDetailNotifier.load` always fetches via the API and
  renders an in-memory `LocalRecording` from `serverRecordingToLocal`, the
  per-action local mirror writes are skipped, and the
  `localRecordingStreamProvider` listen is not registered. The
  `_ensureLocalFile` download path returns early on web. The trim editor for web
  routes to a dedicated `/trim` path that uses streamed audio.
- **Edit controls are role/ownership gated, not just login gated
  (ENG-142).** Every edit affordance on the detail screen flows through
  the one `_canEditRecording` getter, so a single policy decides
  visibility of the popup menu and all section edit buttons. The rule
  (in [../domain/docs.md](../domain/docs.md)) makes a recording editable
  only for platform admins, managers of *that* recording's project, and
  the recording's own creator; ordinary non-owner users no longer see
  those controls. This is a UX/authorization-surface fix, not a security
  boundary — the server remains the enforcement point and a matching
  server-side check is tracked separately (ENG-81). The getter still
  short-circuits to non-editable while `RecordingDetailState.recording` is null
  (before the row resolves).
- **Online-first then mirror locally.** Edits always call the server
  first (now inside the notifier's mutations, ENG-194); if the server call
  fails, the local row is not changed (so we do not generate phantom local
  edits). The notifier hands the outcome back as a `RecordingMutationResult` and
  the widget surfaces errors through the shared `showErrorSnackBar` helper
  ([/lib/shared/widgets/error_snack_bar.dart](../../../shared/widgets/error_snack_bar.dart)),
  which is handed the **typed** caught exception so it localizes via the type
  switch (ENG-104; the throwing catch-sites no longer build a raw
  `ScaffoldMessenger`/`SnackBar` from an interpolated `e`). The share/export
  path is the odd one out: it does not throw but inspects a `Result.error`
  string, which previously got string-interpolated straight into a raw
  `SnackBar`. ENG-186 routed those `Result.error` branches through the same
  helper, which shows only the localized `recording_exportShareFailed` message.
  `AudioExporter`'s raw reason is technical/English and already logged; routing
  it through the friendly mapper would mis-fire import-oriented branches (a
  `file not found` reason becomes an import message), so it is intentionally not
  surfaced. See
  [/lib/core/errors/docs.md](../../../core/errors/docs.md) for the `template`
  contract. The delegated
  delete path is the exception: it does not throw but returns a
  `DeleteRecordingResult`, and a `forbidden` result is shown in the semantic
  `warning` color (`AppColors.of(context).warning`), so it adapts to dark mode.
- **The "download for edit" UX dialog gating.** `_ensureLocalFile` first
  asks the user for confirmation (`recording_downloadAudio`) before
  pulling the bytes. If the user cancels, no write happens; if the
  download fails, the dialog dismisses and a localized error snackbar is
  shown.
- **Import batch save is idempotent on retry (ENG-80).** Two layers
  cooperate. First, the import screen tracks which entries have already been
  saved in a `_completedEntryIds` set that outlives a single save and is
  keyed by entry id; `runImportSave` skips any entry already in that set, so
  if one entry throws part-way through a batch, the already-uploaded entries
  stay in the list and a second tap of Save re-runs only the still-pending
  ones instead of re-uploading the completed ones. Removing an entry also
  drops it from the set. Second, re-attempting an entry that failed *after*
  its server metadata already exists is safe: the metadata create
  (`_createMetadata` in
  [../data/services/direct_recording_uploader.dart](../data/services/direct_recording_uploader.dart))
  is idempotent server-side and returns the same `serverId`, so no duplicate
  recording is created. The real ENG-80 defect was on the large web
  (resumable) path: that path persists a `web_<serverId>` shadow Drift row
  to carry resume state, and a retry that re-derived the same `serverId`
  re-wrote that row. The original code used a plain insert, which crashed
  with `UNIQUE constraint failed: local_recordings.id` and left the import
  unable to complete from the import screen. `_uploadResumable` now writes
  the shadow row with `LocalRecordingRepository.upsertRecording`, so the
  retry reconciles the existing row and the resumable service resumes from
  the persisted offset (`resumableSessionUri`/`uploadedBytes`) instead of
  crashing or re-uploading what already landed.
- **The trim loader distinguishes a failed load from a missing recording
  (ENG-140 F21).** Resolving a server-only recording (now in
  `TrimEditorNotifier.load` →
  [./notifiers/docs.md](notifiers/docs.md)) calls `apiRepo.getRecording`.
  A thrown error is not swallowed as "not found": only an HTTP 404
  (`isRecordingNotFound` in [./trim_load_error.dart](trim_load_error.dart))
  falls through to the not-found state; any other error
  (network/timeout/server) is stored as `loadError` on `TrimEditorState`,
  which the widget localizes via `friendlyErrorFor`. Because a failed
  load also leaves `recording` null, the screen's `build` checks the
  error state **before** the not-found state, so a real error is shown
  instead of a misleading "not found" screen.
- **Quick Recording is resilient to large system fonts via responsive
  layout (ENG-171).** The recording-flow "ready" state (in
  [./widgets/recording_step.dart](widgets/recording_step.dart)) reflows under a
  large OS `textScaler` rather than clamping it down — see
  [./widgets/docs.md](widgets/docs.md). The complementary app-wide *high*
  ceiling (2× max) lives at the `MaterialApp` builder; that invariant is owned
  by [/lib/core/theme/docs.md](/lib/core/theme/docs.md). This screen is the
  first slice of the staged app-wide a11y program (ENG-177).
- **Detail screen `LayoutBuilder` swap is what makes audio playback
  fragile.** The screen pivots between a `Column`/`AppBar` wide layout
  and a `CustomScrollView`/`SliverAppBar` phone layout at the 700 dp
  width threshold. Any orientation change that crosses that threshold
  rebuilds the entire subtree under a different ancestor. Long-lived
  resources used by the hero — most notably the `AudioPlayer` — must
  therefore live outside the widget tree. ENG-69 was the regression
  where the player lived inside a `StatefulWidget` State and was
  disposed by this swap mid-playback; the fix hoists it into
  `RecordingPlayerNotifier`.
- **Secondary-classification collision is prevented, not validated
  (ENG-72).** A secondary classification is invalid only when its whole
  `(register, genre, subcategory)` triple is identical to the primary
  triple — sharing the genre while differing in subcategory is a
  legitimate pair. The pickers therefore hide the one option that would
  complete an identical triple instead of letting the user build it and
  then complaining:
  [./widgets/secondary_classification_fields.dart](widgets/secondary_classification_fields.dart)
  for classify / move / the detail screen's `_SecondaryEditDialog`, and
  [./widgets/segment_taxonomy_sheet.dart](widgets/segment_taxonomy_sheet.dart)
  for per-segment overrides in the trim editor. There is no inline "same
  as primary" error and the segment sheet's save button is never
  disabled. Call sites must thread the **full** primary triple into the
  pickers — with only the genre id the hide-logic under-restricts and a
  colliding triple gets through, which is why those parameters are
  `required` even where they are nullable. The two surfaces that still
  warn both target **legacy rows** — the app can no longer create a
  colliding row, but the database can already hold one: the detail
  screen's red banner (`_hasSecondaryCollision`), resolved manually with
  "Clear secondary", and `TrimEditorScreen`, which refuses to open for
  such a row (the split is impossible for every segment, and the FFmpeg
  export runs before the persist would reject it). The picker itself
  resets a colliding field on **construction** as well as on a primary
  change, so opening it on a legacy row does not show a blank field that
  secretly still holds the old value. The predicate behind all of these is
  `secondaryEqualsPrimary(...)` in
  [../domain/entities/classification.dart](../domain/entities/classification.dart);
  see
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).

Created and maintained by Nori.
