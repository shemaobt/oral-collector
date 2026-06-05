# ADR-0002: Design tokens

- Status: Proposed
- Date: 2026-06-04
- Epic: E2 (Design System & UI Componentization)
- Related: ENG-90, ENG-76, ADR-0000, ADR-0007

## Context

Colors, spacing, and typography are scattered through the widget tree as
`Color(0x…)` literals and bare `Colors.*` references instead of centralized
tokens. Wave 1 E2 introduces a base design-token system under
`lib/core/theme/**` and componentizes the UI on top of it.

This ADR also owns the deferred lint rule from ADR-0007: a custom `custom_lint`
rule banning `Color(0x…)` / bare `Colors.*` outside `lib/core/theme/**`. That
rule should land with (or after) the token system so violations have a
migration target.

## Decision

*Proposed — to be defined by E2. Stub created early so dependent epics can
reference it.*

## Consequences

*To be completed when the decision is made.*
