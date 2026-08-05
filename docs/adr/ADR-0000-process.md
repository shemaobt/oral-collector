# ADR-0000: Architecture Decision Records — process

- Status: Accepted
- Date: 2026-06-04
- Epic: E1 (Architecture & Standards)
- Related: ENG-90

## Context

The app had no place to record *why* cross-cutting technical decisions were
made. Conventions live in `AGENTS.md` and per-folder `docs.md` (noridocs), but
one-off architectural choices — error model, persistence contract, security
policy, and so on — were unrecorded and got re-litigated. The "App Review &
Refactor — Wave 1" milestone makes several such decisions across epics and
needs a durable, reviewable record.

## Decision

Adopt lightweight Architecture Decision Records (ADRs) stored in `docs/adr/`.

**Format.** Every ADR opens with `# ADR-NNNN: <short title>`, a metadata block,
and the body sections **Context**, **Decision**, **Consequences**. The metadata
block carries:

- `Status` — see the lifecycle below.
- `Date` — ISO `YYYY-MM-DD` of the last status change.
- `Epic` — the owning Wave-1 epic (or `—`).
- `Related` — issue IDs and other ADRs.

**Numbering.** Sequential, zero-padded to four digits (`ADR-0001`, `ADR-0002`,
…). `ADR-0000` is this process doc. Filenames are `ADR-NNNN-kebab-title.md`.
Numbers are never reused; a reversed decision is *superseded*, not deleted.

**Status lifecycle.**

```
Proposed ──▶ Accepted ──▶ Superseded by ADR-XXXX
   │                 └──▶ Deprecated
   └──▶ Rejected
```

- **Proposed** — drafted, not yet agreed. Stubs created ahead of their epic
  start here.
- **Accepted** — agreed and in force.
- **Superseded by ADR-XXXX** — replaced by a later ADR (link it). The old ADR
  stays for history.
- **Deprecated** — no longer applies and has no replacement.
- **Rejected** — considered and declined (kept for the record).

**Workflow.** Copy the template below into `docs/adr/ADR-NNNN-<title>.md`, fill
it in, include it in the PR that implements (or commits to) the decision, and
add a row to the index. Superseding an ADR updates both ADRs' status and the
index.

## Consequences

- Decisions become reviewable in PRs and discoverable in one place; `AGENTS.md`
  points here as the living standard.
- Small per-ADR overhead, and the index must be kept in sync — a stale index is
  the main failure mode.
- ADRs complement, not replace, per-folder `docs.md` (noridocs): an ADR captures
  *why* a cross-cutting decision was made; `docs.md` describes *what* a module
  does.

## Index

| ADR | Title | Status | Epic |
|-----|-------|--------|------|
| [0000](ADR-0000-process.md) | ADR process | Accepted | E1 |
| [0001](ADR-0001-error-model.md) | Error model | Proposed | E3 |
| [0002](ADR-0002-design-tokens.md) | Design tokens | Accepted | E2 |
| [0003](ADR-0003-offline-persistence-contract.md) | Offline / persistence contract | Proposed | E4 |
| [0004](ADR-0004-async-and-state-conventions.md) | Async & state conventions | Proposed | E5 |
| [0005](ADR-0005-security-policy.md) | Security policy | Proposed | E6 |
| [0006](ADR-0006-observability.md) | Observability | Proposed | E3 |
| [0007](ADR-0007-lint-baseline.md) | Strict lint baseline | Accepted | E1 |
| [0008](ADR-0008-data-serialization.md) | Data serialization & safe-readers | Accepted | E8 |
| [0009](ADR-0009-release-obfuscation.md) | Release obfuscation | Accepted | E6 |

## Template

```markdown
# ADR-NNNN: <short title>

- Status: Proposed
- Date: YYYY-MM-DD
- Epic: <e.g. E3 (Error Handling & Observability)>
- Related: <issue IDs, related ADRs>

## Context

<The problem, forces, and constraints. Why a decision is needed now.>

## Decision

<The decision, in active voice: "We will …". Include the concrete rules.>

## Consequences

<What becomes easier or harder. Trade-offs, follow-ups, and risks.>
```
