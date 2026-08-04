# Noridoc: Recording Presentation Widgets

Path: @/lib/features/recording/presentation/widgets

### Overview

- Shared widgets used by the recording feature screens: dialogs (move
  category, classify, replace audio, edit details), sections of the
  detail screen (status, info grid, storyteller, quick actions,
  about, upload progress), the guided ficha-completion overlay/pill/sheet
  (`CompleteFichaOverlay`/`CompleteFichaPill`/`CompleteFichaSheet`, ENG-374),
  recording flow widgets
  (segment cards, waveforms, finalizing overlays, recording step), the list
  card and the pending-web-upload card, and the hero player + playback
  controls.
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
- Audio playback widgets read the `AudioPlayer` by calling
  `recordingPlayerProvider(recordingId).notifier.audioPlayer()` — a
  method, not a field, because `riverpod_lint`'s
  `avoid_public_notifier_properties` (a blocking gate since ENG-158)
  bans public notifier fields/getters (see
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
  `AudioPlayer` via `notifier.audioPlayer()` and wires the slider's
  `onChanged` to `notifier.seek`; the play/pause button calls
  `notifier.togglePlay`.
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
  actions. `ConfirmationStep` is the only widget that triggers persisting a
  freshly captured `local_recording` row, but it does not build the Drift
  companion itself: both its save paths (`_save` native, `_saveWebDirect`
  web-direct) construct a `LocalRecordingEntity` and pass it to
  `LocalRecordingRepository.saveRecording`, and the data layer maps that entity
  to the companion (ENG-192, ENG-201 — see
  [../../data/repositories/docs.md](../../data/repositories/docs.md)). It is
  reused by both the normal recording flow and crash recovery via
  [../recovery_confirm_screen.dart](../recovery_confirm_screen.dart).
- A description is mandatory to save (ENG-354). The rule lives in
  `isDescriptionSufficient` /
  [../../../../shared/utils/recording_description.dart](../../../../shared/utils/recording_description.dart)
  and is measured in extended grapheme clusters, so no writing system pays more
  for the same amount of text. Two widgets gate on it, and both call that one
  predicate rather than re-implementing the comparison:
  `ConfirmationStep._save` (the sole route into `_saveWebDirect`, so one guard
  covers the native and the web-direct paths alike) and
  `_EditRecordingDetailsSheetState._onSave`. Both surface the failure inline —
  `errorText` on the description field, cleared as the user types — and neither
  disables its Save button, matching how the sheet already treats a missing
  title. The widget gates are the only *save-time* enforcement: recordings saved
  before ENG-354 are grandfathered in the database, nothing migrates, and the
  Drift column stays nullable. They are not grandfathered on the wire — the API
  requires the description on create, so the sync engine pre-flights the same
  predicate and parks such a row in `uploadStatus='failed_description'` until the
  edit sheet fixes it (see [/lib/features/sync/docs.md](../../../sync/docs.md)).
- The file-import surfaces gate on the same predicate through
  [../file_import_validation.dart](../file_import_validation.dart):
  `isImportEntryValid` folds the description rule in beside genre / register /
  subcategory, and `descriptionErrorText` renders the one message both layouts
  show. `FileMetadataCard` (narrow) and the `FileMetadataEditor` data table
  (wide) each hang it off the description field's `errorText`, gated on the
  same `hasError` flag the classification fields already use — so the message
  appears when the user presses save. It then clears **while the user types**,
  matching the other two surfaces: neither description field has an `onChanged`
  in either layout, so `_FileImportScreenState` attaches a listener to each
  entry's `descriptionController` when the entry is created and rebuilds from
  there (`_onDescriptionChanged`). The rebuild is what re-evaluates
  `descriptionErrorText`; the row's `hasError` flag itself is only dropped once
  `_clearErrorIfResolved` finds the *whole* entry valid, exactly as the
  genre / subcategory / register / bulk handlers do — so a fixed description
  can clear its own message while the row stays flagged for a missing genre.
  `_onSavePressed` also clears every flag on its success branch, so nothing
  stays marked red through a save that was allowed to proceed. The wide
  table gained a description column with ENG-354; before that it had no
  description input at all, which would have left the gate unsatisfiable on a
  desktop-width screen.
- List-side widgets (recording card, filter chips, filter bar, filter
  sheet) consume `recordingsListNotifierProvider` and the
  genre/project notifiers; they emit user intent back to
  `recordings_list_screen.dart`. `RecordingCard` takes a
  `LocalRecordingEntity` (ENG-196), reading its classification via the
  entity's `isUnclassified` / `hasSecondary` extension (see
  [../../domain/docs.md](../../domain/docs.md)); it no longer touches Drift
  or the row-level classification extension.
