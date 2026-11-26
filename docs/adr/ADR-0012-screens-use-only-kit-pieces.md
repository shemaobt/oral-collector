# ADR-0012: A screen is built only from kit pieces

- Status: Accepted
- Date: 2026-11-26
- Related: ENG-3068, ENG-3069, ENG-3067, ADR-0002, ADR-0007

## Context

Stages 3 to 9 of the redesign rebuild almost every screen on the kit that stage 2 builds in `lib/shared/widgets/`. Without a written rule, each agent that builds a screen tends to write its own button, card or shadow inside the screen, and the look drifts from the kit.

In atomic-design terms the kit holds the atoms (colours, signs, numbers, times), the molecules (disc, button, field, row, card) and the organisms (player, quick notice, sheet, question, bar, web menu). A screen is only the page that arranges them.

On 2026-11-26 the owner chose to keep the kit's pieces as the only way a screen draws anything.

## Decision

A screen is built only from the kit's pieces, and a new piece enters the kit before any screen uses it.

1. Code under `lib/features/**/presentation/` draws only with pieces from `lib/shared/widgets/` and tokens from `lib/core/theme/`. Layout primitives (`Row`, `Column`, `Padding`, `SizedBox`, `Expanded`, `Text` and their like) are allowed anywhere. What comes from the kit is the drawing: raw Material widgets (buttons, cards, chips, dialogs and the like), raw decoration and raw shadows are banned.
2. A screen that needs something the kit lacks adds the piece to the kit first, in its own ticket or in the same pull request, with its line in `lib/shared/widgets/docs.md`.
3. The kit's pieces live flat in `lib/shared/widgets/`, named after the piece. A piece's own sub-widgets may sit in a folder named after that piece; nothing else gets a folder. There are no `atoms/` or `molecules/` folders: each name already says what the piece is.
4. The `obt_lints` rule `only_kit_pieces` enforces the rule. It starts with today's files exempt and loses an exemption each time a screen is rebuilt.

## Consequences

- A screen reads as an arrangement of kit pieces. A restyle changes the kit once instead of every screen.
- A screen change that needs a new look is a kit change first. That costs one extra piece and one `docs.md` line, and is reviewed as such.
- Until `only_kit_pieces` ships (ENG-3069), the rule is enforced by review only.
- While exemptions remain, old screens still draw with raw Material pieces. The exemption list is the measure of what is left to rebuild.
- The catalogue screen (ENG-3067) shows every kit piece, so a missing piece is visible before a screen reinvents it.
