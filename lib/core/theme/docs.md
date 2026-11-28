# Noridoc: Theme

Path: @/lib/core/theme

### Overview

- The app's design-system foundation: the brand/semantic color palette and the
  `AppColorSet` `ThemeExtension` ([app_colors.dart](app_colors.dart)), the
  Material 3 `ThemeData` builders that style every widget
  ([app_theme.dart](app_theme.dart)), and the spacing/radii/motion/opacity
  design-token system (`app_spacing.dart` / `app_radii.dart` /
  [app_motion.dart](app_motion.dart) /
  [app_opacity.dart](app_opacity.dart) /
  [context_tokens.dart](context_tokens.dart), re-exported by
  [tokens.dart](tokens.dart)).
- This directory is the **single source of all `Color` construction** in the
  app. Alongside the themed palette it also holds the non-themed color machinery:
  the genre colours
  ([genre_colors.dart](genre_colors.dart)) and the runtime hex-string parser
  ([color_hex.dart](color_hex.dart)). Both live here because the `obt_lints`
  rules forbid raw `Color(...)` everywhere outside this folder.
- All token families follow one **hybrid** pattern: a source-of-truth scale
  (semantic color constants assembled into `AppColorSet`; `const` scales
  `SpacingScale` / `RadiusScale` / `MotionScale` /
  `OpacityScale`), a thin `ThemeExtension` that carries it and makes it
  theme-aware, and a resolver that reads the registered extension with a
  fallback.
- `AppColorSet` is the first `ThemeExtension`; `AppSpacing` / `AppRadii` /
  `AppMotion` / `AppOpacity` follow the same contract.
  Conventions, grid policy, and scope are governed by
  [ADR-0002](/docs/adr/ADR-0002-design-tokens.md).

### How it fits into the larger codebase

- `AppTheme.lightTheme` / `AppTheme.darkTheme` are installed into a `MaterialApp`
  in [../../main.dart](../../main.dart) (and the preview helpers); `themeMode:
  system` selects between them. This is the single registration point, so every
  screen inherits the palette and all token extensions.
- The same `MaterialApp` is also the single registration point for the app-wide
  **text-scale ceiling**: its `builder` wraps the whole tree in `AppFrame`, which
  applies `MediaQuery.withClampedTextScaling(maxScaleFactor: 2.0)` (ENG-171, foundation
  of the ENG-177 a11y program). This bounds the OS `textScaler` every screen
  reads, so pathological system font settings (>2×) cannot break layouts
  app-wide. Per-screen responsive layout (e.g. the Quick Recording ready state
  in
  [/lib/features/recording/presentation/widgets/recording_step.dart](/lib/features/recording/presentation/widgets/recording_step.dart),
  and the profile + project feature widgets in
  [/lib/features/profile/presentation/widgets](/lib/features/profile/presentation/widgets)
  /
  [/lib/features/project/presentation/widgets](/lib/features/project/presentation/widgets))
  handles scale *up to* that ceiling.
- Colors reach widgets two ways: Material components are styled from raw color
  constants baked into `ThemeData`, while app code reads semantic tokens via
  `AppColors.of(context)`, which resolves the registered `AppColorSet`. This
  folder is an upstream dependency of nearly every presentation layer but depends
  only on Flutter `material`.
- The semantic state tokens are `info`, `success`, `warning`, and `error`. They are
  single tokens with no text pair (callers tint both icon and label with the one color). `warning` is the
  caution/attention color (amber/orange): it backs the unclassified affordances
  (FABs, badges, breadcrumbs), `ForbiddenException`
  permission snackbars, and the `needs_cleaning` cleaning state via
  [/lib/shared/utils/cleaning_status_style.dart](/lib/shared/utils/cleaning_status_style.dart).
  It replaced the previously hardcoded `Colors.amber.shade700` / `Colors.orange`
  literals so those surfaces now adapt to dark mode. The recording detail
  screen's classify banner used to be one of the warning-tinted unclassified
  affordances; ENG-374 replaced it with the guided completion pill/sheet
  described in
  [/lib/features/recording/presentation/docs.md](/lib/features/recording/presentation/docs.md),
  which is deliberately primary-toned instead — an unfinished ficha is framed
  as work left to do, not a warning.
