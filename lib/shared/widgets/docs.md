# Noridoc: Shared Widgets

Path: @/lib/shared/widgets

### Overview

- The cross-cutting widget library reused across nearly every feature screen:
  the app chrome (`app_shell.dart`'s responsive nav scaffold, composed from the
  mobile bottom bar / web sidebar sub-widgets in
  [app_shell/](app_shell), and
  [screen_header.dart](screen_header.dart)'s gradient `AppBar`/`SliverAppBar`),
  list/section affordances ([empty_state.dart](empty_state.dart),
  `section_header.dart`, `status_banner.dart`), status chips
  ([cleaning_status_badge.dart](cleaning_status_badge.dart),
  [upload_status_badge.dart](upload_status_badge.dart),
  `sync_status_indicator.dart`), and dialogs/sheets/inputs.
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
- The cleaning chip delegates status→icon/color/label mapping to
  [/lib/shared/utils/cleaning_status_style.dart](/lib/shared/utils/cleaning_status_style.dart),
  keeping the badge purely visual.

### Core Implementation

- Stateless composition is the norm; stateful widgets exist only to drive a
  `RotationTransition` while a status is in-flight (the badges' "cleaning" /
  "uploading" spinners create/dispose an `AnimationController` in
  `didUpdateWidget`) or to track collapse state in the web sidebar
  ([app_shell/web_sidebar.dart](app_shell/web_sidebar.dart)).
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
    width pressure: the status-badge labels and the web sidebar's collapse-toggle
    label (in [app_shell/web_sidebar.dart](app_shell/web_sidebar.dart)) degrade by
    ellipsizing rather than overflowing. The collapse toggle was the only
    unprotected text in the sidebar and the single real overflow found.
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
- **`compact` font sizing uses `null` for the on-token size.** The badges set
  `fontSize` to `null` in compact mode (which keeps `labelSmall`'s native 11)
  and only carry the off-token `13` as an explicit override — same typography
  convention as [/lib/core/theme/docs.md](/lib/core/theme/docs.md)'s "keep
  `copyWith(fontSize:)` when no token matches". No rendered-size change at 1.0×.
- **The two status badges are currently unused in the app.**
  `CleaningStatusBadge` is intended for the recording status section (per its
  style's doc comment) and `UploadStatusBadge` has no call sites yet; both were
  hardened as shared-library hygiene so they are safe when wired up.
- **Regression coverage** lives in
  [/test/shared/widgets](/test/shared/widgets), pumping each widget at the
  ceiling via [/test/support/text_scale.dart](/test/support/text_scale.dart)
  (`pumpAtTextScale` / `expectNoOverflow`) on a realistic phone viewport.

Created and maintained by Nori.
