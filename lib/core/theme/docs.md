# Noridoc: Theme

Path: @/lib/core/theme

### Overview

- The app's design-system foundation: the brand/semantic color palette and the
  `AppColorSet` `ThemeExtension` ([app_colors.dart](app_colors.dart)), the
  Material 3 `ThemeData` builders that style every widget
  ([app_theme.dart](app_theme.dart)), and the spacing/radii/motion/opacity
  design-token system (`app_spacing.dart` / `app_radii.dart` /
  `app_durations.dart` / [app_opacity.dart](app_opacity.dart) /
  [context_tokens.dart](context_tokens.dart), re-exported by
  [tokens.dart](tokens.dart)).
- This directory is the **single source of all `Color` construction** in the
  app. Alongside the themed palette it also holds the non-themed color machinery:
  the categorical/index-addressed decorative accent palettes
  ([app_palettes.dart](app_palettes.dart)) and the runtime hex-string parser
  ([color_hex.dart](color_hex.dart)). Both live here because the `obt_lints`
  rules forbid raw `Color(...)` everywhere outside this folder.
- All token families follow one **hybrid** pattern: a source-of-truth scale
  (semantic color constants assembled into `AppColorSet`; `const` scales
  `SpacingScale` / `RadiusScale` / `DurationScale` / `OpacityScale`), a thin
  `ThemeExtension` that carries it and makes it theme-aware, and a resolver that
  reads the registered extension with a fallback.
- `AppColorSet` is the first `ThemeExtension`; `AppSpacing` / `AppRadii` /
  `AppDurations` / `AppOpacity` follow the same contract. Conventions, grid
  policy, and scope are governed by
  [ADR-0002](/docs/adr/ADR-0002-design-tokens.md).

### How it fits into the larger codebase

- `AppTheme.lightTheme` / `AppTheme.darkTheme` are installed into a `MaterialApp`
  in [../../main.dart](../../main.dart) (and the preview helpers); `themeMode:
  system` selects between them. This is the single registration point, so every
  screen inherits the palette and all token extensions.
