# Noridoc: Recording Presentation Notifiers

Path: @/lib/features/recording/presentation/notifiers

### Overview

- Riverpod notifiers that own the long-lived state for the recording
  feature's screens: the recording session (segmented capture), the
  recordings list (paginated server + local merge), input device
  selection, interrupted-session recovery prompts, and the detail
  screen's audio playback.
- Notifiers in this folder hold resources that must survive widget
  rebuilds — the active `Record` instance, the `AudioPlayer` for
  playback, paginator cursors, and crash-recovery state. The detail
  screen's `LayoutBuilder` swaps subtrees on rotation, so anything that
  must persist across that swap lives here, not in widget `State`.
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

### Core Implementation

- `RecordingSessionNotifier` (in `recording_session_notifier.dart`) is
  the top-level controller for the segmented capture flow. It owns the
  microphone, runs the segmenter from
  [../../data/services/segmented_recorder.dart](../../data/services/segmented_recorder.dart),
  drives the foreground service / live activity, and reconciles crash
  recovery via the services at
  [../../data/services/](../../data/services/).
- `RecordingPlayerNotifier` (`recording_player_notifier.dart`) is an
  `AutoDisposeFamilyNotifier<RecordingPlayerState, String>` keyed by
  recording id. Its `build(arg)` creates a `just_audio` `AudioPlayer`
  through `audioPlayerFactoryProvider` and registers an `onDispose`
  that releases the player and flags the notifier disposed (see Things
  to Know). Callers obtain the long-lived player via
  `ref.read(recordingPlayerProvider(id).notifier).player` and use the
  notifier's `load` / `togglePlay` / `seek` / `stop` methods. State is
  the immutable `RecordingPlayerState` in `recording_player_state.dart`
  (`isLoading`, `errorKind`, `hasAudio`); the error kind is one of
  `fileNotFound` (local missing and no fallback URL) or `loadFailed`
  (decoder/network error).
- `RecordingsListNotifier` (`recordings_list_notifier.dart`) owns the
  paginated list. `fetchRecordings` loads page zero — the server list
  merged with local-only rows from `LocalRecordingRepository`, deduped
  by `serverId` — and `loadMore` appends later pages from the
  `_serverOffset` cursor; offline or on an API error both fall back to
  the full local set. Status / genre / subcategory / search filtering
  is computed client-side by `RecordingsListState.filteredRecordings`
  and never refetches, so only `setUserFilter`, `setStorytellerFilter`,
  `clearAllFilters`, `clearStaleRecordings`, and pull-to-refresh re-hit
  the server. `patchRecordingTitle` rerenders after an edit without a
  full refetch.
- `deleteRecording(LocalRecording)` is the single owner of the
  user-initiated **hard delete** for both the list and detail screens
  (ENG-120). It deletes remotely via the recording API *only* when the
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
  sets `_disposed = true` alongside `player.dispose()`, and every
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
  `id` (ENG-120).** The list shows the server-converted copy of a synced
  recording (`serverRecordingToLocal` in
  [../../data/server_to_local_recording.dart](../../data/server_to_local_recording.dart)
  sets `id == serverId` and an empty `localFilePath`), but a row that was
  created locally and then uploaded keeps its original uuid `id` and only
  gains a `serverId` (`markAsUploaded` never rewrites `id`). So deleting by
  `recording.id` would miss that uuid row — orphaning it (resurrects on the
  next merge) and leaking its audio file (the list copy's path is empty).
  `deleteRecording` first resolves the true row via `getRecordingById` then
  `getRecordingByServerId`, and deletes that row's real `id` and real
  `localFilePath`. This is what makes the hard delete actually remove the
  row + audio for a list-synced recording on every platform, generalizing
  the web-orphan fix above.
- **This is a hard delete, not a tombstone.** `deleteRecording` removes
  the row and audio outright; there is no soft-delete / tombstone marker.
  The durable cross-device delete case (delete on device A propagating to
  device B) is out of scope and needs a server-side delete contract
  (`needs-api`); a synced row deleted here will reappear on a different
  device that still lists it from the server.

Created and maintained by Nori.
