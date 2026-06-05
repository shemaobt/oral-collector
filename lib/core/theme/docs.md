# Noridoc: Theme

Path: @/lib/core/theme

### Overview

- The app's design-system foundation: the color palette
  ([app_colors.dart](app_colors.dart)), the light/dark `ThemeData` builders
  ([app_theme.dart](app_theme.dart)), and the spacing/radii/motion design-token
  system (the `app_spacing.dart` / `app_radii.dart` / `app_durations.dart` /
  [context_tokens.dart](context_tokens.dart) quartet, re-exported by
  [tokens.dart](tokens.dart)).
- Tokens are **hybrid**: a `const` scale class per family is the single source of
  truth, a thin `ThemeExtension` per family makes it theme-aware, and a
  `BuildContext` accessor reads the extension with a fallback to the scale.
- Conventions, grid policy, and scope are governed by
  [ADR-0002](/docs/adr/ADR-0002-design-tokens.md) (ENG-106). This folder replaces
  ~800 scattered style magic numbers with one vocabulary.

### How it fits into the larger codebase

- [/lib/main.dart](/lib/main.dart) wires `AppTheme.lightTheme` and
  `AppTheme.darkTheme` into the `MaterialApp` as `theme:` / `darkTheme:` — this is
  the single registration point, so every screen inherits the palette and the
  registered token extensions.
- Widgets across every feature read colors via `AppColors.of(context)` (a
  brightness-aware selector) rather than hardcoded `Color(0x…)`. This folder is
  the canonical home for color literals; ADR-0002 reserves a future lint banning
  `Color(0x…)` / bare `Colors.*` elsewhere (ENG-76 / ENG-159).
- Spacing/radii/motion consumers reference the `const` scale directly (e.g.
  `SpacingScale.s16`, `RadiusScale.r12`, `DurationScale.ms200`) or the
  `context.*` accessor. Migrated call sites include the recording screens
  ([/lib/features/recording/presentation/recording_detail_screen.dart](/lib/features/recording/presentation/recording_detail_screen.dart),
  [/lib/features/recording/presentation/trim_editor_screen.dart](/lib/features/recording/presentation/trim_editor_screen.dart))
  and the app chrome
  ([/lib/shared/widgets/app_shell.dart](/lib/shared/widgets/app_shell.dart)),
  plus UI motion durations across many widgets.
- Those migrations were **value-identical literal swaps** — no behavior change —
  so the migrated feature folders' own `docs.md` are intentionally left untouched.
- The token extensions are registered for both light and dark `ThemeData`; values
  are brightness-invariant today, so the extension exists as the seam for future
  per-theme/density variation and the animated `lerp` hook, not for current
  divergence.

### Core Implementation

```
SpacingScale / RadiusScale / DurationScale   (const scale = source of truth)
        │ default field values
        ▼
AppSpacing / AppRadii / AppDurations          (ThemeExtension, const `fallback`)
        │ registered in ThemeData.extensions (light + dark)
        ▼
context.spacing / .radii / .durations         (TokenContext on BuildContext)
        = Theme.of(context).extension<T>() ?? T.fallback
```

- The `const` scales ([app_spacing.dart](app_spacing.dart),
  [app_radii.dart](app_radii.dart), [app_durations.dart](app_durations.dart)) are
  `abstract final class`es of `static const` values. Being `const` they are usable
  in `const` constructors, which is what lets migrated sites keep their
  const-ness (e.g. `const EdgeInsets.all(SpacingScale.s16)`).
- Each `ThemeExtension` defaults every field to its scale value, exposes a
  `static const fallback`, and implements `copyWith` / `lerp` / `==` / `hashCode`
  over its fields (`lerp` uses `lerpDouble` for spacing/radii and `lerpDuration`
  for motion).
- [app_theme.dart](app_theme.dart) registers `AppSpacing.fallback`,
  `AppRadii.fallback`, `AppDurations.fallback` in `ThemeData.extensions` inside
  both the `lightTheme` and `darkTheme` getters.
- [context_tokens.dart](context_tokens.dart) defines `extension TokenContext on
  BuildContext`, the ergonomic read surface for theme-reactive / dynamic code.
- [app_colors.dart](app_colors.dart) holds `AppColors` (brand swatches + named
  light & dark roles + Material surface containers) and `AppColorSet` (the
  per-brightness bundle returned by `AppColors.of(context)`).

### Things to Know

- **Invariant: the `const` scale is the single source of truth.** The
  `ThemeExtension` defaults to it and `context.*` falls back to it when the
  extension is unregistered — so widgets still resolve tokens under a bare
  `MaterialApp` (e.g. in tests) without a configured theme.
- **Grid policy.** Only on-grid values are tokenized: spacing
  {4,8,12,16,20,24,28,32,40,48}px and radii {4,8,12,16,20,24}px. Off-grid
  stragglers (6/10/14/22/26/34, radius 36) are deliberately **not** tokens —
  normalizing them is a separate, behavior-changing follow-up.
- **`DurationScale` is motion-only.** It covers UI/animation timings; I/O
  timeouts, logic timers, and snackbar/feedback display durations are
  deliberately excluded and remain raw `Duration`s.
- **Migration is pure.** Only literals that already equal a token value AND are
  the direct argument of an `EdgeInsets` / `SizedBox` / `BorderRadius` / `Radius`
  / `Duration` constructor were swapped. Literals inside expressions are left
  (e.g. `EdgeInsets.symmetric(horizontal: expanded ? 10 : 0, vertical:
  SpacingScale.s8)`), keeping the change value-identical.
- **Naming is value-encoded** (`sN` / `rN` / `msN` = the literal px or ms),
  chosen over t-shirt sizing because the dense 4px grid does not map onto a few
  semantic names; no `md`/`lg` aliases exist yet (YAGNI).
- **Deferred, per ADR-0002.** [app_theme.dart](app_theme.dart) still inlines its
  own internal radii/padding literals (to consume the scale under ENG-115), and
  colors are not yet a `ThemeExtension` (ENG-76 / ENG-159) — so today colors flow
  through `AppColors`, not `context.*`.

Created and maintained by Nori.