- `onPrimary` (ENG-374) is the content color for text/icons drawn on a
  `primary`-filled surface, e.g. the recording detail screen's
  `CompleteFichaPill`/`CompleteFichaSheet`
  ([/lib/features/recording/presentation/widgets/complete_ficha_pill.dart](/lib/features/recording/presentation/widgets/complete_ficha_pill.dart)).
  The Material `ColorScheme.onPrimary` reads the same pair in both themes (the
  page tone in light, `darkBackground` in dark), never pure white on cream.
- The kit's own roles (ENG-3004): `pale` (rest on a card), `tint` (switched-off
  button, selector track), `mic` (brick; the microphone and the record disc
  only, never a failure), `clay`, `sand`, `onColor` (sign on brick, tile and the
  two dark genre colours), `knob`, `count` (time of who is recording: brick in
  light, cream in dark) and `onSoft` (the sign on `soft`, the same terracotta in
  both themes). `error` is the terracotta of what failed, not brick.
- Spacing/radii/motion/opacity consumers reference the `const` scale directly
  (e.g. `SpacingScale.s16`, `RadiusScale.r12`,
  `MotionScale.base`, `OpacityScale.o40`) or the `context.spacing` / `.radii` /
  `.motion` / `.opacity` accessor. The spacing/radii call-site
  migration is now app-wide
  across [/lib/features](/lib/features) and [/lib/shared/widgets](/lib/shared/widgets):
  ENG-106 seeded the on-grid swaps on the densest screens and app chrome, ENG-163
  finished the value-identical long tail, and ENG-162 then ran the
  behavior-changing pass that snapped the off-grid stragglers onto tokens (see
  Grid policy and Migration in Things to Know). UI motion times are migrated
  across many widgets too — those were value-identical swaps with no behavior
  change.
- [app_theme.dart](app_theme.dart) is now itself a consumer of the `const`
  scales: its component themes read `RadiusScale` / `SpacingScale` /
  `OpacityScale` directly rather than repeating literals, because there is no
  `BuildContext` at `ThemeData`-build time (the `context.*` resolvers are
  unavailable, so it reads the same canonical scales those resolvers fall back
  to). This closes the prior "second source of truth" where the builders
  duplicated radii/spacing literals next to the scales.
- This directory (plus `test/`) is the **only** place raw `Color(...)` / bare
  `Colors.*` are allowed: the `obt_lints` custom_lint plugin
  ([/packages/obt_lints/docs.md](/packages/obt_lints/docs.md), ENG-159) flags
  them everywhere else and exempts these paths, so the palette here stays the
  design-token source of truth. ENG-183 burned the rest of the app's color
  literals down to **zero** outside this folder and promoted both rules
  `info`→`warning` (ADR-0007). To absorb that migration `AppColors` gained the
  neutral anchors `white`/`black`/`transparent` (pure primitives, distinct from
  the off-white `brandBranco` / near-black `brandPreto` brand tokens) plus a few
  long-tail semantic tokens (`authHeroAccent`); the genre
  accents live in `GenreColors` ([genre_colors.dart](genre_colors.dart)) and the runtime hex parser to [color_hex.dart](color_hex.dart).
- Token values and contracts are pinned by tests under
  [/test/core/theme/](/test/core/theme) (colors in `app_colors_test.dart`;
  spacing/radii/opacity and motion, the `context.*` accessor, the resolved
  component radii/padding, and the `ThemeData` registration in the
  `app_*`/`context_tokens` tests).

### Core Implementation

```
source of truth                       ThemeExtension (const fallback)        resolver
─────────────────────────────────────────────────────────────────────────────────────
AppColors raw consts ─► AppColorSet light/dark ─► ThemeData.extensions ─► AppColors.of(context)
SpacingScale/RadiusScale/MotionScale/OpacityScale ─► AppSpacing/AppRadii/AppMotion/AppOpacity ─► context.spacing/.radii/.motion/.opacity
                                                = Theme.of(context).extension<T>() ?? T.fallback
```

- **Registration.** `lightTheme` registers `AppColors.light`; `darkTheme`
  registers `AppColors.dark`; both register `AppSpacing.fallback`,
  `AppRadii.fallback`, `AppMotion.fallback`,
  `AppOpacity.fallback` — in a
  single `const <ThemeExtension<dynamic>>[...]` list per theme.
- **`AppColors.of(context)`** reads `Theme.of(context)`, prefers
  `extension<AppColorSet>()`, and only falls back to a brightness check when no
  extension is registered (bare `ThemeData` in tests/previews).
