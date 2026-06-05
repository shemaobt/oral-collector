# Noridoc: Core Theme

Path: @/lib/core/theme

### Overview

- Owns the app's design-token foundation: the brand/semantic color palette
  ([app_colors.dart](app_colors.dart)) and the Material 3 `ThemeData` builders
  that style every widget ([app_theme.dart](app_theme.dart)).
- `AppColorSet` is the first `ThemeExtension` in the codebase. It carries the
  semantic color tokens and implements the `copyWith` / `lerp` / equality
  contract, establishing the pattern intended for future token sets
  (e.g. spacing, radii).
- Colors reach widgets two ways: Material components are styled from raw color
  constants baked into `ThemeData`, while app code reads semantic tokens via
  `AppColors.of(context)`, which resolves the registered `AppColorSet`.

### How it fits into the larger codebase

- `AppTheme.lightTheme` / `AppTheme.darkTheme` are installed into a
  `MaterialApp` in [../../main.dart](../../main.dart) (the production app) and
  in [../../shared/preview_helpers.dart](../../shared/preview_helpers.dart)
  (widgetbook/device previews). These are the only places the themes are wired
  in; `themeMode: ThemeMode.system` selects between them.
- Feature widgets across the app (home, auth, recording, sync, etc.) call
  `AppColors.of(context)` to pull semantic tokens, e.g.
  [../../features/recording/presentation/recordings_list_screen.dart](../../features/recording/presentation/recordings_list_screen.dart).
  This folder is therefore an upstream dependency of nearly every presentation
  layer, but depends on nothing in the app itself (only Flutter `material`).
- The theme is the app-wide source of truth for color/typography state. There
  is no Riverpod/notifier state here — brightness state lives in Flutter's
  inherited `Theme` (driven by the platform), and `AppColors.of` reads from
  that inherited widget rather than holding state of its own.
- Token values are pinned by [../../../test/core/theme/app_colors_test.dart](../../../test/core/theme/app_colors_test.dart),
  which also locks the `ThemeExtension` contract, the `ThemeData` registration,
  and the `of()` resolution order.

### Core Implementation

- **Two color paths from one palette.** `AppColors` exposes raw `static const
  Color` constants plus two assembled `AppColorSet` instances (`light` /
  `dark`). `AppTheme` builds its `ColorScheme` and every component theme from
  the raw constants; the matching `AppColorSet` is registered separately in
  `ThemeData.extensions`. Both paths derive from the same constants, so the
  Material-styled surfaces and the `of()`-read tokens stay in sync.

```
raw const tokens (AppColors.primary, darkSurface, ...)
   ├─► AppTheme builders ─► ColorScheme + component themes ─► Material widgets
   └─► AppColorSet light/dark ─► ThemeData.extensions ─► AppColors.of(context) ─► app widgets
```

- **`AppColors.of(context)` resolution.** It reads `Theme.of(context)`,
  prefers `theme.extension<AppColorSet>()`, and only falls back to a
  brightness check when no extension is registered:

```
Theme.of(context)
   ├─ extension<AppColorSet>()  ─► registered set        (production path)
   └─ null ─► brightness == dark ? AppColors.dark : AppColors.light  (fallback)
```

- **Extension registration.** `lightTheme` registers `AppColors.light` and
  `darkTheme` registers `AppColors.dark`. Because both production themes always
  register an extension, the brightness fallback never runs in the real app; it
  exists for bare `ThemeData.light()` / `ThemeData.dark()` used in tests or
  previews.
- **`AppColorSet` is an immutable value type.** `const` constructor, `copyWith`
  for per-token overrides, value-based `==` / `hashCode`, and a `lerp` that
  interpolates each token with `Color.lerp`. `lerp` returns the receiver
  unchanged when the other value is `null` or not an `AppColorSet`.
- `AppTheme` also builds the typography (`_buildTextTheme`) and a large set of
  component themes (buttons, inputs, cards, navigation, dialogs, etc.) so the
  Material defaults match the brand palette without per-widget styling.

### Things to Know

- **Invariant: a registered extension's brightness must match its
  `ThemeData.brightness`.** Since `of()` prefers the extension and ignores
  brightness whenever one is present, registering the dark set on a light
  `ThemeData` (or vice versa) would make `of()` hand back colors for the wrong
  mode while the Material `ColorScheme` stays correct — an inconsistent UI. The
  builders uphold this by pairing light↔`AppColors.light` and
  dark↔`AppColors.dark`.
- **`lerp` is effectively dormant in production.** [../../main.dart](../../main.dart)
  sets `themeAnimationDuration: Duration.zero`, so theme switches snap and
  `lerp` runs only at `t == 1.0` (no visible cross-fade). The interpolation
  exists to satisfy the `ThemeExtension` contract and enable future animated
  transitions.
- **The `AppColorSet` is a curated semantic subset, not every constant.**
  Extra raw constants (surface containers, outline variant, switch thumb, the
  `brand*` source colors) feed the `ColorScheme` / component themes only and
  are not part of the token set returned by `of()`.
- **Some tokens are shared or remapped across modes.** For example the dark
  set maps its `card` token to the dark surface color, and `error` is the same
  value in both light and dark sets. Read [app_colors.dart](app_colors.dart)
  for the exact mapping rather than assuming a 1:1 light/dark pairing.
- **Adding a token is a multi-point edit.** A new field on `AppColorSet` must
  be threaded through the constructor, `copyWith`, `lerp`, `==`, `hashCode`,
  and both `light` / `dark` instances, or the value-equality and interpolation
  contracts break.

Created and maintained by Nori.