- The same `MaterialApp` is also the single registration point for the app-wide
  **text-scale ceiling**: its `builder` wraps the whole tree in
  `MediaQuery.withClampedTextScaling(maxScaleFactor: 2.0)` (ENG-171, foundation
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
- The semantic state tokens are `info`/`infoText`, `success`/`successText`,
  `warning`, and `error`. `info` and `success` carry a darker `*Text` companion
  for legible text-on-tint; `warning` and `error` are single tokens with no text
  pair (callers tint both icon and label with the one color). `warning` is the
  caution/attention color (amber/orange): it backs the unclassified affordances
  (FABs, badges, breadcrumbs, the classify banner), `ForbiddenException`
  permission snackbars, and the `needs_cleaning` cleaning state via
  [/lib/shared/utils/cleaning_status_style.dart](/lib/shared/utils/cleaning_status_style.dart).
  It replaced the previously hardcoded `Colors.amber.shade700` / `Colors.orange`
  literals so those surfaces now adapt to dark mode.
- Spacing/radii/motion/opacity consumers reference the `const` scale directly
  (e.g. `SpacingScale.s16`, `RadiusScale.r12`, `DurationScale.ms200`,
  `OpacityScale.o40`) or the `context.spacing` / `.radii` / `.durations` /
  `.opacity` accessor. Migrated call sites include the recording screens and the
  app chrome
  ([/lib/shared/widgets/app_shell.dart](/lib/shared/widgets/app_shell.dart)),
  plus UI motion durations across many widgets — all value-identical literal
  swaps, no behavior change.
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
  long-tail semantic tokens (`meterWarning`, the `warningContainer` /
  `onWarningContainer` storage-banner pair, `authHeroAccent`); the categorical
  decorative accents moved to `AppPalettes` ([app_palettes.dart](app_palettes.dart),
  ENG-116) and the runtime hex parser to [color_hex.dart](color_hex.dart).
- Token values and contracts are pinned by tests under
  [/test/core/theme/](/test/core/theme) (colors in `app_colors_test.dart`;
  spacing/radii/durations/opacity, the `context.*` accessor, the resolved
  component radii/padding, and the `ThemeData` registration in the
  `app_*`/`context_tokens` tests).

### Core Implementation

```
source of truth                       ThemeExtension (const fallback)        resolver
─────────────────────────────────────────────────────────────────────────────────────
AppColors raw consts ─► AppColorSet light/dark ─► ThemeData.extensions ─► AppColors.of(context)
SpacingScale/RadiusScale/DurationScale/OpacityScale ─► AppSpacing/AppRadii/AppDurations/AppOpacity ─► context.spacing/.radii/.durations/.opacity
                                                = Theme.of(context).extension<T>() ?? T.fallback
```

- **Registration.** `lightTheme` registers `AppColors.light`; `darkTheme`
  registers `AppColors.dark`; both register `AppSpacing.fallback`,
  `AppRadii.fallback`, `AppDurations.fallback`, `AppOpacity.fallback` — in a
  single `const <ThemeExtension<dynamic>>[...]` list per theme.
- **`AppColors.of(context)`** reads `Theme.of(context)`, prefers
  `extension<AppColorSet>()`, and only falls back to a brightness check when no
  extension is registered (bare `ThemeData` in tests/previews).
- **`context.spacing/radii/durations/opacity`** ([context_tokens.dart](context_tokens.dart))
  read `Theme.of(context).extension<T>() ?? T.fallback`, so tokens still resolve
  under a bare `MaterialApp`.
- The `const` scales ([app_spacing.dart](app_spacing.dart),
  [app_radii.dart](app_radii.dart), [app_durations.dart](app_durations.dart),
  [app_opacity.dart](app_opacity.dart)) are `abstract final class`es of `static
  const` values; being `const` they let migrated sites keep their const-ness
  (e.g. `const EdgeInsets.all(SpacingScale.s16)`).
- Each `ThemeExtension` has a `const` constructor, `copyWith`, value `==` /
  `hashCode`, and a `lerp` (`Color.lerp` for colors, `lerpDouble` for
  spacing/radii/opacity, `lerpDuration` for motion) guarded with `if (other is!
  T) return this;`. [app_theme.dart](app_theme.dart) also builds the typography
  and the component themes.
- **`AppPalettes`** ([app_palettes.dart](app_palettes.dart)) holds the
  categorical accent palettes that were previously inline `Color(0x…)` arrays in
  feature widgets — the genre-card and project-card accent lists plus the hero
  genre-card accent and the default scrolling-waveform cursor. It exposes the
  two `const List<Color>` palettes and pure helpers `genreAccent(int)` /
  `projectAccent(int)` that pick by list position, cycling via `index % length`.
  These are addressed by *index*, not by a `ColorScheme` role, so they are
  non-semantic and do not belong in `AppColorSet`. Deliberately a plain
  `abstract class` of `static const` — **not** a `ThemeExtension` — because the
  palettes are single-theme and fixed (value-identical), so `lerp`/`copyWith`
  would be dead weight.
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
  [../../main.dart](../../main.dart) `builder` clamp uses
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
  title/language row. Tests pump screens against this ceiling via
  [/test/support/text_scale.dart](/test/support/text_scale.dart).
- **Color/brightness invariant.** A registered `AppColorSet`'s brightness must
  match its `ThemeData.brightness` — `of()` prefers the extension and ignores
  brightness when one is present, so a mismatched pairing would hand back colors
  for the wrong mode. The builders pair light↔`AppColors.light`,
  dark↔`AppColors.dark`.
- **Grid policy.** Only on-grid values are tokenized: spacing
  {4,8,12,16,20,24,28,32,40,48}px and radii {4,8,12,16,20,24}px. Off-grid
  stragglers (6/10/14/22/26/34, radius 36) are deliberately **not** tokens —
  normalizing them is a separate, behavior-changing follow-up. In particular the
  off-grid `vertical: 14` in the elevated/filled button padding stays a raw
  literal even though the surrounding `horizontal: SpacingScale.s28` was
  tokenized.
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
  one token that is pure white in both light and dark, so it preserves a former
  `Colors.white` literal value-for-value.)
- **`DurationScale` is motion-only.** I/O timeouts, logic timers, and
  snackbar/feedback display durations are excluded and remain raw `Duration`s.
- **Migration is pure.** Only literals already equal to a token value AND the
  direct argument of an `EdgeInsets` / `SizedBox` / `BorderRadius` / `Radius` /
  `Duration` constructor were swapped; literals inside expressions are left
  (e.g. `EdgeInsets.symmetric(horizontal: expanded ? 10 : 0, vertical:
  SpacingScale.s8)`).
- **Naming.** Colors are semantic; spacing/radii/durations/opacity are
  value-encoded (`sN` / `rN` / `msN` = the literal px or ms; `oNN` = the alpha's
  two decimal digits, e.g. `o40` = 0.4, `o06` = 0.06); no `md`/`lg` aliases
  (YAGNI).
- **`lerp` is effectively dormant in production** — [../../main.dart](../../main.dart)
  sets `themeAnimationDuration: Duration.zero`, so theme switches snap; the
  interpolation exists to satisfy the contract and enable future animation.
- **Deferred, per ADR-0002.** Off-grid normalization (e.g. the button `vertical:
  14` literal). (ENG-115 — [app_theme.dart](app_theme.dart) consuming the `const`
  radii/spacing/opacity scales instead of inlining its own literals — is done;
  the `Color(0x…)` / bare `Colors.*` lint rule (ENG-76 / ENG-159) shipped as the
  `obt_lints` plugin, [/packages/obt_lints/docs.md](/packages/obt_lints/docs.md),
  and ENG-183/ENG-116 then burned the app's color literals down to zero outside
  this folder and promoted both rules to `warning`.)
- **Adding a token field is a multi-point edit** — thread it through the
  constructor, `copyWith`, `lerp`, `==`, `hashCode`, and the registered
  instances, or the equality/interpolation contracts break.

Created and maintained by Nori.