- **`context.motion`** reads `extension<AppMotion>() ?? AppMotion.fallback`;
  under `MediaQuery.maybeDisableAnimationsOf` it zeroes the six times and sets
  `still`. Curves, distances and `pressScale` do not change.
- **`context.spacing/radii/opacity`** ([context_tokens.dart](context_tokens.dart))
  read `Theme.of(context).extension<T>() ?? T.fallback`, so tokens still resolve
  under a bare `MaterialApp`.
- The `const` scales ([app_spacing.dart](app_spacing.dart),
  [app_radii.dart](app_radii.dart),
  [app_motion.dart](app_motion.dart),
  [app_opacity.dart](app_opacity.dart)) are `abstract final class`es of `static
  const` values; being `const` they let migrated sites keep their const-ness
  (e.g. `const EdgeInsets.all(SpacingScale.s16)`).
- Each `ThemeExtension` has a `const` constructor, `copyWith`, value `==` /
  `hashCode`, and a `lerp` (`Color.lerp` for colors, `lerpDouble` for
  spacing/radii/opacity) guarded with `if (other is! T) return this;`.
  `AppMotion.lerp` interpolates the durations with `lerpDuration` and `rise`,
  `slide` and `pressScale` with `lerpDouble`; the curves and `still` switch
  from `this` to `other` at `t = 0.5`. [app_theme.dart](app_theme.dart) also builds the typography
  and the component themes.
- **`GenreColors`** ([genre_colors.dart](genre_colors.dart)) is a
  `ThemeExtension` with the four genre brand colours (g1–g4) per mode, each with
  a tinted card background. `forGenre(index, id)` picks by list position, cycling
  every four, and returns `null` for the unclassified genre, which has no colour.
  Read it through `GenreColors.of(context)`.
- **`parseHexColor`** ([color_hex.dart](color_hex.dart)) turns a `#RRGGBB` /
  `RRGGBB` string into an opaque `Color`, returning a fallback (`AppColors.primary`
  by default) on null/malformed input. It lives here, not with the genre helpers,
  because its `Color(int.parse(...))` construction is raw color construction —
  allowed only under this folder. Its input is runtime data (e.g. a genre's
  server-supplied color), not a hardcoded literal. Callers are the
  genre/subcategory selection steps and the genre detail screen; the icon mapper
  it used to share a file with stays in
  [/lib/shared/utils/genre_helpers.dart](/lib/shared/utils/genre_helpers.dart).

### Things to Know

- **Invariant: the source-of-truth scale is canonical.** Each `ThemeExtension`
  defaults / falls back to it, so widgets resolve tokens even under bare
  `ThemeData` (tests, previews).
- **Text-scale invariant: high ceiling only, never a floor.** The
  `AppFrame` clamp (installed by the `builder` in [../../main.dart](../../main.dart)) uses
  `withClampedTextScaling(maxScaleFactor: 2.0)` with no `minScaleFactor`, so it
  only *lowers* extreme up-scaling and never raises the floor — low-vision users
  keep full up-scaling up to 2×. A symmetric/low clamp was explicitly rejected
  for that reason; resilience to large fonts is instead the responsibility of
  responsive layout — both in each feature screen and, since ENG-178, in the
  cross-cutting shared widget library
  ([/lib/shared/widgets/docs.md](/lib/shared/widgets/docs.md): scroll-when-overflow,
  `Flexible`+ellipsis, preserved fixed chrome). ENG-180 (Wave 3) extended this
  to the high-visibility profile + project feature widgets
  ([/lib/features/profile/presentation/widgets](/lib/features/profile/presentation/widgets),
  [/lib/features/project/presentation/widgets](/lib/features/project/presentation/widgets)),
  under one guiding principle: **let text grow/wrap where space allows; ellipsize
  only where width is locked** (a name beside a fixed chip or icon). Two
  techniques recur there: a shared `LanguageChipRow` (globe + `Flexible`,
  ellipsizing name + optional code chip) replaces the formerly-inline language
  rows so the name truncates instead of overflowing; and a **scale-aware
  `SliverAppBar` `expandedHeight`** (fixed top/bottom padding plus the
  text-bearing portion multiplied by the system `textScaler`) so the expanded
  project-settings header grows vertically with the font instead of clipping its
  title/language row. A third recurs in the home expandable-record FAB (ENG-185,
  a follow-up to ENG-181): a fixed-size corner box with hardcoded `Transform`
  offsets was replaced by an intrinsic, bottom-anchored layout whose action
  labels are width-capped by a `ConstrainedBox` and **wrap (never ellipsize)**,
  so long locales stay fully legible. Its failure mode is the one to watch for —
  clipping inside a `Stack` throws *no* overflow exception, so the regression is
  silent and must be caught by geometry assertions, not `expectNoOverflow`. Tests
  pump screens against this ceiling via
  [/test/support/text_scale.dart](/test/support/text_scale.dart).
