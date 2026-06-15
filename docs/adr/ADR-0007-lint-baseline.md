# ADR-0007: Strict lint baseline (custom_lint + riverpod_lint)

- Status: Accepted
- Date: 2026-06-04
- Epic: E1 (Architecture & Standards)
- Related: ENG-89, ENG-90, ENG-156, ADR-0000, ADR-0002, ADR-0004

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
`info`: `unawaited_futures` (40); `riverpod_lint`'s
`avoid_public_notifier_properties` (14) stays non-blocking.

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
