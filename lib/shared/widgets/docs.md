# Noridoc: Shared Widgets

Path: @/lib/shared/widgets

### Overview

- The cross-cutting widget library reused across nearly every feature screen:
  the app chrome (`app_shell.dart`'s responsive nav scaffold, composed from the
  mobile bottom bar / web sidebar sub-widgets in
  [app_shell/](app_shell), and
  [screen_header.dart](screen_header.dart)'s flat `AppBar`/`SliverAppBar`),
  list/section affordances ([empty_state.dart](empty_state.dart),
  `section_header.dart`, `status_banner.dart`), send-state signs and words
  ([upload_status_badge.dart](upload_status_badge.dart),
  `sync_status_indicator.dart`), and dialogs/sheets/inputs.
- A screen is built only from these pieces and the tokens, and a new piece
  enters here before any screen uses it:
  [ADR-0012](/docs/adr/ADR-0012-screens-use-only-kit-pieces.md).
- Presentation-only: these widgets read design tokens from
  [/lib/core/theme](/lib/core/theme) (`AppColors.of(context)`, the `const`
  scales) and localized strings from [/lib/l10n](/lib/l10n), and surface
  state owned elsewhere — they hold only local UI state (animation
  controllers, expand/collapse).

### How it fits into the larger codebase

- `AppShell` is the persistent shell wrapped around the router's `ShellRoute`
  in [/lib/core/router/app_router.dart](/lib/core/router/app_router.dart); it
  hosts the bottom nav (mobile) / collapsible sidebar (web), the global FAB,
  and reads Riverpod state (auth/role, the recording session, invites) to gate
  tab navigation through the recording navigation guard. Every routed screen
  renders inside it.
- `ScreenHeader` / `ScreenHeaderSliver` are the standard per-screen `AppBar`,
  used by the home, recordings, projects, profile, and recording-flow screens.
- `EmptyState` is the shared "no content yet" placeholder for the recordings,
  projects, and storytellers lists.
- These widgets are downstream of [/lib/core/theme](/lib/core/theme) (their
  only design dependency) and of [/lib/l10n](/lib/l10n); they do not own domain
  state, so they fit the app as a thin, reusable presentation layer over the
  feature notifiers.

### Core Implementation

- [brush_sign.dart](brush_sign.dart) draws the kit's 47 brush signs (`Sign`)
  from outlines held as text in `brush_signs.dart`, which is generated from the
  kit's `ia/s-*.svg` and never edited by hand. A `BrushSign` stands where an
  `Icon` stood: size and colour default to the `IconTheme`. `label` makes it an
  image for screen readers; with none it is skipped. `turns` rotates it («close»
  is `plus` at 0.125, «open list» is `next` at 0.25). `back` and `next` mirror
  under a right-to-left locale.
- [brush_number.dart](brush_number.dart) writes a count or the recording time
  in the kit's ten brush numbers and a colon (`Glyph`, held in
  `brush_signs.dart` and generated from `ia/n-*.svg`). `height` is multiplied
  by the text scale; width follows from each character's own width plus 0.04 of
  the height between two, or, with `tabular`, every digit takes the widest
  digit's slot (equal-width digit slots) so the width holds as digits change. Colour defaults to the text colour around it. The
  screen reader says the text, or `label` when given. Only digits and `:`
  (asserted in debug); a duration, date or size in a list stays in the text
  typeface.
- [recording_clock.dart](recording_clock.dart) is the recording time in brush
  numbers (`formatClock`, hours only from one hour on), `count` colour, `secondary`
  when `paused`, `height` 72 unless asked. It is `tabular`.
- [sound_strokes.dart](sound_strokes.dart) paints the kit's strokes of sound
  in `color` behind its `child` (a disc of `diameter`) while `sounding`: a box
  138% of the disc, centred, under the child, no taps, no semantics, still. Not
  sounding, it paints nothing and the child stays mounted. The disc's own sign
  size is `RoundButton.signSize` (default 18).
