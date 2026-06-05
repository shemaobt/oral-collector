# ADR-0004: Async & state conventions

- Status: Proposed
- Date: 2026-06-04
- Epic: E5 (Asynchrony)
- Related: ENG-90, ADR-0000, ADR-0007

## Context

Async patterns and Riverpod state conventions vary across features (how futures
are awaited or fired-and-forgotten, how notifiers expose state, how loading and
error states are represented). Wave 1 E5 standardizes these conventions.

This ADR is the home for the conventions behind two rules staged in ADR-0007:
`unawaited_futures` and `riverpod_lint`'s `avoid_public_notifier_properties`.

## Decision

*Proposed — to be defined by E5. Stub created early so dependent epics can
reference it.*

## Consequences

*To be completed when the decision is made.*
