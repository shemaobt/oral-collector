# Noridoc: Shared Widgets

Path: @/lib/shared/widgets

### Overview

- The cross-cutting widget library reused across nearly every feature screen:
  the app chrome (`app_shell.dart`'s responsive nav scaffold, composed from the
  mobile bottom bar / web sidebar sub-widgets in
  [app_shell/](app_shell), and
  [screen_header.dart](screen_header.dart)'s flat `AppBar`/`SliverAppBar`),
  list/section affordances ([empty_state.dart](empty_state.dart),
  `section_header.dart`, `status_banner.dart`), status chips
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
  the height between two. Colour defaults to the text colour around it. The
  screen reader says the text, or `label` when given. Only digits and `:`
  (asserted in debug); a duration, date or size in a list stays in the text
  typeface.
- [app_tile.dart](app_tile.dart) is the flat card, [row_group.dart](row_group.dart)
  stacks [app_row.dart](app_row.dart) and [app_data_row.dart](app_data_row.dart) in it.
- Stateless composition is the norm; stateful widgets exist only to own an
  animation: a `RotationTransition` while a status is in-flight (the upload badge's
  spinner creates/disposes an `AnimationController` in
  `didUpdateWidget`) and `LeavingRow`'s fade and height.
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
    [app_shell/floating_nav_bar.dart](app_shell/floating_nav_bar.dart), the 96px
    toolbar in `screen_header.dart`). They
    clip rather than grow, keeping the base design; content adapts *within* the
    fixed chrome. This mirrors the resilience approach in the feature screens:
    the recording flow
    ([/lib/features/recording/presentation/widgets](/lib/features/recording/presentation/widgets))
    and, since ENG-180, the profile + project widgets
    ([/lib/features/profile/presentation/widgets](/lib/features/profile/presentation/widgets),
    [/lib/features/project/presentation/widgets](/lib/features/project/presentation/widgets)).
  - `screen_header.dart` needed no change — its title/subtitle already ellipsize
    and fit the toolbar within the 2.0× ceiling; only regression guards were
    added.
- **`compact` font sizing uses `null` for the on-token size.** The upload badge sets
  `fontSize` to `null` in compact mode (which keeps `labelSmall`'s native 11)
  and only carries the off-token `13` as an explicit override — same typography
  convention as [/lib/core/theme/docs.md](/lib/core/theme/docs.md)'s "keep
  `copyWith(fontSize:)` when no token matches". No rendered-size change at 1.0×.
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

Created and maintained by Nori.