- `CompleteFichaOverlay`/`CompleteFichaPill`/`CompleteFichaSheet`
  ([complete_ficha_overlay.dart](complete_ficha_overlay.dart) /
  [complete_ficha_pill.dart](complete_ficha_pill.dart) /
  [complete_ficha_sheet.dart](complete_ficha_sheet.dart), ENG-374) are the
  guided-completion widgets that replaced the detail screen's classify
  banner: a floating pill showing how many `PendencyKind`s
  ([../../domain/entities/review_pendency.dart](../../domain/entities/review_pendency.dart))
  a recording still owes, and the bottom-sheet checklist it opens. All three are
  presentational — they take the step list, the resolved set, and callbacks —
  and own no providers; the orchestration (opening the sheet, recomputing
  what is resolved, routing a tapped step to an editor) lives on
  [../recording_detail_screen.dart](../recording_detail_screen.dart), see
  [../docs.md](../docs.md). Two layout rules are load-bearing and easy to undo
  by accident. The overlay exists as a separate widget so the pill's placement
  can be tested without the screen (which cannot be pumped loaded), and it is
  where the safe-area offset, the wide-layout offset above the docked player
  strip, and the width constraint on the pill all live. The sheet scrolls its
  step list inside a `Flexible`/`SingleChildScrollView` and keeps the CTA
  outside it: at 2.0x the steps alone outgrow a phone screen, and a CTA that
  scrolled with them ended up below the bottom edge with nothing left to bring
  it back. Its subtitle counts the steps that are still *open*, not the length
  of the list, and disappears when that count reaches zero.
- `PendingWebUploadCard` (ENG-196) is the presentational, stateless card for
  one resumable web upload, rendered once per item by
  `PendingWebUploadsBanner` ([./pending_web_uploads_banner.dart](pending_web_uploads_banner.dart)).
  It takes a `LocalRecordingEntity` plus an `isResuming` flag and
  `onResume` / `onDiscard` callbacks; it owns no state and no providers.
  It was split out of the banner's inline per-item body precisely because
  the banner is gated behind `kIsWeb` and so never renders under the CI
  widget tests (where `kIsWeb` is always false) — extracting the card lets
  the card's layout be exercised directly on the VM while the banner keeps
  the platform gate, the repository read, and the resume/discard
  orchestration.

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
- **The detail-screen sections do not decide who may edit.** The
  `canEdit` flag passed into `RecordingAboutSection`,
  `RecordingQuickActions`, and `RecordingStorytellerSection` only toggles
  control visibility; the actual role/ownership decision is the screen's
  `_canEditRecording` getter delegating to the policy in
  [../../domain/docs.md](../../domain/docs.md). A section showing its
  edit buttons therefore implies the screen already granted edit rights.
- **Cleaning-status presentation has one source of truth.**
  `RecordingStatusSection`'s cleaning row no longer maps the status String
  (none / needs_cleaning / cleaning / cleaned / failed) to its icon / color /
  label itself; it calls `CleaningStatusStyle.forStatus` from
  [/lib/shared/utils/cleaning_status_style.dart](/lib/shared/utils/cleaning_status_style.dart),
  the same mapping consumed by
  [/lib/shared/widgets/cleaning_status_badge.dart](/lib/shared/widgets/cleaning_status_badge.dart).
  That object's `isFlagged` flag models the one behavioral divergence between
  the two consumers: the badge hides non-flagged (none / unknown) statuses,
  while the status section renders a neutral "not flagged" row for them. Colors
  come from the resolved `AppColorSet` (`needs_cleaning` → `warning`,
  `cleaning` → `info`, `cleaned` → `success`, `failed` → `error`), so both
  surfaces are theme-aware in dark mode. Three private cleaning-mapping helpers
  on the status section were deleted in favor of this shared mapping.
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
- **`ConfirmationStep` cancels its own preview-player stream subscriptions
  on dispose (ENG-140 F16).** Its inline `AudioPlayer` preview subscribes to
  `playerStateStream` / `positionStream` / `durationStream`; those handles are
  stored and `cancel()`-ed in `dispose()` before `_player.dispose()`. just_audio
  0.9.42 does not close those streams when the player is disposed, so dropping
  the subscriptions is required to stop their `setState` callbacks from firing
  on an unmounted widget. (This widget owns a short-lived preview player only;
  the long-lived detail-screen player still lives in `RecordingPlayerNotifier`.)
