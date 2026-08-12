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
- `ActiveFilterChips` (`active_filter_chips.dart`) renders one chip per active
  filter on `RecordingsListState`, each removable back through the matching
  notifier setter. **The pendency is the exception: it has no chip here.** It
  had one (ENG-381), until `PendencyFilterChips` took over showing which
  pendency the list is narrowed to and offering the way back — two controls for
  one filter is the case where the user can watch them disagree.
- `PendencyFilterChips` (`pendency_filter_chips.dart`) is the always-visible
  shortcut in front of the sheet's pendency section: "all" plus one chip per
  `PendencyKind`, scrolling horizontally, each carrying how many recordings owe
  that field. It keeps **no selection of its own** — it watches
  `selectedReviewFlag` and calls `setReviewFlagFilter`, the same field the sheet
  mirrors in `initState`, which is the whole mechanism behind "pick a chip, open
  the sheet, and it is already selected". Labels come from the shared
  `pendencyLabel` in [../pendency_label.dart](../pendency_label.dart), not a
  local switch: the project settings breakdown names the same three kinds and
  the copies would drift. That helper sits in `presentation/`, not next to the
  `PendencyKind` enum it switches on, because a translated string is not domain
  knowledge — see [../../domain/docs.md](../../domain/docs.md).
- **The chip is a Material `ChoiceChip` overridden down to the package's pill**,
  not Material's own metrics: `showCheckmark: false`, `StadiumBorder`, no side,
  `labelPadding: zero`, `padding` 8×4, `VisualDensity.compact` and
  `MaterialTapTargetSize.shrinkWrap` take it from a 32px label box inside a 48px
  tap target down to ~28px. The count is bold text beside the label, not a
  capsule of its own — the capsule was most of the extra width. The design's
  literal `6px 10px` / `gap: 5` are off the codebase's 4px scale
  ([/lib/core/theme/app_spacing.dart](../../../../core/theme/app_spacing.dart)),
  so the tokens one step tighter are used instead. **The trade is the tap
  target**: ~28px is below the 44px both platforms ask for, and
  `MaterialTapTargetSize.padded` would restore it without changing how the chip
  looks, at the cost of a row half again as tall. The density is what the design
  is explicit about, so it wins — but it is a real trade, not an oversight.
- **Those counts are the project's, not the visible list's.** They come from
  `projectStatsProvider` → `ProjectStats.reviewFlagCounts`, the same aggregate
  the project screen quotes, so the two surfaces can never answer "how many
  still need a narrator" differently. The cost is that under another filter — a
  genre, a narrower status — the chip counts more recordings than the list ends
  up showing. A code absent from that map is a real zero and reads as `0`; an
  aggregate that never answered shows **no number at all**, because the list
  works offline and an invented count is worse than a missing one.
- `RecordingsFilterSheet` (`recordings_filter_sheet.dart`) must carry every
  filter `RecordingsListState.activeFilterCount` counts, because that count is
  the badge on the sheet's own button. It shipped without the pendency one:
  the badge said "1", the sheet showed nothing selected, and Reset + Apply left
  the filter standing — only the chip on the list could remove it (ENG-383).
  The sheet mirrors the notifier's filters into local fields in `initState` and
  writes them back on Apply, so Reset is a local clear that only takes effect
  through Apply. Apply calls `setReviewFlagFilter(..., refresh: false)` before
  the storyteller and user setters: all three are server-side, and those two
  re-fetch, so the flag is in state by the time the request goes out and one
  Apply still costs the fetches it already did. Its chips iterate
  `PendencyKind.values` and label them with the shared `pendencyLabel`, the
  same helper `PendencyFilterChips` uses.
- **The subcategory is carried without a control of its own (ENG-383).** It is
  counted by `activeFilterCount` too, and it is reachable: the genre detail
  screen navigates to `/recordings?genreId=…&subcategoryId=…`. The sheet mirrors
  it into a field like every other filter, Reset clears it, and Apply writes it
  — but it gets no chips, because a subcategory only means something under the
  genre it arrived with. Picking a *different* genre in the sheet drops it, for
  the same reason: kept across a genre change it would narrow the list to
  nothing while the badge counted it.
