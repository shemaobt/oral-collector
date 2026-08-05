# Noridoc: obt_lints

Path: @/packages/obt_lints

### Overview

- A project-internal `custom_lint` plugin (ENG-159) holding bespoke rules that
  pin app code to its single sources of truth. Two ban raw colors outside the
  design-token files: `avoid_hardcoded_color` (any `dart:ui` `Color` constructor
  — `Color(0x…)`, `Color.fromARGB`, `Color.fromRGBO`) in
  [lib/src/avoid_hardcoded_color.dart](lib/src/avoid_hardcoded_color.dart) and
  `avoid_material_colors` (bare `Colors.*` Material palette) in
  [lib/src/avoid_material_colors.dart](lib/src/avoid_material_colors.dart). A
  third, `avoid_raw_print` (ENG-190) in
  [lib/src/avoid_raw_print.dart](lib/src/avoid_raw_print.dart), bans raw `print` /
  `debugPrint` so all console output routes through the logging facade.
- Lives in its **own package** because `custom_lint` requires every lint plugin
  to be a standalone Dart package exposing a `createPlugin()` entrypoint
  ([lib/obt_lints.dart](lib/obt_lints.dart)); it cannot be folded into the app's
  own source tree.
- Each rule is a deferred follow-up an ADR planned and held back until its target
  existed. The color rules wait on the tokens
  ([ADR-0002](/docs/adr/ADR-0002-design-tokens.md),
  [ADR-0007](/docs/adr/ADR-0007-lint-baseline.md)), so every flagged site has a
  migration target in [/lib/core/theme/](/lib/core/theme); `avoid_raw_print`
  closes the candidate rule [ADR-0010](/docs/adr/ADR-0010-logging-facade.md)
  left open, routing diagnostics to the facade in
  [/lib/core/observability/](/lib/core/observability).

### How it fits into the larger codebase

- The app consumes it as a path `dev_dependency` (`obt_lints: {path:
  packages/obt_lints}` in [/pubspec.yaml](/pubspec.yaml)) and turns the rules on
  in [/analysis_options.yaml](/analysis_options.yaml): the `analyzer: plugins: -
  custom_lint` entry (shared with `riverpod_lint`) loads the plugin, and a
  `custom_lint: rules:` block lists each rule name. Registering a rule in
  [lib/obt_lints.dart](lib/obt_lints.dart) only makes it available; the consumer's
  `rules:` block decides which are active.
- It enforces the design-token invariant owned by [/lib/core/theme/](/lib/core/theme)
  (see [/lib/core/theme/docs.md](/lib/core/theme/docs.md)): raw `Color(...)` /
  `Colors.*` are allowed **only** inside that directory — the
  `AppColors`/`AppColorSet` palette, the `ThemeData` builders, the `AppPalettes`
  decorative accents, and the `color_hex.dart` parser — plus `test/`. Everywhere
  else, app code is expected to read semantic tokens (`AppColors.of(context)`).
  ENG-183 burned the rest of the app down to zero such literals.
- It likewise enforces the logging-facade invariant owned by
  [/lib/core/observability/](/lib/core/observability) (see
  [/lib/core/observability/docs.md](/lib/core/observability/docs.md)): raw
  `print` / `debugPrint` are allowed **only** under that directory (the legitimate
  spot for a low-level fallback) plus `test/`. Everywhere else, app code is
  expected to log through a named `package:logging` `Logger`, which the facade
  echoes to `dart:developer log()` and bridges into the `ErrorReporter` at
  `SEVERE`+. This is what mechanically keeps raw `debugPrint` (which prints in
  release too) from leaking back into the codebase after ADR-0010.
- CI runs it two ways in [/.github/workflows/lint.yml](/.github/workflows/lint.yml):
  a dedicated **blocking** `obt_lints` job runs this package's fixtures, and the
  pre-existing app-wide `dart run custom_lint` step (which also runs these rules
  over `lib/`) is **blocking** too — ENG-158 removed its `continue-on-error` once
  the baseline was clean, so a new `obt_lints` finding now walls the build even
  though `custom_lint` does not run under `flutter analyze` (see Things to Know).
- This package depends only on the analyzer toolchain (`analyzer`,
  `analyzer_plugin`, `custom_lint_builder`); it does not import app code. The
  dependency arrow points one way: the app depends on the plugin, not vice versa.

### Core Implementation

```
app pubspec dev_dep ─► createPlugin() ─► getLintRules() ─► [AvoidHardcodedColor,
analysis_options (plugins + custom_lint.rules)             AvoidMaterialColors,
                                                           AvoidRawPrint]
                                                       each rule.run():
                                                        if <path-exempt>(resolver.path) → return
                                                        register AST visitor → reporter.atNode(node)
```

- **Entrypoint.** [lib/obt_lints.dart](lib/obt_lints.dart) exposes
  `createPlugin()` returning a `PluginBase` whose `getLintRules` returns every
  rule unconditionally; which rules are *active* is decided by the consumer's
  `custom_lint: rules:` block, not here.