- **Color/brightness invariant.** A registered `AppColorSet`'s brightness must
  match its `ThemeData.brightness` — `of()` prefers the extension and ignores
  brightness when one is present, so a mismatched pairing would hand back colors
  for the wrong mode. The builders pair light↔`AppColors.light`,
  dark↔`AppColors.dark`.
- **Grid policy.** The token scales are spacing {4,8,12,16,20,24,28,32,40,48}px
  and radii {4,8,12,16,20,24,28,32}px. The radius scale gained `r28`/`r32` in
  ENG-162 so it reaches parity with the spacing scale through 32; that extension
  exists specifically to give the snapped off-grid radii (34→32, 36→32) a real
  token to land on. Off-grid call-site literals were the deliberate stragglers
  ENG-106/ENG-163 left raw (those passes only swapped literals already equal to a
  token); ENG-162 then normalized the enumerated off-grid set onto the nearest
  token (see Migration below).
- **Opacity is not on the 4px grid.** `OpacityScale` is a named set of the
  distinct alpha values the theme actually uses (`o06`…`o70`), not a generated
  scale, so it has no on/off-grid policy — a value gets a token only because a
  component theme needs it.
- **The typography ramp has gaps — keep `copyWith(fontSize:)` when no token
  matches.** `_buildTextTheme` ([app_theme.dart](app_theme.dart)) defines the
  `textTheme.*` roles at a fixed set of sizes (display/headline/title/body/label),
  but several literal sizes consumers use have no exact token (e.g. 10, 14, and
  12@w400 — only `labelMedium` is 12, at w600). This is the typography analogue of
  the off-grid spacing stragglers in the Grid policy above. When a site moves from
  a hand-built `TextStyle(fontSize: N)` to a theme token, it starts from the
  nearest-role token (for size/weight/family/`height` defaults) and keeps an
  explicit `.copyWith(fontSize: N)` so the rendered size is unchanged. The
  surviving `fontSize` override is therefore intentional, not redundant — snapping
  it to a token would change the rendered size. Introducing a token for one of
  those sizes (so the override can drop) is a separate, possibly behavior-changing
  follow-up.
- **Every `textTheme` role bakes in `color: fg`, so themed `errorStyle` /
  `hintStyle` must set `color` explicitly.** `_buildTextTheme` applies `color: fg`
  (the theme foreground) to every role. A token used directly as an
  `InputDecoration.errorStyle` (or hint/helper) is merged by the `InputDecorator`,
  and the baked-in foreground wins over the decorator's semantic color — so a
  red error label would silently regress to the foreground color. A themed
  `errorStyle` must `copyWith(color: …error)` to preserve its meaning. (This is
  the same reason styles used on a colored chrome — e.g. nav items / badges on the
  primary surface — `copyWith(color: colorScheme.onPrimary)`; `onPrimary` is the
  page tone in light and `darkBackground` in dark, the same pair as the
  `AppColorSet.onPrimary` semantic token added in ENG-374 — see above.)
- **`MotionScale` is motion-only.** I/O timeouts and logic timers are excluded
  and remain raw `Duration`s. Notice motion and display times (`noticeJump`,
  `noticeDrop`, `noticeStay`, `noticeStayAction`) are constants of `MotionScale`.
