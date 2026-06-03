# Noridoc: Recording Presentation Widgets

Path: @/lib/features/recording/presentation/widgets

### Overview

- Shared widgets used by the recording feature screens: dialogs (move
  category, classify, replace audio, edit details), sections of the
  detail screen (status, info grid, storyteller, quick actions,
  about, upload progress), recording flow widgets (segment cards,
  waveforms, finalizing overlays, recording step), the list card, and
  the hero player + playback controls.
- These widgets are leaf consumers: they `ref.watch` notifiers and
  data-layer providers but do not own long-lived resources. Anything
  that must survive a widget rebuild (the active `AudioPlayer`, the
  capture pipeline) lives in notifiers under
  [../notifiers/](../notifiers/).
- Most widgets read theme via `AppColors.of(context)` and localized
  strings via `AppLocalizations.of(context)`.

### How it fits into the larger codebase

- Consumed by the recording feature screens at [../](../) — the detail
  screen, recordings list, recording flow, trim editor, and file import
  screens all compose widgets from this folder.
- Widgets that mutate recording state call into
  [../../data/repositories/](../../data/repositories/) via providers
  in [../../data/providers.dart](../../data/providers.dart) — they
  never write to Drift directly. The detail-screen action handlers
  (replace, classify, move, etc.) live on
  [../recording_detail_screen.dart](../recording_detail_screen.dart);
  the widgets surface user intent via callbacks.
- Audio playback widgets read the `AudioPlayer` off
  `recordingPlayerProvider(recordingId).notifier.player` (see
  [../notifiers/docs.md](../notifiers/docs.md)). The widgets never
  construct an `AudioPlayer` themselves — that is the notifier's
  responsibility.
- Cross-feature widget reads include storyteller resolution from
  [/lib/features/storyteller/](../../../storyteller/) and project
  membership from
  [/lib/features/project/presentation/notifiers/](../../../project/presentation/notifiers/).

### Core Implementation

- `RecordingHeroPlayer` (the hero card at the top of the detail
  screen) is a `ConsumerWidget` that watches
  `recordingPlayerProvider(recording.id)` and dispatches to one of
  four sub-views: loading spinner, error label, "no audio available"
  text, or `RecordingPlayerControls`. It reads `MediaQuery` to pick a
  wide vs phone layout for its own chrome, but the underlying player
  is the same provider entry across both layouts — rotation does not
  recreate it.
- `RecordingPlayerControls` renders the play/pause button, slider,
  position label, and duration label. It reads the long-lived
  `AudioPlayer` off the notifier and wires the slider's `onChanged` to
  `notifier.seek`; the play/pause button calls `notifier.togglePlay`.
  The space-bar shortcut is provided by `PlaybackKeyHandler`, which
  is web-only.
- The taxonomy-edit dialogs (classify, move category, secondary
  classification) return a value object the detail screen consumes to
  call the server and mirror the change locally; the replace-audio
  dialog is the confirmation gate that fronts
  `_handleReplaceAudio` on the detail screen.
- Recording-flow widgets (the recording step, segment card, scrolling
  waveform, finalizing overlay, confirmation step) consume
  `recordingSessionNotifierProvider` and visualize the segmented
  recorder's progress; they call back into the notifier for transport
  actions.
- List-side widgets (recording card, filter chips, filter bar, filter
  sheet) consume `recordingsListNotifierProvider` and the
  genre/project notifiers; they emit user intent back to
  `recordings_list_screen.dart`.

### Things to Know

- **The hero player is not the owner of playback state.** The
  `AudioPlayer` lives in `RecordingPlayerNotifier` (an
  `AutoDisposeFamilyNotifier` keyed by recording id). The hero player
  watches that notifier's `RecordingPlayerState` for the loading /
  error / hasAudio fork. This split was introduced by ENG-69: when
  the player lived in a widget `State`, the detail screen's
  `LayoutBuilder` swap at the 700 dp threshold disposed it
  mid-playback on rotation. See [../notifiers/docs.md](../notifiers/docs.md)
  for the lifecycle contract.
- **The widgets in this folder do not call repositories directly.**
  Edits flow up through callbacks to the owning screen
  (`recording_detail_screen.dart` for the detail dialogs;
  `recordings_list_screen.dart` for the list filters), which performs
  the server call first and then mirrors locally via
  `LocalRecordingRepository`. This keeps the "online-first then mirror
  locally" invariant in one place — see
  [../docs.md](../docs.md) and
  [../../data/repositories/docs.md](../../data/repositories/docs.md).
- **Waveform widgets are isolated from the player.**
  `scrolling_waveform.dart` and `trim_waveform.dart` consume the
  `WaveformExtractor` service from
  [../../data/services/](../../data/services/) for visualization; they
  do not share an `AudioPlayer` instance with the hero player.
- **`PlaybackKeyHandler` is web-only.** On non-web platforms it
  returns `child` as-is. The Focus + space-bar shortcut is meant to
  match desktop-browser audio player conventions; mobile does not get
  it.
- **"Returned from background" is detected by a real-background flag,
  not the previous lifecycle state.** `recording_step.dart` re-activates
  the capture audio session on resume (otherwise the mic comes back
  dead on Android 14+). The framework synthesizes intermediate states,
  so the return path is always `paused → hidden → inactive → resumed` —
  the state immediately before `resumed` is *always* `inactive`, never
  `paused`. The widget therefore latches a flag whenever it sees
  `hidden`/`paused` and only acts on the following `resumed` (and only
  while `isRecording`), calling
  `recordingSessionNotifierProvider.notifier.reactivateAudioSession()`
  and showing the "continued in background" banner for 3s. A bare
  `inactive` blip (e.g. opening iOS control center, which never reaches
  background) leaves the flag unset, so it neither re-activates nor
  shows the banner — this avoids the false positive a `previous ==
  inactive` check would produce.
- **This widget's resume path is distinct from OS-interruption
  recovery.** The foreground/background re-activation above is owned by
  the widget and the session notifier. Re-activation after an OS audio
  interruption (phone calls, another app grabbing audio) is a separate
  path inside
  [../../data/services/segmented_recorder.dart](../../data/services/segmented_recorder.dart),
  which subscribes to the platform `interruptionEventStream` and
  re-activates the session itself.

Created and maintained by Nori.
