# Noridoc: Recording Presentation

Path: @/lib/features/recording/presentation

### Overview

- Holds the user-facing screens for the recording feature: the recordings
  list, the detail screen, the recording flow / quick recording, the trim
  editor, the file import flow, and the supporting notifiers and widgets.
- The detail screen is the central hub for editing a recording's
  metadata. It is also the call site of the ENG-64 fix: a server-only
  recording opened for edit must download the audio and persist the row
  without dropping any metadata field.
- All persistence happens through the recording data layer at
  [../data/](../data/). Screens never write directly to Drift; they read
  through providers in [../data/providers.dart](../data/providers.dart)
  and call repository methods.

### How it fits into the larger codebase

- Screens are wired into navigation by the top-level router in
  [/lib/core/router/](../../../core/router/) (e.g. `/recording/:id`,
  `/recording/:id/trim`, the recording flow, the file-import screen).
- The detail screen depends on:
  - [../data/recording_heal_companion.dart](../data/recording_heal_companion.dart)
    for the additive-only metadata heal on online refresh.
  - [../data/server_to_local_recording.dart](../data/server_to_local_recording.dart)
    for kIsWeb and offline-miss cases where there is no local row yet.
  - [../data/repositories/local_recording_repository.dart](../data/repositories/local_recording_repository.dart)
    for `cacheDownloadedAudio` (the post-download write) and for in-place
    edits (`updateRecording`, `deleteRecording`).
  - [../data/providers.dart](../data/providers.dart) for
    `localRecordingStreamProvider`, which streams Drift changes back into
    the screen so any external write (sync, heal) re-renders the UI.
- The trim editor at
  [./trim_editor_screen.dart](./trim_editor_screen.dart) consumes the
  same data layer and writes split children through
  `LocalRecordingRepository.splitRecording`, following the propagation
  contract documented in
  [/docs/recording-split-semantics.md](../../../../docs/recording-split-semantics.md).
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

- `recording_detail_screen.dart` owns the lifecycle for one recording.
  `_loadRecording()` resolves the row by trying local-by-id, then
  local-by-server-id, then (online) a server fetch that either heals an
  existing local row via `buildHealMetadataCompanion(local, server)` or
  builds an in-memory `LocalRecording` via `serverRecordingToLocal` when
  nothing is cached. The screen also `ref.listen`s
  `localRecordingStreamProvider(id)` so a heal or sync write propagates
  back into local state without manual reloads.
- `_ensureLocalFile(recording)` is the "download server audio so the user
  can trim/replace" path. It downloads the file from `recording.gcsUrl`
  via `http`, writes it to the app documents directory, and persists the
  cache via `LocalRecordingRepository.cacheDownloadedAudio`. The hand-built
  insert this method used to do was the ENG-64 corruption site; it is now
  a single call into the repository.
- All write actions on the detail screen (`_onStorytellerChanged`,
  `_saveDescription`, `_toggleCleaningStatus`, `_moveCategory`,
  `_classifyRecording`, `_persistSecondary`, `_replaceAudio`) follow the
  same pattern: call the server first, then mirror the change locally via
  `LocalRecordingRepository.updateRecording` with a narrow companion that
  touches only the affected fields, then `await _loadRecording()` to
  refresh the screen state.
- `trim_editor_screen.dart` loads a recording the same way as the detail
  screen but additionally streams audio from `gcsUrl` on web. After
  FFmpeg cuts the segments, the editor hands off to
  [../data/services/recording_split_persister.dart](../data/services/recording_split_persister.dart)
  which writes the children, archives the parent, deletes the parent
  locally and (best-effort) remotely, and kicks
  `SyncNotifier.processQueue` so the new children start uploading without
  the user having to interact. Prior to that handoff, the editor inlined
  the same pipeline but forgot the upload trigger, so children sat in
  `uploadStatus='local'` until the user edited a field on the detail
  screen (which kicks the queue via the `!hasServerId` branch in
  `_classifyRecording`).
- The detail screen's audio playback is owned by
  `RecordingPlayerNotifier` at
  [./notifiers/recording_player_notifier.dart](notifiers/recording_player_notifier.dart).
  After `_loadRecording` resolves the row, it calls
  `ref.read(recordingPlayerProvider(id).notifier).load(filePath, url)`;
  the same call also covers replace-audio and storyteller-change paths,
  which re-invoke `_loadRecording`. `RecordingHeroPlayer` watches that
  provider and renders the play controls / loading / error sub-views.
  Path resolution (stored path → docs dir → `recordings/` subdir) is
  delegated to
  [../data/services/audio_path_resolver.dart](../data/services/audio_path_resolver.dart).