- **Path exemption.** Each rule early-returns on a path check before registering
  any visitor. The color rules use `isColorLintExempt`
  ([lib/src/theme_path.dart](lib/src/theme_path.dart)); `avoid_raw_print` uses the
  parallel `isRawPrintExempt`
  ([lib/src/observability_path.dart](lib/src/observability_path.dart)). Both
  normalize backslashes and match a path *substring*: the color helper exempts
  `/lib/core/theme/`, the print helper exempts `/lib/core/observability/`, and
  **both** exempt `/test/` (fixtures and golden setups, exempted in ENG-183).
  Each matches the `/test/` path segment, not the `_test.dart` suffix. The two
  helpers are deliberately kept separate so each rule's exempt directory tracks
  its own source-of-truth folder.
- **`avoid_hardcoded_color`** visits instance-creation expressions and flags a
  node whose static type `isExactlyType` of `dart:ui#Color` (a `TypeChecker`
  built from that URL). "Exactly" is deliberate: it matches `Color` and its
  named constructors but **not** subtypes like `MaterialColor`, which the other
  rule owns; static methods such as `Color.lerp` are not constructors and are
  not visited.
- **`avoid_material_colors`** visits prefixed identifiers and flags any whose
  prefix name is `Colors`, so `AppColors.…` and member access on a token
  instance do not match.
- **`avoid_raw_print`** flags a call to `print` or `debugPrint` only when it has
  **no receiver**, so an instance method such as `obj.print()` is intentionally
  left alone. It registers **two** AST visitors because the two banned names land
  on different node types: `print` is a top-level *function* and resolves to a
  `MethodInvocation` (checked for `target == null`), while `debugPrint` is a
  top-level reassignable *variable* in Flutter foundation, so the analyzer
  rewrites its call site as a `FunctionExpressionInvocation` (checked for a
  `SimpleIdentifier` function with the banned name). Missing either node would
  silently let one of the two through.
- **Severity.** Every rule emits `LintCode` with `ErrorSeverity.WARNING` — the
  color rules were promoted from `INFO` in ENG-183 once the baseline was clean
  (see Things to Know); `avoid_raw_print` shipped at `WARNING`. Because these are
  `custom_lint` rules, severity lives here in the plugin's `LintCode`, not in the
  app's `analyzer: errors:`.

### Things to Know

- **Severity and CI-gating are separate levers.** Per
  [ADR-0007](/docs/adr/ADR-0007-lint-baseline.md) the color rules began at `info`
  with a pre-existing violation baseline in `lib/`. ENG-183/ENG-116 burned that
  baseline down to **zero** outside `lib/core/theme/**` (neutral anchors and a
  few long-tail tokens added to `AppColors`, the categorical accents moved to
  `AppPalettes`, and the one dynamic parser moved to
  [/lib/core/theme/color_hex.dart](/lib/core/theme/color_hex.dart)) and promoted
  both rules `info`→`warning`. Because these are `custom_lint` rules, `flutter
  analyze` never runs them and promoting their `LintCode` does not touch
  `analyzer: errors:`. CI-gating moved separately: ENG-158 removed
  `continue-on-error` from the app-wide `dart run custom_lint` step once its whole
  baseline was clean, so that step is now **blocking** — a single command gates
  the entire `custom_lint` surface, so every `obt_lints` finding (`warning`) walls
  the build app-wide. `avoid_raw_print` (ENG-190) entered under that
  already-blocking gate.
- **The fixtures *are* the rule tests.** The [example/](example) sub-package is a
  standalone package (its own [example/pubspec.yaml](example/pubspec.yaml) with a
  path dep back on this plugin) holding `// expect_lint:` fixtures. `dart run
  custom_lint` from `example/` passes only if every `// expect_lint` line flags
  **and** no un-annotated line flags — an unexpected lint fails the run. The
  blocking CI job runs exactly this.
- **Fixtures cover both directions, per rule.** Each rule has a violations
  fixture asserting the positives *and* the false-positive controls, plus an
  exempt fixture sitting in the rule's exempt directory with no annotations so the
  run fails if the exemption breaks. For colors that is
  [example/lib/features/violations_fixture.dart](example/lib/features/violations_fixture.dart)
  (controls such as `Color.lerp` and member access on a token) and
  [example/lib/core/theme/exempt_fixture.dart](example/lib/core/theme/exempt_fixture.dart).
  For raw print it is
  [example/lib/features/print_violations_fixture.dart](example/lib/features/print_violations_fixture.dart)
  (controls such as a receiver call `p.print(...)` and a benign no-receiver call
  `greet(...)`, which prove name- and receiver-discrimination) and
  [example/lib/core/observability/exempt_logging_fixture.dart](example/lib/core/observability/exempt_logging_fixture.dart).
- **`test/` is exempt for every rule (ENG-183).** Both exemption helpers match
  `/test/`, so fixtures and golden setups may use raw colors *and* raw
  `print`/`debugPrint` directly; the shared `test/` fixture
  ([example/test/exempt_test_fixture.dart](example/test/exempt_test_fixture.dart))
  exercises both. They match the `/test/` path *segment*, not the `_test.dart`
  suffix, so a `*_test.dart` file outside a `test/` directory would still be
  flagged.
- **The exemptions are purely path-based.** Each keys off the resolved file path
  substring, not package or import structure — moving the token files out of
  `/lib/core/theme/`, or facade code out of `/lib/core/observability/`, would
  silently start flagging them.

Created and maintained by Nori.
