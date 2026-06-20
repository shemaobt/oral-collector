# ADR-0011: Architecture & Dependency Rules

## Status

Accepted (2026-06-09)

## Context

The app is feature-first (`lib/features/<feature>/` with `data` / `domain` / `presentation`
layers) on top of shared `lib/core/` and `lib/shared/`. The intended dependency rule
(Uncle Bob / Clean Architecture) is:

- Within a feature: `presentation -> domain <- data`. `domain` is the innermost circle and
  must not depend on `data`, `presentation`, or infrastructure.
- Features depend on `core` and `shared`; `core` and `shared` must NOT depend on `features`.
- No cyclic dependencies between modules.

A dependency analysis (2026-06-09) showed this rule is currently violated in several places
(known debt):

- `core -> features` (~31 imports) — chiefly `core/router/app_router.dart` importing feature
  screens (an artifact of centralized go_router routing).
- `shared -> features` (~8 imports).
- `domain -> core/database` (Drift) in a couple of feature entities.
- `data -> presentation` (~7 imports).
- ~150 cross-feature imports; `recording` is a hub.
- Import cycles: `recording <-> sync`, and `core/auth <-> features` (via `app_router` / notifiers).

All internal imports are relative (`../`), which blocks rule-based tools like `import_lint`
(they key on `package:` imports).

## Decision

1. The **target architecture** is the dependency rule above. New code must follow it.
2. **Enforcement is advisory for now**, consistent with ADR-0007 (stage strict checks, burn
   down, promote later):
   - `layerlens` runs in CI to report import cycles (non-blocking).
   - The `dart_code_linter` metric gate (complexity / size / nesting / parameters) IS blocking
     — see `analysis_options.yaml` and `scripts/check_metrics.sh`.
   - Test coverage is generated and uploaded in CI but not enforced yet (current ~19%).
3. **Out of scope for this change** (separate, to-be-approved effort):
   - A relative -> `package:` import codemod (prerequisite for `import_lint` layer rules).
   - Breaking the existing cycles and the `core/router -> feature screens` coupling.

## Consequences

- The cycle report and coverage are visible on every PR without blocking delivery.
- Once the codemod + cycle remediation land, `import_lint` layer rules and
  `layerlens --fail-on-cycles` can be promoted to blocking gates.
