# Noridoc: obt_lints

Path: @/packages/obt_lints

### Overview

- A project-internal `custom_lint` plugin (ENG-159) holding the rules that ban
  raw colors outside the design-token source of truth: `avoid_hardcoded_color`
  (any `dart:ui` `Color` constructor — `Color(0x…)`, `Color.fromARGB`,
  `Color.fromRGBO`) in [lib/src/avoid_hardcoded_color.dart](lib/src/avoid_hardcoded_color.dart),
  and `avoid_material_colors` (bare `Colors.*` Material palette) in
  [lib/src/avoid_material_colors.dart](lib/src/avoid_material_colors.dart).
- Lives in its **own package** because `custom_lint` requires every lint plugin
  to be a standalone Dart package exposing a `createPlugin()` entrypoint
  ([lib/obt_lints.dart](lib/obt_lints.dart)); it cannot be folded into the app's
  own source tree.
- It is the deferred rule that [ADR-0002](/docs/adr/ADR-0002-design-tokens.md)
  and [ADR-0007](/docs/adr/ADR-0007-lint-baseline.md) planned and held back until
  the color tokens existed, so every flagged site has a migration target in
  [/lib/core/theme/](/lib/core/theme).

### How it fits into the larger codebase

- The app consumes it as a path `dev_dependency` (`obt_lints: {path:
  packages/obt_lints}` in [/pubspec.yaml](/pubspec.yaml)) and turns the rules on
  in [/analysis_options.yaml](/analysis_options.yaml): the `analyzer: plugins: -
  custom_lint` entry (shared with `riverpod_lint`) loads the plugin, and a
  `custom_lint: rules:` block lists the two rule names.
- It enforces the design-token invariant owned by [/lib/core/theme/](/lib/core/theme)
  (see [/lib/core/theme/docs.md](/lib/core/theme/docs.md)): raw `Color(...)` /
  `Colors.*` are allowed **only** inside that directory — the
  `AppColors`/`AppColorSet` palette, the `ThemeData` builders, the `AppPalettes`
  decorative accents, and the `color_hex.dart` parser — plus `test/`. Everywhere
  else, app code is expected to read semantic tokens (`AppColors.of(context)`).
  ENG-183 burned the rest of the app down to zero such literals.
- CI runs it two ways in [/.github/workflows/lint.yml](/.github/workflows/lint.yml):
  a dedicated **blocking** `obt_lints` job runs this package's fixtures, while
  the pre-existing app-wide `dart run custom_lint` step (which also runs these
  rules over `lib/`) stays **non-blocking** (`continue-on-error`) — by deliberate
  choice even after the rules were promoted to `warning`, since `custom_lint`
  does not run under `flutter analyze` (see Things to Know).
- This package depends only on the analyzer toolchain (`analyzer`,
  `analyzer_plugin`, `custom_lint_builder`); it does not import app code. The
  dependency arrow points one way: the app depends on the plugin, not vice versa.

### Core Implementation

```
app pubspec dev_dep ─► createPlugin() ─► getLintRules() ─► [AvoidHardcodedColor, AvoidMaterialColors]
analysis_options (plugins + custom_lint.rules)        each rule.run():
                                                        if isColorLintExempt(resolver.path) → return
                                                        register AST visitor → reporter.atNode(node)
```

- **Entrypoint.** [lib/obt_lints.dart](lib/obt_lints.dart) exposes
  `createPlugin()` returning a `PluginBase` whose `getLintRules` returns both
  rules unconditionally; which rules are *active* is decided by the consumer's
  `custom_lint: rules:` block, not here.
- **Path exemption.** Both rules early-return when
  `isColorLintExempt(resolver.path)` is true. `isColorLintExempt`
  ([lib/src/theme_path.dart](lib/src/theme_path.dart)) normalizes backslashes and
  tests for the substrings `/lib/core/theme/` (the design-token files, which may
  use raw colors freely) **or** `/test/` (fixtures and golden setups, exempted in
  ENG-183). It matches the `/test/` path segment, not the `_test.dart` suffix.
- **`avoid_hardcoded_color`** visits instance-creation expressions and flags a
  node whose static type `isExactlyType` of `dart:ui#Color` (a `TypeChecker`
  built from that URL). "Exactly" is deliberate: it matches `Color` and its
  named constructors but **not** subtypes like `MaterialColor`, which the other
  rule owns; static methods such as `Color.lerp` are not constructors and are
  not visited.
- **`avoid_material_colors`** visits prefixed identifiers and flags any whose
  prefix name is `Colors`, so `AppColors.…` and member access on a token
  instance do not match.
- **Severity.** Both rules emit `LintCode` with `ErrorSeverity.WARNING` —
  promoted from `INFO` in ENG-183 once the baseline was clean (see Things to
  Know). Because these are `custom_lint` rules, severity lives here in the
  plugin's `LintCode`, not in the app's `analyzer: errors:`.

### Things to Know

- **Promoted to `warning`, but the CI step is still non-blocking.** Per
  [ADR-0007](/docs/adr/ADR-0007-lint-baseline.md) both rules began at `info` with
  a pre-existing violation baseline in `lib/`. ENG-183/ENG-116 burned that
  baseline down to **zero** outside `lib/core/theme/**` (neutral anchors and a
  few long-tail tokens added to `AppColors`, the categorical accents moved to
  `AppPalettes`, and the one dynamic parser moved to
  [/lib/core/theme/color_hex.dart](/lib/core/theme/color_hex.dart)) and promoted
  both rules `info`→`warning`. Severity and CI-gating are **separate** levers,
  though: these are `custom_lint` rules, so `flutter analyze` never runs them and
  promoting their `LintCode` does not touch `analyzer: errors:`. The app-wide
  `dart run custom_lint` step therefore stays **non-blocking**
  (`continue-on-error`) by deliberate choice — the `warning` shows in the IDE and
  in that non-fatal step. Flipping `continue-on-error` to blocking is the
  remaining step to full enforcement.
- **The fixtures *are* the rule tests.** The [example/](example) sub-package is a
  standalone package (its own [example/pubspec.yaml](example/pubspec.yaml) with a
  path dep back on this plugin) holding `// expect_lint:` fixtures. `dart run
  custom_lint` from `example/` passes only if every `// expect_lint` line flags
  **and** no un-annotated line flags — an unexpected lint fails the run. The
  blocking CI job runs exactly this.
- **Fixtures cover both directions.** [example/lib/features/violations_fixture.dart](example/lib/features/violations_fixture.dart)
  asserts the violations *and* the false-positive controls (e.g. `Color.lerp`,
  member access on a token), while [example/lib/core/theme/exempt_fixture.dart](example/lib/core/theme/exempt_fixture.dart)
  sits under `lib/core/theme/` with no annotations, so the run fails if the
  exemption ever stops working.
- **`test/` is exempt (ENG-183).** `isColorLintExempt` matches `/test/` as well
  as `/lib/core/theme/`, so fixtures and golden setups may use raw colors
  directly. It matches the `/test/` path *segment*, not the `_test.dart` suffix,
  so a `*_test.dart` file outside a `test/` directory would still be flagged.
- **The exemption is purely path-based.** It keys off the resolved file path
  substring, not package or import structure — moving the token files out of
  `/lib/core/theme/` would silently start flagging them.

Created and maintained by Nori.