- **Two migration passes, two contracts.** The *value-identical* passes
  (ENG-106/ENG-163, motion durations) swapped only literals already equal to a
  token value AND the direct argument of an `EdgeInsets` / `SizedBox` /
  `BorderRadius` / `Radius` / `Duration` constructor — no rendered change. ENG-162
  is the *behavior-changing* pass: it snaps the enumerated off-grid set
  {6,10,14,22,26,34, radius 36} onto the nearest token, so those sites move by a
  pixel or two. The snap map and tie-break are the single source of truth in
  [/tool/off_grid_snap_policy.dart](/tool/off_grid_snap_policy.dart): nearest
  token, and on an exact tie the multiple of 8 wins (round-half-to-even on the
  4px grid), giving spacing 6→s8, 10→s8, 14→s16, 22→s24, 26→s24, 34→s32 and the
  extra radius 36→r32. The policy is pinned by
  [/test/core/theme/off_grid_snap_test.dart](/test/core/theme/off_grid_snap_test.dart),
  which re-derives the maps from `nearestToken` so a wrong direction or a
  non-token target fails.
- **Both passes only touch direct constructor arguments — literals inside
  expressions stay raw** (e.g. `EdgeInsets.symmetric(horizontal: expanded ? 10 :
  0, vertical: SpacingScale.s8)`). ENG-162 enforces this structurally via an AST
  codemod ([/tool/snap_off_grid.dart](/tool/snap_off_grid.dart),
  `package:analyzer` unresolved parse) that rewrites a literal only when it is a
  direct argument of the spacing/radii constructors (and the spacing-denoting
  named args `spacing`/`runSpacing`/`mainAxisSpacing`/`crossAxisSpacing`,
  `SizedBox` width/height, `Gap`). So `Icon(size: 14)`, `fontSize: 14`, counts,
  and durations are left alone because they are not those constructors. The
  codemod has `--dry-run` / `--write` / `--verify` modes and is dev-only tooling
  (not shipped); `analyzer` is a pinned dev_dependency for it. The completeness
  guarantee that no in-policy off-grid literal survives is the codemod's
  `--verify`, not a unit test.
- **Naming.** Colors and motion are semantic (motion is named by meaning:
  `fast` / `base` / `slow`, `enter` / `leave`); spacing/radii/opacity are
  value-encoded (`sN` / `rN` = the literal px; `oNN` = the alpha's
  two decimal digits, e.g. `o40` = 0.4, `o06` = 0.06); no `md`/`lg` aliases
  (YAGNI).
- **`lerp` is effectively dormant in production** — [../../main.dart](../../main.dart)
  sets `themeAnimationDuration: Duration.zero`, so theme switches snap; the
  interpolation exists to satisfy the contract and enable future animation.
- **Token migration is now closed; a few literals stay raw on purpose.** Off-grid
  normalization (ENG-162) is done, so the spacing/radii token program — ENG-106
  (seed), ENG-115 ([app_theme.dart](app_theme.dart) consuming the `const` scales
  instead of inlining literals), ENG-163 (value-identical long tail), ENG-162
  (off-grid behavior-changing) — is closed. Two sets of literals are intentionally
  left raw: (1) the `lib/core/theme/` builder literals themselves, e.g. the
  elevated/filled-button `vertical: 14` padding in [app_theme.dart](app_theme.dart)
  — the ENG-162 codemod excludes this folder (and `l10n/`, generated `*.g.dart` /
  `*.freezed.dart`), since it is the token source of truth, not a consumer; and
  (2) non-enumerated stragglers outside the snapped set, e.g. radius 15 and
  `spacing 36` on fixed-size boxes (the codemod reports these as out-of-policy and
  leaves them, because 36 is a radius-only snap, never a spacing token). The
  `Color(0x…)` / bare `Colors.*` lint rule (ENG-76 / ENG-159) shipped as the
  `obt_lints` plugin, [/packages/obt_lints/docs.md](/packages/obt_lints/docs.md),
  and ENG-183/ENG-116 then burned the app's color literals down to zero outside
  this folder and promoted both rules to `warning`.
- **Screen transitions** ([screen_transition.dart](screen_transition.dart),
  ENG-3055): the themes map every `TargetPlatform` to a builder, so no route is
  edited. iOS and macOS keep Apple's slide and its edge swipe, also under less
  motion; the rest get the kit's slide. The root swaps in the web's map (fade
  only) from `isWebPlatformProvider` through `ScreenTransition.pick`, because a
  builder's time getters have no context and Apple's takes 500 ms where the
  fade takes 320.
- **Adding a token field is a multi-point edit** — thread it through the
  constructor, `copyWith`, `lerp`, `==`, `hashCode`, and the registered
  instances, or the equality/interpolation contracts break.

Created and maintained by Nori.