- [call_ring.dart](call_ring.dart) is the same piece for the kit's hand-drawn
  ring that calls (`calling`); [outline_halo.dart](outline_halo.dart) is the box
  both share. `RecordButton` draws the ring when `calling` and ready, the
  microphone sign when ready or paused, the stop sign with the strokes while
  recording. Only the disc swells; the ring and the strokes stay still.
- [app_tile.dart](app_tile.dart) is the flat card, [row_group.dart](row_group.dart)
  stacks [app_row.dart](app_row.dart) and [app_data_row.dart](app_data_row.dart) in it.
- Stateless composition is the norm; stateful widgets exist only to own an
  animation (`LeavingRow`'s fade and height). Nothing spins: the upload state
  is a sign or a word.
- All color and spacing come from theme tokens, never raw literals (enforced by
  the `obt_lints` plugin outside `lib/core/theme/**`); strings come from
  `AppLocalizations.of(context)`.
- **Text-scale resilience (ENG-178)** is built into the layout shape, not added
  as an afterthought (see Things to Know).

### Things to Know

- **Switching tabs away from the confirmation form is a second way out of it,
  and it offers the same three doors (ENG-518, slice 2).**
  `_AppShellState._navigateToTab` sees the form through
  `pendingRecordingDecisionProvider`, and used to show its own copy of the
  discard dialog — stay, or delete the audio. It now calls the shared
  `showLeaveRecordingDialog`
  ([/lib/features/recording/presentation/widgets/leave_recording_dialog.dart](/lib/features/recording/presentation/widgets/leave_recording_dialog.dart)),
  the same one the back button uses, and keeping parks the session instead of
  deleting the file. Fixing only the back button would have left the hole open
  down a path people use just as much.
- **Text-scale resilience is a contract here.** Because these widgets render on
  nearly every screen, they must survive the system `TextScaler` up to the
  app-wide **2.0× ceiling** (the global clamp in
  [/lib/main.dart](/lib/main.dart); invariant documented in
  [/lib/core/theme/docs.md](/lib/core/theme/docs.md)) without `RenderFlex`
  overflow or hidden controls. The clamp is only a ceiling — staying laid-out
  *up to* it is this layer's responsibility. The toolkit, applied consistently:
  - **Scroll-when-overflow** for centered content: `EmptyState` wraps its
    icon/title/description/action column in
    `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight: viewport)
    → IntrinsicHeight`, so it stays centered when it fits and scrolls instead of
    overflowing when large fonts make it taller than the viewport.
  - **`Flexible` + `maxLines: 1` + `TextOverflow.ellipsis`** for labels under
    width pressure: the status-badge label and the web sidebar's brand name
    (in [app_shell/web_sidebar.dart](app_shell/web_sidebar.dart)) degrade by
    ellipsizing rather than overflowing.
  - **Fixed nav-chrome heights are intentionally preserved** (the mobile bottom
    bar / nav item in
    [app_shell/floating_nav_bar.dart](app_shell/floating_nav_bar.dart), the top in `screen_header.dart` is the exception, see below). They
    clip rather than grow, keeping the base design; content adapts *within* the
    fixed chrome. This mirrors the resilience approach in the feature screens:
    the recording flow
    ([/lib/features/recording/presentation/widgets](/lib/features/recording/presentation/widgets))
    and, since ENG-180, the profile + project widgets
    ([/lib/features/profile/presentation/widgets](/lib/features/profile/presentation/widgets),
    [/lib/features/project/presentation/widgets](/lib/features/project/presentation/widgets)).
  - `screen_header.dart` has a minimum row height that grows with the title up to
    its own 1.3× text ceiling; the back disc and each action are semantic nodes
    apart from the title's heading.
- **`UploadStatusBadge` draws a send state as a word or a sign, never a pill.**
  `compact` is the row form (check alone, word, or the 32 disc); the page form
  is the sign at 18 then the word at 15/600. No retry lives here.
- **The status badge is currently unused in the app.**
  `UploadStatusBadge` has no call sites yet; it was hardened as shared-library
  hygiene so it is safe when wired up.
- **`HandCutRectPainter`** ([hand_cut_rect.dart](hand_cut_rect.dart)) is the
  kit's rectangle cut by hand: outline wobbles per axis by 0.012 × the short side
  (at least 0.35, at most 1.1 from a short side of 92); the combined shift of a
  point can exceed 1.1 (1.21 at 200×100, inherited from `sheetOutline`). The
  seed derives from the size (stable across rebuilds). With a `shadow` colour it paints the
  same shape shifted by `shadowOffset` (default 3 right, 4 down; 2 and 3 for
  small pieces), no blur, in physical directions so RTL does not flip it. Colours
  come from the caller; only pressable pieces pass a shadow.
- **`AppDisc` is the kit's disc cut by hand** ([app_disc.dart](app_disc.dart),
  [hand_cut_disc.dart](hand_cut_disc.dart)): one closed curve scaled to the
  diameter, sign at 46%. The tone says what the disc tells (fill and sign); the
  printed shadow (the same outline 3.7% right and 4.2% down, no blur, physical
  directions so RTL does not flip it) is painted only when `pressable` is set,
  never when `enabled` is false (the disc is then at 40%), and never inside a
  piece that already paints one (`PrintedShadowScope`, which a piece with a
  printed shadow puts around its child). Shadow colours: `PrintedShadows`.
