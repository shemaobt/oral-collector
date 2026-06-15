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
  `Colors.*` are allowed **only** inside that directory, which is the
  `AppColors`/`AppColorSet` palette and the `ThemeData` builders. Everywhere
  else, app code is expected to read semantic tokens (`AppColors.of(context)`).
- CI runs it two ways in [/.github/workflows/lint.yml](/.github/workflows/lint.yml):
  a dedicated **blocking** `obt_lints` job runs this package's fixtures, while
  the pre-existing app-wide `dart run custom_lint` step (which also runs these
  rules over `lib/`) stays **non-blocking** (`continue-on-error`) during the
  staging period.
- This package depends only on the analyzer toolchain (`analyzer`,
  `analyzer_plugin`, `custom_lint_builder`); it does not import app code. The
  dependency arrow points one way: the app depends on the plugin, not vice versa.

### Core Implementation

```
app pubspec dev_dep ─► createPlugin() ─► getLintRules() ─► [AvoidHardcodedColor, AvoidMaterialColors]
analysis_options (plugins + custom_lint.rules)        each rule.run():
                                                        if isThemeFile(resolver.path) → return
                                                        register AST visitor → reporter.atNode(node)
```

- **Entrypoint.** [lib/obt_lints.dart](lib/obt_lints.dart) exposes
  `createPlugin()` returning a `PluginBase` whose `getLintRules` returns both
  rules unconditionally; which rules are *active* is decided by the consumer's
  `custom_lint: rules:` block, not here.
- **Theme exemption.** Both rules early-return when
  `isThemeFile(resolver.path)` is true. `isThemeFile`
  ([lib/src/theme_path.dart](lib/src/theme_path.dart)) normalizes backslashes and
  tests for the substring `/lib/core/theme/`, so the design-token files can use
  raw colors freely.
- **`avoid_hardcoded_color`** visits instance-creation expressions and flags a
  node whose static type `isExactlyType` of `dart:ui#Color` (a `TypeChecker`
  built from that URL). "Exactly" is deliberate: it matches `Color` and its
  named constructors but **not** subtypes like `MaterialColor`, which the other
  rule owns; static methods such as `Color.lerp` are not constructors and are
  not visited.
- **`avoid_material_colors`** visits prefixed identifiers and flags any whose
  prefix name is `Colors`, so `AppColors.…` and member access on a token
  instance do not match.
- **Severity.** Both rules emit `LintCode` with `ErrorSeverity.INFO` — the
  staged level (see Things to Know).

### Things to Know

- **Staged at `info`, promoted per rule.** Per [ADR-0007](/docs/adr/ADR-0007-lint-baseline.md)
  there is a pre-existing violation baseline in `lib/` to burn down before any
  rule moves from `info` to `warning`/`error` and before the app-wide
  `dart run custom_lint` CI step becomes blocking. Promotion is per rule, not all
  at once.
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
- **`test/` is currently NOT exempt.** `isThemeFile` only matches
  `/lib/core/theme/`, so raw colors in `test/` are flagged like any other
  non-theme file. There is a test-directory violation baseline left to burn down
  alongside the `lib/` one before promotion.
- **The exemption is purely path-based.** It keys off the resolved file path
  substring, not package or import structure — moving the token files out of
  `/lib/core/theme/` would silently start flagging them.

Created and maintained by Nori.
