# ADR-0001: Error model

- Status: Proposed
- Date: 2026-06-04
- Epic: E3 (Error Handling & Observability)
- Related: ENG-90, ADR-0000, ADR-0006

## Context

Failures are surfaced inconsistently across layers — raw exceptions in some
paths, ad-hoc strings in others — with no shared type to distinguish expected
from unexpected errors. Wave 1 E3 introduces shared base types (e.g. a
`Result` / `AppException` family) so failures are modeled uniformly from the
data layer up to the UI.

## Decision

*Proposed — to be defined by E3. Stub created early so dependent epics can
reference it.*

## Consequences

*To be completed when the decision is made.*