- **`Pressable` and `PressLook` are the app's answer to a touch**
  ([pressable.dart](pressable.dart)): held, the piece shrinks by `MotionScale`'s
  `pressScale` over `pressIn` and darkens by the same amount; let go, it springs
  back over `pressOut` with `pressBack`. With less motion it only darkens. `Pressable` keeps `InkWell`'s focus, Enter and
  Space, cursor and tap target, and shows nothing when it has nothing to do.
  It follows the pointer, not Material's pressed state, so it answers at once in
  scroll views. `RoundButton`, `RecordButton` and the button pieces use it; the theme turns the spreading ink
  off everywhere (`NoSplash`).
- **`SlabCard` is the kit's dark block** ([slab_card.dart](slab_card.dart)): a
  hand-cut sheet (no printed shadow) in `primary`, `sand` in dark, with a brush
  title and `SlabRow`s (an `int` count in brush in one column, 32 at text scale 1 or as wide as the widest count, so the words line up
  across rows; words, action word and chevron). The
  line between rows is the ink at 16% (22% in dark), none after the last.
  **`StatTile`** ([stat_tile.dart](stat_tile.dart)) is a project number: runs of
  digits in brush, the rest as small text, and one semantic label with the value
  and the word. The theme's `dataTableTheme` gives every `DataTable` the kit's
  quiet heading, 46-high rows and 1 px `border` lines.
- **`StatusBanner`** ([status_banner.dart](status_banner.dart)) is a notice on a
  hand-cut sheet in one of three tones: calm (`pale`), attention (`wood`) or
  failed (`soft`, text in `onSoft`). **`NeedsYouBlock`**
  ([needs_you_block.dart](needs_you_block.dart)) is the «Precisa de você» block:
  a brush title, one sentence and the button that solves it, passed in as a
  widget and held to the block's width at 44 high.
- **Regression coverage** lives in
  [/test/shared/widgets](/test/shared/widgets), pumping each widget at the
  ceiling via [/test/support/text_scale.dart](/test/support/text_scale.dart)
  (`pumpAtTextScale` / `expectNoOverflow`) on a realistic phone viewport.

