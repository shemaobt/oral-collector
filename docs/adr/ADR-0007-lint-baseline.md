# ADR-0007: Strict lint baseline (custom_lint + riverpod_lint)

- Status: Accepted
- Date: 2026-06-04
- Epic: E1 (Architecture & Standards)
- Related: ENG-89, ENG-90, ENG-156, ENG-157, ENG-158, ENG-159, ENG-183, ENG-116, ENG-190, ADR-0000, ADR-0002, ADR-0004, ADR-0010
- Update (2026-06-15, ENG-159): the deferred custom rule from item 5 shipped as
  the `obt_lints` plugin — `avoid_hardcoded_color` + `avoid_material_colors`,
  staged at `info` and non-blocking, exempting `lib/core/theme/**`.
- Update (2026-06-16, ENG-183/ENG-116): baseline burned down to zero outside
  `lib/core/theme/**`; both rules promoted `info`→`warning` (in the plugin's
  `LintCode`, not `analyzer: errors:`) and `test/` is now exempt. The
  `dart run custom_lint` step stays non-blocking by choice — see "Promoted in
  ENG-183" below.
- Update (2026-06-17, ENG-158): `avoid_public_notifier_properties` baseline
  burned down to zero and `dart run custom_lint` is now **blocking** in CI and
  the pre-commit hook (full enforcement) — supersedes the ENG-183 "stays
  non-blocking" note. See "Promoted in ENG-158" below.
- Update (2026-06-20, ENG-190): added a third `obt_lints` rule, `avoid_raw_print`
  — bans raw `print`/`debugPrint` outside `lib/core/observability/**` and `test/`
  (ADR-0010). Baseline was already zero, so it shipped enforced at `warning` with
  no `info` staging; the blocking `dart run custom_lint` gate (ENG-158) walls new
  violations app-wide.

## Context

`analysis_options.yaml` only included `package:flutter_lints/flutter.yaml`,
which enforces a small default set and runs none of the Riverpod-specific
checks — even though Riverpod is used across ~88 of ~299 `lib/` files. There was
no staged path to stricter rules: the team needs more enforcement without a
one-shot CI wall that blocks unrelated work.

Two analysis tools coexist in a Flutter project and behave differently:

- `flutter analyze` / `dart analyze` run the built-in analyzer over
  `analysis_options.yaml`. **`flutter analyze` exits non-zero on *any* issue,
  including `info`** (measured: 0 errors + 0 warnings + 172 infos still failed).
  `dart analyze` and `flutter analyze --no-fatal-infos` exit 0 when only infos
  remain.
- `custom_lint` plugins (e.g. `riverpod_lint`) do **not** run under
  `flutter analyze`; they run via `dart run custom_lint` and in the IDE, with
  their own exit code.

## Decision

Adopt a **staged** lint baseline.

1. **Dependencies** (dev): `custom_lint ^0.7.6` + `riverpod_lint ^2.6.5` — the
   Riverpod 2.x line, matching `flutter_riverpod ^2.6.1`. Enabling the
   `custom_lint` plugin pins the analyzer/codegen cluster slightly older (e.g.
   `source_gen 4.0.0`, `sqlite3 2.9.4`); all stay within existing constraints
   and are validated by the full test suite. (`pubspec.lock` is not committed,
   so builds already resolve within constraint ranges.)

2. **`analysis_options.yaml`**: enable the `custom_lint` plugin (Riverpod 2.x
   syntax: `analyzer: plugins: - custom_lint`) and these rules at their default
   **`info`** severity — `use_build_context_synchronously`, `unawaited_futures`,
   `prefer_const_constructors`, `prefer_final_locals`, `directives_ordering`.
   `info` is the staging level; no `analyzer: errors:` promotion yet.

3. **Keep analysis green while staging**: the git hook and CI run
   `flutter analyze --no-fatal-infos`, so staged `info` lints do not wall the
   build while `warning`/`error` still fail. `dart run custom_lint` runs as a
   separate, **non-blocking** step (`continue-on-error`) until its baseline is
   burned down.

4. **Fix the trivial now, defer the rest**: the mechanical rules were auto-fixed
   in this change (`dart fix` for `directives_ordering`,
   `prefer_const_constructors`, `prefer_final_locals` — 83 fixes across 53
   files). `use_build_context_synchronously` had **0** violations.
   `unawaited_futures` (40) and `riverpod_lint`'s
   `avoid_public_notifier_properties` (14) are left staged, with follow-ups.

5. **Deferred**: a custom `custom_lint` rule banning `Color(0x…)` / bare
   `Colors.*` outside `lib/core/theme/**` is **not** added here — it depends on
   the design-token system (ADR-0002 / E2). Tracked as a follow-up so violations
   have a migration target.

**Promotion path (follow-ups).** Per rule: burn down the remaining violations,
then promote it from `info` to `warning`/`error` via `analyzer: errors:` (which
`flutter analyze` enforces even with `--no-fatal-infos`). Make the
`dart run custom_lint` step blocking once its baseline is clean.