- **Two sections in that sheet hold chips that read identically, on purpose.**
  `filter_unclassified` (status) and `recording_pendencyClassification`
  (pendency) are word-for-word the same string in ar, es, id, ko, sw, tpi and
  zh — "Sin clasificar" twice in Spanish — and the description pair overlaps in
  meaning everywhere. Both stay: the status filter sieves the recordings already
  in memory and therefore **works offline**, which is how this app is used in
  the field, while the pendency filter is a question only the server can answer.
  What distinguishes them is the section, so the section is what the tree and
  the copy lean on. `FilterSection` (same file, public so tests can scope a
  finder to one section) groups a header, an optional supporting line and the
  controls into a real subtree instead of leaving them as siblings; the two
  colliding sections name where their answer comes from
  (`filters_sectionStatus` → "Status on this device",
  `filters_sectionPendency` → "What the server says is missing") and each
  carries a line saying what it costs ("Works offline" against "Needs a
  connection"). The copy deliberately describes the effect and never the
  mechanism — no "client-side" on screen. Covered in Spanish by
  [/test/features/recording/presentation/widgets/recordings_filter_sheet_test.dart](../../../../../test/features/recording/presentation/widgets/recordings_filter_sheet_test.dart).
- **The card is three rows, and the design package is what makes it three.**
  Title line (title, upload glyph, date), an optional description line, and a
  footer (tag, full classification, pendency chip, chevron). The upload glyph
  moved up from the footer to the title line — it answers "is this one safe
  yet", a property of the recording the title names — and the classification
  moved down into the footer, which is what buys the ~76px/~92px heights the
  package specifies. Two consequences worth knowing before touching either row:
  the **register** is now part of the classification (`registerName` had been a
  constructor parameter the list screen filled in and the card silently
  dropped, so a recording classified down to its register read exactly like one
  still missing it); and the duration, which ENG-382 had let back in ranked
  below the chip, now ranks below the classification too and therefore does not
  render at any phone width. It was **not** deleted — the package says it does
  not come back, and the ranking is what delivers that, so a wider row still
  shows it and nothing had to be argued away.
- **Unclassified is italic in `secondary`, never `warning`.** The design package
  reserves the warning token for system trouble — a corrupted recording, a
  failed upload — and the card had been spending it on a field the user simply
  had not filled in yet, which says something broke when nothing did.
- **The pendency chip carries the glyph of the field it names**: tag for the
  classification (the same tag the footer labels the classification with), a
  page for the description, a struck-through person for the storyteller. Two or
  more open fields collapse to `recording_pendencyCount(n)`, which has no kind,
  so it falls back to the neutral dashed circle.
- **Two width caps, both only ever binding at large text scales.** The chip may
  take at most `_chipShare` (60%) of what it and the classification divide: it
  outranks the classification — it is the call to action, and its label cannot
  be guessed from an ellipsis — but a chip that takes everything leaves the card
  unable to say which recording it is. The date is capped at `_dateShare` (45%)
  of the title row: the date is non-flex so the title yields to it at ordinary
  sizes (a truncated title is still recognisable, a truncated date is not), and
  without a ceiling the Arabic spelled-out date at 2.0x pushed the title off the
  card instead of merely shortening it.
- `RecordingCard` (ENG-374, "card V3") was redesigned around one question —
  "which recordings still need me?" — which cost the duration chip (and the
  `formattedDuration` constructor param `recordings_list_screen.dart` used to
  compute) and the standalone "unclassified" chip, and bought a description
  line plus a pendency chip. The upload-status chip lost its text to make
  room: `_statusIcon` still renders at 13px, but that glyph now sits inside a
  `SizedBox.square(dimension: 24)` so its `Tooltip` has a touchable hit
  target, and `_statusLabel` still exists — it feeds that `Tooltip` and the
  icon's `semanticLabel` instead of painted text, so the state is not lost,
  only moved off-screen, matching the design's requirement that colour never
  be the only signal for status. `_visibleDescription` reads
  `recording.description`, trims it, and only then applies `blankToNull` —
  `blankToNull` alone disagreed with `isDescriptionSufficient` about whether
  a whitespace-only string counts as present, and the card used to draw
  quotation marks around three spaces. When the trimmed description falls
  short of `isDescriptionSufficient`
  ([/lib/shared/utils/recording_description.dart](/lib/shared/utils/recording_description.dart)),
  `RecordingDescriptionLine` wraps it in curly quotes (`“ ”`, not ASCII `"`,
  to avoid a description that already contains a straight quote rendering as
  `""like this""`) rather than hiding it. The quotes are not localized per
  script because neither `intl` nor `flutter_localizations` exposes CLDR's
  quotation-mark data; that reasoning is a comment on the widget itself.
  `RecordingDescriptionLine` is public (not private) so a test can assert the
  line's absence by type instead of hunting for stray quotation marks — the
  same reasoning as `PendingWebUploadCard`'s split, below. `_FooterRow`'s
  `_pendencyLabel` calls `recordingPendencies`
  ([../../domain/entities/review_pendency.dart](../../domain/entities/review_pendency.dart)),
  the same function `CompleteFichaPill`/`CompleteFichaSheet` read (see
  below), and shows at most one chip: a single open field is named, two or
  more collapse into `recording_pendencyCount(n)`. A title-less recording
  falls back to `formatUntitledRecordingTime`
  ([/lib/shared/utils/format.dart](/lib/shared/utils/format.dart)), in
  italics, instead of a generic "Untitled" label — the fallback carries
  seconds because untitled recordings tend to arrive in bursts from the same
  session, and minute precision would not tell siblings apart. It is a clock
  time only: ENG-382 dropped the weekday the function used to prefix, because
  the date column on the same row already places the recording in time. The
  function kept `DateFormat.jms` (not `Hms`) through the rename — the clock
  convention belongs to the locale, and forcing 24 hours is the defect PR #174
  fixed for en/ar/hi/ko. `build()` was
  split entirely into row-level widget classes — `_TitleRow`, `_FooterRow`,
  `RecordingDescriptionLine`, and a few more — rather than
  private build-returning methods, a convention local to this file; each
  resolves its own `l10n`/theme off its own `BuildContext` instead of taking
  them as parameters. The split happened because the redesign pushed the file
  past the `dart_code_linter` SLOC gate's ceiling of 300 lines — before the
  description line was even added. `_statusAccent` (not `_statusIconColor`)
  returns `Color?`, null for the local (not-yet-uploaded) state that owns no
  colour of its own; each caller picks its own fallback instead of the two
  comparing colour values to infer which state produced them — the rail falls
  back to `colors.border`, the icon to `colors.secondary`. The chip's
  background is the themed `colors.chipSurface`
  (ENG-374; see [/lib/core/theme/docs.md](/lib/core/theme/docs.md)). ENG-382
  weighed retiring that token and kept it: it is not interchangeable with
  `surfaceAlt`, which coincides in dark (`0xFF302D22`) but differs in light
  (`0xFFF1EEDE` against `0xFFEDE9D5`), so the field is carrying a real
  distinction rather than costing one for nothing. ENG-382 did put
  the duration back in `_FooterRow`, between the chip and the chevron, which
  amends the ENG-374 trade rule that had banned it — the description keeps the
  room it won, and the duration is the element ranked below it. It uses
  `formatDurationHMS`, not `formatDurationCompact`: the compact form is
  hours-and-minutes only and renders both a three-second misfire and a real
  forty-minute take as `0m`, which is the exact distinction the amendment
  exists to restore. Its `semanticsLabel` is
  `formatDurationCompactWithSeconds`, because `00:03` spoken aloud is
  ambiguous between mm:ss and hh:mm while `3s` names its units.
  That ranking is enforced by measurement, not by the flex factors: a `Row`
  sizes its non-flex children at their intrinsic width **first** and hands
  only the remainder to the `Expanded` one, so leaving the duration in the row
  unconditionally made the chip — not the duration — pay for every pixel of a
  shortfall (at 390dp and 2.0x the chip's paragraph was cut to 69.5px). So
  `_FooterRow` takes the width the card measured for it, adds up the
  classification's `_textWidth`, `_PendencyChip.widthFor` and the duration's own
  `_textWidth`, and drops the duration from the row entirely when the three do
  not all fit. Dropping it
  whole rather than ellipsizing it is deliberate: `1:0…` reads as a wrong
  duration, an absent one reads as nothing. The width is measured by a
  `LayoutBuilder` at the very top of `RecordingCard.build` rather than around
  the footer, because the rail's `IntrinsicHeight` asks its subtree for
  intrinsic dimensions and `LayoutBuilder` throws on that query.
  `recording_card_text_scale_test.dart` pins the ranking: it pumps the card
  inside the 16dp padding the list really applies, at 320dp as well as 390dp,
  and asserts geometry — the chip reaches the chevron once the duration
  yields, and wherever the duration does render the chip's paragraph is
  uncut. (`find.text` is blind to all of this: it matches `Text.data`
  whatever the layout did with it.) One overflow at 320dp above 1.0x is
  neither the footer's nor ENG-382's — `_TitleRow`'s date column overflows
  there on `dev` too, by the same 26px — so that assertion is scoped to the
  footer's own rows until the title is fixed on its own issue.
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
- `RecordingUploadBanners` (ENG-377) renders every banner that explains why a
  recording is not on the server — title conflict, description gap, spent
  retry budget, missing audio file, secondary-classification collision — in a
  fixed order, each configured from the shared `RecordingActionBanner`. Split
  out of `RecordingDetailScreen.build` for the same reason as
  `PendingWebUploadCard` above: the loaded detail screen cannot be pumped in a
  widget test, so the wiring was untestable while it lived there. It is
  presentational — a `LocalRecordingEntity`, a `canEdit` flag and four
  callbacks, no providers. `canEdit` disables the action but never hides the
  banner: a viewer who cannot fix the problem should still be told what it is.

### Things to Know

- **`FinalizingOverlay`'s error body is chosen by `FinalizationErrorKind`, and
  its button does not discard anything (ENG-408).** The screen used to render
  one hardcoded pair of strings for every failure, so a browser recording that
  produced no blob was told "we tried to recover the audio but no segments were
  available" — segments do not exist on web, and the recovery it promised
  cannot happen there. Pass `errorKind`; `_errorBody` maps each kind to copy
  that is true for it, and the missing-segments wording survives only under
  `noSegments`, where it is accurate. The action is labelled
  `recording_finalizationErrorBack`, not "Discard and return", because
  `dismissFinalizationError` only clears state — it deletes no audio, and on a
  `finalizationFailed` the recording is still in the unsaved list.
- **`RecordingCard`'s room is a trade, not free space (ENG-374, card V3).**
  The description line only fits because the upload-status chip gave up its
  visible text; the duration chip and the standalone "unclassified" chip are
  simply gone. Reintroducing the duration chip, restoring text on the
  status chip, or adding a second pendency chip will overflow the row
  again. `recording_card_text_scale_test.dart` pins the fullest possible
  card (long title, long description, a two-field pendency count, an
  in-progress upload) at 1.0x/1.5x/2.0x in en and fr to catch that; the test
  was checked against a real regression by briefly removing the breadcrumb's
  `Flexible` while writing it.
- **Every blocked-upload status must keep a distinct icon on
  `RecordingCard`.** `_statusIcon` gives `failed_conflict` `LucideIcons.copy`,
  `failed_description` `LucideIcons.fileText`, and (ENG-377)
  `failed_exhausted` `LucideIcons.alertOctagon` and `failed_missing_file`
  `LucideIcons.fileX`; the first two used to share `LucideIcons.alertCircle`,
  which made the two states visually identical once the label moved from
  painted text into the icon's tooltip/semantics — on this card the icon shape
  is the only signal a sighted user gets for which of them blocked a recording.
  `RecordingStatusSection`
  ([recording_status_section.dart](recording_status_section.dart)) keeps
  `failed_conflict` and `failed_description` on `LucideIcons.alertCircle`
  deliberately, because there the icon sits next to its own text label and does
  not need to carry the distinction alone — the two surfaces disagreeing on
  iconography for those states is known, not a bug, and aligning them would be
  a separate change. The ENG-377 pair matches across both surfaces only because
  they were written once, not because the surfaces were reconciled.
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
- **`ConfirmationStep._saveWebDirect` deletes the uploaded recording's bytes
  from browser storage once the upload succeeds (ENG-421).** On web the
  captured/imported audio bytes are read via `file_ops.readFileBytes` from
  the durable IndexedDB store in
  [/lib/core/platform/web_file_store.dart](../../../../core/platform/web_file_store.dart)
  (see [/lib/core/platform/docs.md](../../../../core/platform/docs.md)); once
  `DirectRecordingUploader.upload` returns a `serverId`, those bytes are
  redundant with the server's copy and `file_ops.deleteFile` removes them.
  This is a deliberate leak-prevention step, not cleanup of a bug: before the
  bytes were made durable the module-level map that held them died with the
  tab, capping the leak; persisting them (the ENG-421 fix) turned an
  already-small leak into an unbounded one that would grow with every saved
  recording and never be collected without this delete. The delete is wrapped
  in its own try/catch with `_log.warning` so a cleanup failure is never
  reported to the user as a failed upload — the upload already succeeded by
  that point.
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