- **`LeavingRow` is a switch on a row, not an `AnimatedList`.** The caller keeps
  the row in the list it builds and flips `gone`; the row fades and slides
  (`fast`, `leave`), then its height closes (`base`, `enter`); `gone: false`
  opens the height, then fades the row in rising. The `gap` between rows lives
  inside the helper so it closes with the row. The row stays mounted at zero
  height while gone, so its child keeps its state through leave and return; it
  takes no taps, focus or semantics, and on the way back takes taps only once
  whole. Turning back mid-flight continues from the current frame. Under
  `context.motion` with less motion asked, gone and back are cuts in one frame.
  Caller contract: give every item's row a key (`ValueKey(item.id)`), or after a
  drop the next row inherits the collapsed state and plays the come-back; flip
  `gone` before any `await`, so the row leaves while the work runs; dropping the
  item from the list mid-leave snaps the row out: the list shortens in one frame.

- **`NameAndState`** ([name_and_state.dart](name_and_state.dart)) lays out a
  row's name and end state: the state shows whole on one line, the name gives
  way with an ellipsis, and only below 48 px of name does the state end in one.

- **`UpdatingLine`** ([updating_line.dart](updating_line.dart)) wraps a whole
  `Scaffold` and takes one switch, `checking`. A 3-high line is drawn over the
  content, below the status bar, only after the check lasted 250 ms (an
  animation clock, not a `Timer`): fades in on `enter`, out on `leave`, and a
  38% stroke runs across in 1100 ms (reversed under right-to-left). Screen
  readers hear `common_updating` once. With less motion asked, one still
  stroke fills the width.

- **`showAppSheet`** ([app_sheet.dart](app_sheet.dart)) is the one way a sheet
  opens: its own route. The frame (corner 26, grab) is the helper's; content
  leaves the top 24 free. The keyboard's insets are never read. `constraints`
  caps the sheet's width; `useRootNavigator` pushes it on the root navigator.
- **`showQuickNotice`** ([quick_notice.dart](quick_notice.dart)) says a short
  message on a hand-cut bar on the root `Overlay`, margin to margin. A new
  notice replaces the one on screen at once. Tones:
  calm and failed (`error`). It jumps in (`base`, `noticeJump`), stays
  `noticeStay` even under less motion, leaves in `fast`; a live region. An
  `action` (word and callback; `.undo` says «Desfazer») at its end keeps it
  `noticeStayAction` and runs once, on a tap. A downward swipe sends it away.
  It stands 10 above the safe area, the keyboard and the bar of a visible
  `QuickNoticeFloor` (the shell's body), read live; `quickNoticeOf(context)`
  takes a handle before an `await` to show one after the caller is gone.

- **`AppOption`** ([app_option.dart](app_option.dart)) is one choice among
  several, with a title and an optional explanation: hand-cut, `card` at rest,
  `primary` with the `check` sign at the end when chosen. It paints its own
  printed shadow and puts a `PrintedShadowScope` around its content. The caller
  owns the selection and the gap between options; a screen reader hears each as
  one choice of a group, with title and explanation.
- **`AppSelector`** ([app_selector.dart](app_selector.dart)) switches between up
  to three views of one list (asserted): a `tint` track, equal parts, the chosen
  part hand-cut (`card`, `pale` in dark). Labels wrap rather than clip; a count
  is part of the label the caller passes. The choice changes at once, with no
  slide.

- **`AppField`** ([app_field.dart](app_field.dart)) is the one text field a screen
  may use. It wraps `TextFormField` and takes its whole look from the theme; it
  has no style of its own. `onCard` gives the on-a-card field.
  `enabled: false` switches it off.

- **`AppTick` and `AppSwitch`** ([app_tick.dart](app_tick.dart),
  [app_switch.dart](app_switch.dart)) are the kit's hand-cut tick (26 square,
  `check` sign when marked) and switch (52 × 30, knob at the start edge off, the
  end edge on). Both keep their own size under any parent and take the keyboard.
  They paint the printed shadow unless switched off (`onChanged` null, then 40%)
  or inside a piece that paints one. The tick takes an optional `label` that is
  tappable and read once; the knob and the label follow the reading direction.
  The state changes at once, with no slide. No screen uses them yet; the
  theme's Material switch and tick take the kit's colours until each screen
  moves.

