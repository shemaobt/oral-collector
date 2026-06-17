# ADR-0002: Design tokens

- Status: Accepted
- Date: 2026-06-05
- Epic: E2 (Design System & UI Componentization)
- Related: ENG-106, ENG-115, ENG-162, ENG-163, ENG-76, ENG-159, ENG-183, ENG-116, ENG-90, ADR-0000, ADR-0007
- Update (2026-06-15, ENG-159): the deferred `Color(0x…)`/`Colors.*` lint rule
  from item 7 shipped as the `obt_lints` plugin (`avoid_hardcoded_color` +
  `avoid_material_colors`), staged at `info`/non-blocking, exempting
  `lib/core/theme/**`.
- Update (2026-06-16, ENG-183/ENG-116): the color-token conversion from item 7
  landed, value-identical. `AppColors` gained neutral anchors
  (`white`/`black`/`transparent`, distinct from the off-white/near-black brand
  tokens) plus long-tail semantic tokens; the categorical accent palettes
  (genre/project/hero/waveform) are centralized in `AppPalettes`
  (`lib/core/theme/app_palettes.dart`) as index-addressed `static const` lists
  with `genreAccent(i)`/`projectAccent(i)` helpers (plain `static const`, not a
  `ThemeExtension`, since the palettes are single-theme/fixed); the dynamic
  hex→`Color` parser moved to `lib/core/theme/color_hex.dart`. obt_lints then
  promoted (ADR-0007).
- Update (2026-06-16, ENG-163): the long-tail call-site migration from item 6
  landed, value-identical. The remaining on-grid spacing/radii direct-argument
  literals (`EdgeInsets`/`SizedBox`/`BorderRadius`/`Radius`) across the feature
  and shared widgets now consume the `const` scale, preserving `const`; off-grid
  normalization stays deferred (ENG-162). No motion `Duration`s remained on the
  long tail — ENG-106 had already migrated them all.

## Context

Spacing, corner radii, and animation durations are scattered through the widget
tree as magic numbers (~347 `EdgeInsets`, ~547 `SizedBox`, ~251
`BorderRadius`/`Radius`, plus animation `Duration`s) with no single source of
truth. Colors are similarly scattered as `Color(0x…)` / bare `Colors.*`. Wave 1
E2 introduces a base design-token system under `lib/core/theme/**` and
componentizes the UI on top of it.

About ~93% of the spacing/radii literals already sit on a 4px grid; off-grid
stragglers (6/10/14/22/26/34, and a few others) leak in. `Duration`s split into
UI/animation timings versus I/O timeouts and logic timers.

This ADR also owns the deferred lint rule from ADR-0007 — a custom `custom_lint`
rule banning `Color(0x…)` / bare `Colors.*` outside `lib/core/theme/**`. That
rule and the color-token conversion are tracked separately (ENG-76 / ENG-159)
and land with (or after) the color tokens so violations have a migration target.

## Decision

1. **Architecture (hybrid).** A `const` scale class is the single source of
   truth for each family — `SpacingScale`, `RadiusScale`, `DurationScale`. Being
   `const`, the scale is usable in `const` contexts and by the theme builders
   (ENG-115). A thin `ThemeExtension` per family (`AppSpacing`, `AppRadii`,
   `AppDurations`) defaults its fields to the scale and exposes a `const
   fallback`. A `BuildContext` extension exposes `context.spacing`,
   `context.radii`, `context.durations`, each reading the registered extension
   with `?? fallback`.

2. **Registration.** All three extensions are registered in
   `ThemeData.extensions` for both light and dark themes. Values are
   brightness-invariant today; the extension is the seam for future
   per-theme/density variation and the `lerp` hook.

3. **Naming — value-encoded.** `SpacingScale.sN` / `RadiusScale.rN` /
   `DurationScale.msN`, where `N` is the literal value (px or ms). Chosen over
   semantic t-shirt sizing (`xs/sm/md/lg/…`) because the dense 4px grid has ten
   spacing steps that do not map cleanly onto a handful of t-shirt names;
   value-encoding gives full coverage and a verifiable 1:1 migration. Semantic
   aliases (`md`, `lg`, …) are intentionally omitted (YAGNI); a semantic layer
   can be added later if needed.

4. **Grid policy.** Only on-grid values get tokens — spacing
   {4,8,12,16,20,24,28,32,40,48}, radii {4,8,12,16,20,24}. Off-grid stragglers
   (6,10,14,22,26,34) and other non-grid values (e.g. radius 36) are **not**
   tokenized; normalizing them is a separate, behavior-changing follow-up.
   Durations cover motion timings only ({120,150,200,250,300,900,1100,1200} ms);
   snackbar/feedback display durations (seconds-based), logic timers, and I/O
   timeouts are excluded.

5. **Migration policy.** Call-site migration is pure and behavior-preserving:
   only literals that already equal a token value are changed, and only when the
   literal is the direct argument of an `EdgeInsets`/`SizedBox`/`BorderRadius`/
   `Radius`/`Duration` constructor (literals embedded in expressions are left).
   Migrated sites use the `const` scale (`SpacingScale.s16`, …), which preserves
   `const` and is value-identical; the `context.*` accessor is for
   dynamic/theme-reactive code.

6. **Scope of the first pass (ENG-106).** The token infrastructure + tests,
   registration, and migration of the four densest screens (`recording_detail`,
   `confirmation_step`, `app_shell`, `trim_editor`) plus all UI motion
   `Duration`s. The long tail of remaining files is tracked as ENG-163.

7. **Deferred.** `app_theme.dart`'s own internal radii/padding literals consume
   the `const` scale in the theme builders (ENG-115); color tokens →
   `ThemeExtension` and the `Color(0x…)` / bare `Colors.*` lint rule (ENG-76 /
   ENG-159); off-grid normalization (ENG-162).

## Consequences

- One place to evolve each scale; ENG-115 makes the theme builders read the same
  `const` scale, removing the second source of truth.
- `const`-ness is preserved at migrated call sites — no rebuild regression, and
  `prefer_const_constructors` stays satisfied.
- The `context.*` accessor + `ThemeExtension`s provide the future seam for
  theme/density variation and animated `lerp`, even though current values are
  brightness-invariant.
- Value-encoded names document grid intent but not semantic intent (`s16` says
  "16px", not "card padding"); a semantic grouping, if wanted, is a later layer.
- No golden tests exist; behavior-preservation rests on value-identity
  (unit-tested token values) plus per-file diff review — hence the staged scope.
- New off-grid spacing/radii are now visible against the token vocabulary; a lint
  to enforce token usage is a possible follow-up (not added here).