**Promoted in ENG-156 (2026-06-15).** Burned down `directives_ordering` (1
violation — unsorted imports in a recording widget test) and promoted four rules
via `analyzer: errors:`. `use_build_context_synchronously` → `error` (a real
correctness bug — a `BuildContext` used across an async gap); the style/format
rules `directives_ordering`, `prefer_const_constructors`, `prefer_final_locals`
→ `warning`. Under `--no-fatal-infos` both levels fail CI; the split reflects
intent (correctness vs. style). The CI command is unchanged. An
intentional-violation pass confirms each promoted rule now fails analyze:
`use_build_context_synchronously` reports as `error` in `lib/` — note the
analyzer does not apply this rule to `test/` — with 0 current violations because
the codebase already guards async gaps with `context.mounted`. Still staged at
`info`: `riverpod_lint`'s `avoid_public_notifier_properties` (14) stays
non-blocking (`unawaited_futures` was promoted later, in ENG-157 below).

**Promoted in ENG-157 (2026-06-16).** Burned down `unawaited_futures` (42
violations — 41 in `lib/`, one in `test/`) and promoted it to `warning` via
`analyzer: errors:`. Every site was an intentional fire-and-forget, wrapped in
`unawaited(...)` — the established pattern (the codebase already had 16 such
calls and zero `// ignore: unawaited_futures`), never a missing `await` — so
behavior is unchanged and the full suite (1028 tests) stays green. `warning`
(not `error`) mirrors the ENG-156 split: only the pure correctness bug
(`use_build_context_synchronously`) is `error`; this rule is mostly explicit
fire-and-forget. Note the analyzer **does** apply `unawaited_futures` to `test/`
(unlike `use_build_context_synchronously`). An intentional-violation pass
confirms it now fails `flutter analyze --no-fatal-infos` (exit 1) as a `warning`.
Still staged at `info`: `riverpod_lint`'s `avoid_public_notifier_properties` (14)
stays non-blocking.

**Promoted in ENG-183 (2026-06-16).** Burned down the `obt_lints` baseline (~21
`Color(0x…)` + ~127 bare `Colors.*` across `lib/`) to **zero** outside
`lib/core/theme/**`: neutral anchors (`AppColors.white`/`black`/`transparent`)
and a few long-tail semantic tokens were added to `AppColors`, the categorical
accent palettes moved to `AppPalettes` (ENG-116), and the one dynamic
`Color(int.parse(...))` parser moved into `lib/core/theme/color_hex.dart`. Both
rules were promoted `info`→`warning`, but these are **custom_lint** rules, so
severity lives in the plugin's `LintCode.errorSeverity` (not `analyzer:
errors:`) and custom_lint does **not** run under `flutter analyze`. The
`dart run custom_lint` step is therefore left **non-blocking**
(`continue-on-error`) by deliberate choice: the `warning` is surfaced in the IDE
and in the (non-fatal) CI step, but does not yet wall the build. The rules also
now exempt `test/` (fixtures legitimately use raw colors). Flipping
`continue-on-error` to blocking is the remaining step to full enforcement.

**Promoted in ENG-158 (2026-06-17).** Burned down `riverpod_lint`'s
`avoid_public_notifier_properties` to **zero** (15 sites). In `lib/` (4): the two
derived getters on `RoleNotifier` became top-level providers
(`isPlatformAdminProvider`, `canCreateProjectProvider`),
`LocaleNotifier.hasLocalePreference` was inlined to `localeProvider != null` at
its single call site, and `RecordingPlayerNotifier.player` is re-exposed as an
`audioPlayer()` method. In `test/` (11): public spy counters and the
`_FakeSyncNotifier.initialOnline` config field were made private on the test
doubles. The rule is **body-blind** — it flags any public instance getter or
field on a notifier subtype (including `late final` fields and pure
`state`-derived getters), so the fix is always to route data through
`state`/derived providers or expose it via a method (methods are not flagged).
With the baseline clean, `continue-on-error` was removed from the
`dart run custom_lint` step in `.github/workflows/lint.yml` and `|| true` from
`.githooks/pre-commit`: the step is now **blocking**. `dart run custom_lint`
exits non-zero on any finding at any severity, so there is no
`analyzer: errors:` promotion (custom_lint rule severity is not configurable from
`analysis_options.yaml`). Because a single command gates the **entire**
custom_lint surface, this also makes the `obt_lints` rules
(`avoid_hardcoded_color`/`avoid_material_colors`, `warning`) blocking app-wide —
which ENG-183 had deliberately left non-blocking. Their baseline is already zero
outside `lib/core/theme/**`, so CI stays green, but new `obt_lints` findings now
wall the build too. The isolated `obt_lints` fixture job is unchanged. The full
suite (1067 tests) stays green.

## Consequences

- More enforcement (Riverpod lints + 5 rules) with **no CI wall**:
  `flutter analyze --no-fatal-infos` and the non-blocking `custom_lint` step
  keep `dev`/`main` green today; the full test suite (462 tests) stays green.
- Staging at `info`/non-blocking means new violations of staged rules are
  **visible but not enforced** until promoted — the follow-ups close that gap.
- `--no-fatal-infos` relaxes the previous "any info fails analyze" behavior;
  warnings and errors remain fatal, and promoted rules move to those levels.
- The git hook is slower (custom_lint compiles and analyzes) and prints staged
  issues without blocking; acceptable during staging, revisited when the rule is
  promoted to blocking (or moved to a `pre-push` hook).
- Transitive version pinning from `custom_lint` (analyzer / source_gen /
  sqlite3) is accepted and covered by tests.