- **The Quick Recording "ready" state is responsive to system text scale,
  not text-clamped (ENG-171).** `recording_step.dart`'s not-recording layout
  must survive a large OS font (`MediaQuery` `textScaler`) without overflowing
  or hiding controls — a user-reported regression where the fixed-size,
  non-wrapping layout broke under enlarged fonts. The stance is responsive
  layout, deliberately *not* a per-screen low text-scale clamp (a low clamp was
  rejected because it hurts low-vision users; only the app-wide *high* ceiling
  in [/lib/main.dart](/lib/main.dart) applies — see
  [/lib/core/theme/docs.md](/lib/core/theme/docs.md)). The mechanism is a few
  reflowing primitives instead of fixed sizes: the sensitivity chips scroll
  horizontally (label/icon stay pinned), the input-source row wraps its
  label + device name to a second line instead of truncating it, and both the
  fixed-size record-ring stack and the elapsed timer sit in a `FittedBox` that
  scales them down only when space is tight (base size unchanged at 1×). The
  "tap to record" hint is the last child *inside* the centered ready-content
  `Column` rather than a fixed sibling, so Column ordering guarantees it cannot
  overlap the record button under scale. The timer block is shared with the
  active-recording state, so its `FittedBox` benefits both. This is the first
  widget slice of the
  staged app-wide a11y program (ENG-177); regression is pinned by a widget test
  that pumps this state at 1.0×/1.3×/2.0× on a realistic phone viewport via the
  shared `pumpAtTextScale` / `expectNoOverflow` harness in
  [/test/support/text_scale.dart](/test/support/text_scale.dart).
- **The rest of the recording feature is text-scale resilient (ENG-179, Wave 2
  of ENG-177).** Continuing the ENG-171 stance (responsive layout, never a
  per-screen low clamp), the remaining widgets were audited at 1.0×/1.3×/2.0×
  with the shared `pumpAtTextScale` / `expectNoOverflow` harness. Only five
  needed code: `ConfirmationStep` wraps its whole body in a scroll-when-overflow
  shell (`LayoutBuilder` → `SingleChildScrollView` →
  `ConstrainedBox(minHeight: maxHeight)`) so the previously-fixed bottom section
  (title, storyteller picker, description, action buttons) scrolls instead of
  overflowing the column — `IntrinsicHeight` is deliberately avoided because the
  waveform's `LayoutBuilder` cannot report intrinsics; `ActionTile`
  (`recording_quick_actions.dart`) drops its fixed `height: 76` for a
  `ConstrainedBox(minHeight: 76)` + `Column(mainAxisSize: min)` so labels grow
  downward (width stays 80, parent `Wrap` reflows); the header `Row`s of
  `segment_taxonomy_sheet.dart` and `input_device_picker_sheet.dart` wrap their
  title `Text` in `Expanded` to kill a horizontal overflow at scale; and
  `recording_hero_player.dart`'s error box swaps its fixed `height: 64` for a
  `ConstrainedBox(minHeight: 64)` so a long localized error message (the worst
  case is the `fileNotFound` string, longer in pt than en) can grow a second
  line instead of clipping — pinned by tests at both error branches in en + pt.
  The audit intentionally left several targets unchanged after the harness
  proved them safe: the confirmation **waveform `Stack`** is pure graphics (no
  text → `TextScaler` cannot overflow it, so its fixed `height: 100` stays), the
  `edit_recording_details_sheet.dart` save button and the
  `filters_icon_button.dart` count badge (a `Stack(clipBehavior: none)`) do not
  overflow, and `active_filter_chips.dart` already ellipsizes. Those keep a
  text-scale regression test but no production change.
- **`ConfirmationStep` is parameterized for the recovery reuse (ENG-80).**
  Two optional params let the recovery screen host the same widget
  without duplicating the save logic: `onSaved` runs in place of the
  default `go('/home')` after the row is written (recovery uses it to
  mark the session recovered and route to `/recordings`), and
  `showReRecord` hides the "record again" button (recovery has no live
  segments to re-capture). Because the save row is created here, the
  recovery flow must reach this screen — routing straight to the list
  after finalize was the original ENG-80 data-loss bug. See
  [../notifiers/docs.md](../notifiers/docs.md) for the deferred-resolution
  invariant.

Created and maintained by Nori.
