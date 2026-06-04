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
  through `audioPlayerFactoryProvider` and registers
  `ref.onDispose(() => player.dispose())`. Callers obtain the
  long-lived player via
  `ref.read(recordingPlayerProvider(id).notifier).player` and use the
  notifier's `load` / `togglePlay` / `seek` / `stop` methods. State is
  the immutable `RecordingPlayerState` in `recording_player_state.dart`
  (`isLoading`, `errorKind`, `hasAudio`); the error kind is one of
  `fileNotFound` (local missing and no fallback URL) or `loadFailed`
  (decoder/network error).
- `RecordingsListNotifier` paginates server recordings, merges them
  with local-only rows from `LocalRecordingRepository`, and exposes
  patch operations (e.g. `patchRecordingTitle`) used after edits so
  the list rerenders without a full refetch.
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

Created and maintained by Nori.
