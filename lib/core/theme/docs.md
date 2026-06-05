# Noridoc: Theme

Path: @/lib/core/theme

### Overview

- The app's design-system foundation: the brand/semantic color palette and the
  `AppColorSet` `ThemeExtension` ([app_colors.dart](app_colors.dart)), the
  Material 3 `ThemeData` builders that style every widget
  ([app_theme.dart](app_theme.dart)), and the spacing/radii/motion design-token
  system (`app_spacing.dart` / `app_radii.dart` / `app_durations.dart` /
  [context_tokens.dart](context_tokens.dart), re-exported by
  [tokens.dart](tokens.dart)).
- All token families follow one **hybrid** pattern: a source-of-truth scale
  (semantic color constants assembled into `AppColorSet`; `const` scales
  `SpacingScale` / `RadiusScale` / `DurationScale`), a thin `ThemeExtension` that
  carries it and makes it theme-aware, and a resolver that reads the registered
  extension with a fallback.
- `AppColorSet` is the first `ThemeExtension`; `AppSpacing` / `AppRadii` /
  `AppDurations` follow the same contract. Conventions, grid policy, and scope
  are governed by [ADR-0002](/docs/adr/ADR-0002-design-tokens.md).

### How it fits into the larger codebase

- `AppTheme.lightTheme` / `AppTheme.darkTheme` are installed into a `MaterialApp`
  in [../../main.dart](../../main.dart) (and the preview helpers); `themeMode:
  system` selects between them. This is the single registration point, so every
  screen inherits the palette and all token extensions.
- Colors reach widgets two ways: Material components are styled from raw color
  constants baked into `ThemeData`, while app code reads semantic tokens via
  `AppColors.of(context)`, which resolves the registered `AppColorSet`. This
  folder is an upstream dependency of nearly every presentation layer but depends
  only on Flutter `material`.
- Spacing/radii/motion consumers reference the `const` scale directly (e.g.
  `SpacingScale.s16`, `RadiusScale.r12`, `DurationScale.ms200`) or the
  `context.spacing` / `.radii` / `.durations` accessor. Migrated call sites
  include the recording screens and the app chrome
  ([/lib/shared/widgets/app_shell.dart](/lib/shared/widgets/app_shell.dart)),
  plus UI motion durations across many widgets — all value-identical literal
  swaps, no behavior change.
- Token values and contracts are pinned by tests under
  [/test/core/theme/](/test/core/theme) (colors in `app_colors_test.dart`;
  spacing/radii/durations, the `context.*` accessor, and the `ThemeData`
  registration in the `app_*`/`context_tokens` tests).

### Core Implementation

```
source of truth                       ThemeExtension (const fallback)        resolver
─────────────────────────────────────────────────────────────────────────────────────
AppColors raw consts ─► AppColorSet light/dark ─► ThemeData.extensions ─► AppColors.of(context)
SpacingScale/RadiusScale/DurationScale ─► AppSpacing/AppRadii/AppDurations ─► context.spacing/.radii/.durations
                                                = Theme.of(context).extension<T>() ?? T.fallback
```

- **Registration.** `lightTheme` registers `AppColors.light`; `darkTheme`
  registers `AppColors.dark`; both register `AppSpacing.fallback`,
  `AppRadii.fallback`, `AppDurations.fallback` — in a single
  `const <ThemeExtension<dynamic>>[...]` list per theme.
- **`AppColors.of(context)`** reads `Theme.of(context)`, prefers
  `extension<AppColorSet>()`, and only falls back to a brightness check when no
  extension is registered (bare `ThemeData` in tests/previews).
- **`context.spacing/radii/durations`** ([context_tokens.dart](context_tokens.dart))
  read `Theme.of(context).extension<T>() ?? T.fallback`, so tokens still resolve
  under a bare `MaterialApp`.
- The `const` scales ([app_spacing.dart](app_spacing.dart),
  [app_radii.dart](app_radii.dart), [app_durations.dart](app_durations.dart)) are
  `abstract final class`es of `static const` values; being `const` they let
  migrated sites keep their const-ness (e.g. `const
  EdgeInsets.all(SpacingScale.s16)`).
- Each `ThemeExtension` has a `const` constructor, `copyWith`, value `==` /
  `hashCode`, and a `lerp` (`Color.lerp` for colors, `lerpDouble` for
  spacing/radii, `lerpDuration` for motion) guarded with `if (other is! T)
  return this;`. [app_theme.dart](app_theme.dart) also builds the typography and
  the component themes.

### Things to Know

- **Invariant: the source-of-truth scale is canonical.** Each `ThemeExtension`
  defaults / falls back to it, so widgets resolve tokens even under bare
  `ThemeData` (tests, previews).
- **Color/brightness invariant.** A registered `AppColorSet`'s brightness must
  match its `ThemeData.brightness` — `of()` prefers the extension and ignores
  brightness when one is present, so a mismatched pairing would hand back colors
  for the wrong mode. The builders pair light↔`AppColors.light`,
  dark↔`AppColors.dark`.
- **Grid policy.** Only on-grid values are tokenized: spacing
  {4,8,12,16,20,24,28,32,40,48}px and radii {4,8,12,16,20,24}px. Off-grid
  stragglers (6/10/14/22/26/34, radius 36) are deliberately **not** tokens —
  normalizing them is a separate, behavior-changing follow-up.
- **`DurationScale` is motion-only.** I/O timeouts, logic timers, and
  snackbar/feedback display durations are excluded and remain raw `Duration`s.
- **Migration is pure.** Only literals already equal to a token value AND the
  direct argument of an `EdgeInsets` / `SizedBox` / `BorderRadius` / `Radius` /
  `Duration` constructor were swapped; literals inside expressions are left
  (e.g. `EdgeInsets.symmetric(horizontal: expanded ? 10 : 0, vertical:
  SpacingScale.s8)`).
- **Naming.** Colors are semantic; spacing/radii/durations are value-encoded
  (`sN` / `rN` / `msN` = the literal px or ms); no `md`/`lg` aliases (YAGNI).
- **`lerp` is effectively dormant in production** — [../../main.dart](../../main.dart)
  sets `themeAnimationDuration: Duration.zero`, so theme switches snap; the
  interpolation exists to satisfy the contract and enable future animation.
- **Deferred, per ADR-0002.** [app_theme.dart](app_theme.dart) still inlines its
  own internal radii/padding literals (to consume the `const` scale under
  ENG-115); the `Color(0x…)` / bare `Colors.*` lint rule (ENG-76 / ENG-159); and
  off-grid normalization.
- **Adding a token field is a multi-point edit** — thread it through the
  constructor, `copyWith`, `lerp`, `==`, `hashCode`, and the registered
  instances, or the equality/interpolation contracts break.

Created and maintained by Nori.