- **`AppChoice`** ([app_choice.dart](app_choice.dart)) is the kit's choose-one: a
  hand-drawn ring with a disc inside when chosen, no printed shadow, 26 square.
  It keeps that size under any parent and takes the keyboard. It takes an
  optional `label` that is tappable and read once; `onChosen` null switches it
  off (40%). The state changes at once, with no slide. No screen uses it yet.

- **`AppFilterChoice` and `AppActiveFilter`**
  ([app_filter_choice.dart](app_filter_choice.dart),
  [app_active_filter.dart](app_active_filter.dart)) are the two filter pieces.
  The choice sits in the filter sheet: hand-cut, 38 high in a touch area of 44,
  `card` at rest with the paper shadow, `primary` with the ink shadow when
  chosen. The active filter sits in the list: 36 high in 44, `primary`, no
  shadow, the name then a «close» sign; one tap on it calls `onRemove`, and a
  screen reader hears «Tirar o filtro {name}». No screen uses them yet. The
  theme's Material chips (`card`, no line, corners 12) and tabs (`primary` line
  of 2 under the chosen tab, a `border` line under the row) wear the same look
  until each screen moves.

- **`showAppQuestion`** ([app_question.dart](app_question.dart)) opens a question
  on its own route: a title, one line, the caller's buttons (they pop the
  answer). A ground tap pops null unless `isDismissible` is false. It enters in
  `base` rising `rise`, leaves in `fast` in place, and scrolls if it overflows. **`showAppDialog`** gives the
  same ground and motion to a child the caller builds (an `AlertDialog`); every
  question opens through one of the two.

- **`ProgressBeads`** ([progress_beads.dart](progress_beads.dart)) shows an
  upload as ten hand-cut beads in a 140 × 10 strip, one every 14, whole beads
  only: `percent ~/ 10` are lit (`accent`), the rest `pale`; clamped to 0–10.
  Lit beads start at the leading edge, so at the right under right-to-left.
  A bead lights at once, with no animation. Decoration beside a word the
  caller writes («Enviando 42%»): left out of semantics.
- **`TodoMark`** ([todo_mark.dart](todo_mark.dart)) is what is still to do: a
  dashed circle of 13 (stroke 1.5, no fill), 6 apart, then the caller's `label`
  at 13, weight 500, all in `foreground`; no fill and no outline around the
  word.
- **`ClayBar`** ([clay_bar.dart](clay_bar.dart)) is a still bar of clay where
  content will arrive: hand-cut, `clay` at 40%, `height` 14 by default, as wide
  as `width` or as the space it is given. It never animates. Left out of
  semantics: the screen labels a group of bars («Carregando»).

- **`AppButton`** ([app_button.dart](app_button.dart)) is the kit's pressable
  word, built on [hand_cut_button_style.dart](hand_cut_button_style.dart):
  `ink` (the main one) or `quiet`; `quietOnCard` when it stands on a card. An
  optional `sign` leads the word. Off (`onPressed: null`) it takes the `tint`
  fill and no printed shadow; inside a `PrintedShadowScope` it paints none
  either. The focus tint shows only under keyboard navigation. `small` makes
  it 44 high; `danger` is the terracotta button, for inside the question that
  confirms and nowhere else.
- **`AppWordButton`** ([app_word_button.dart](app_word_button.dart)) is a
  word in `error` («Descartar») with no fill and no printed shadow.
- **`AppLink`** ([app_link.dart](app_link.dart)) is an underlined word
  («Ver todas») with no fill. The underline sits flush with the word: Flutter
  has no offset for it, so the kit's 4px gap is not drawn.
- **`AppSignButton`** ([app_sign_button.dart](app_sign_button.dart)) is a lone
  sign with no ring and a touch area of 44 by 44. `semanticLabel` names it for
  the screen reader, which can press it.

Created and maintained by Nori.