- `file_import_screen.dart` is the multi-file import flow: it picks /
  drops candidates, probes each via
  [../data/services/audio_probe.dart](../data/services/audio_probe.dart),
  collects per-entry metadata, and saves the batch. The per-batch save
  delegates to the pure
  [./import_save_runner.dart](import_save_runner.dart) seam, which walks
  the entries and invokes a per-entry callback. That callback branches on
  `kIsWeb`: web uploads bytes straight to the server through
  `DirectRecordingUploader.upload` (no Drift row); native copies the file
  into the docs `recordings/` dir, optionally compresses WAV→M4A via
  FFmpeg, then writes a row through
  `LocalRecordingRepository.insertRecording` and lets the sync queue pick
  it up. Pure-logic seams like this and
  [./trim_edit_decision.dart](trim_edit_decision.dart) exist because
  `kIsWeb` is always false under test, so the branch-selecting orchestration
  is extracted to a headless-testable function while the screen keeps only
  the platform calls.
- `notifiers/` holds the Riverpod notifiers for the recording list,
  recording flow, and detail-screen playback (see
  [./notifiers/docs.md](notifiers/docs.md)); `widgets/` holds the
  dialogs and section widgets shared by the detail and list screens
  (see [./widgets/docs.md](widgets/docs.md)).

### Things to Know

- **Listener-driven re-renders.** The detail screen keeps a local
  `_recording` field but also listens to
  `localRecordingStreamProvider(widget.recordingId)`. If anything writes
  to that Drift row, the listener calls `setState(() => _recording =
  updated)`. This is what makes the ENG-64 bug user-visible: a corrupt
  cache insert immediately blanks the description on screen even though
  the user did not edit anything. Cache writes therefore have to be
  exhaustive.
- **Heal runs at most once per online open.** The heal companion in
  `_loadRecording` is gated by `localHasServerId && (needsGcsRefresh ||
  needsUserRefresh)`; rows that already have `gcsUrl` and `userId` are
  not heal-refreshed, which avoids redundant API calls. Inside the heal
  companion itself the corruption marker is `userId IS NULL`: only rows
  that lost userId to the original bug get user-content fields filled
  from the server. Healthy rows never get their description / storyteller
  / secondary classification touched — intentional clears survive.
- **Web vs native divergence.** On `kIsWeb`, the detail screen does not
  use Drift at all — it always reads via the API and renders an in-memory
  `LocalRecording` from `serverRecordingToLocal`. The `_ensureLocalFile`
  download path is a no-op on web. The trim editor for web routes to a
  dedicated `/trim` path that uses streamed audio.
- **Online-first then mirror locally.** Edits always call the server
  first; if the server call fails, the local row is not changed (so we do
  not generate phantom local edits). Errors are surfaced via
  `ScaffoldMessenger` snackbars; `ForbiddenException` is treated as a
  permission error and shown in orange.
- **The "download for edit" UX dialog gating.** `_ensureLocalFile` first
  asks the user for confirmation (`recording_downloadAudio`) before
  pulling the bytes. If the user cancels, no write happens; if the
  download fails, the dialog dismisses and a localized error snackbar is
  shown.
- **Import batch save is client-side idempotent on retry (ENG-80).** The
  import screen tracks which entries have already been saved in a
  `_completedEntryIds` set that outlives a single save and is keyed by
  entry id. `runImportSave` skips any entry already in that set, so if one
  entry throws part-way through a batch, the already-uploaded entries stay
  in the list and a second tap of Save re-runs only the still-pending ones
  instead of re-uploading the completed ones (which previously duplicated
  them — twice on the server for web, twice through sync for native).
  Removing an entry also drops it from the set. This idempotence is
  client-only: the server metadata create (`_createMetadata` in
  [../data/services/direct_recording_uploader.dart](../data/services/direct_recording_uploader.dart))
  and the sync engine carry no dedupe key, so an entry that fails *after*
  its server metadata already exists still creates a second metadata on its
  own re-attempt. Fixing that requires an API change and is out of scope.
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

Created and maintained by Nori.
