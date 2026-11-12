# ModuloMarket 0.6.7 — recipe-source filter simplification

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.6.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.

## Player problem

The All Crafts filter exposed `Unlearned: confirmed`, `Unlearned: borrowed` and `Unlearned: unknown`. The All Items item-role filter exposed equivalent evidence categories. These labels made provider provenance a player-facing navigation concept, despite the product decision in 0.6.6 to choose one useful acquisition route and use Classic as a fallback when no direct Forever source supersedes it.

## Decision

Player-facing filters classify recipe learning state, not acquisition evidence:

- All recipes / All item types
- Known by you / Known craft outputs
- Unlearned / Unlearned craft outputs

The unlearned role includes every recipe not recorded as learned, whether its best available acquisition route comes from Forever, Classic fallback data, or has no established source. It does not claim the source is confirmed or currently available.

For inspector and tooltip presentation, the existing 0.6.6 source-selection rule remains: prefer a direct `FOREVER_OBSERVED` source; otherwise use `CLASSIC_BORROWED` as the practical fallback, then `FOREVER_CLIENT`, then `UNKNOWN`, while skipping inferred trainer observations as primary sources. This filter change does not alter that selection logic.

Underlying per-record evidence and source rows remain intact for provenance, correction and future data refreshes. They are not exposed as separate filter choices or explanatory filter tooltips.

## Implementation

- All Crafts options reduced to All recipes, Known by you and Unlearned.
- Item-role options reduced to All item types, Known craft outputs and Unlearned craft outputs, retaining Gathering resources and Crafting reagents.
- All Crafts unlearned matching now includes `future`, `borrowed`, `unknown` and automatic-learning statuses; only `known` is excluded.
- `ProfessionData.Matches(..., "unlearned")` includes output items with any unlearned supported or unknown-source recipe and excludes items already produced by a known recipe.
- Filter label and helper tooltip now describe recipe status/item role, not source evidence.
- No canonical ForeverDB data, source precedence, recipe economics, SavedVariables schema, API usage, or parent MODULO files changed.

## Acceptance and tests

Focused regression tests cover the compact option set, removal of evidence-specific labels, inclusion of all unlearned source classes, retention of gathering/material roles, and release version agreement.

Forever runtime acceptance remains NOT RUN. In-game checks should verify All Crafts and All Items each show only the simplified learned/unlearned choices and that borrowed and unknown unlearned recipes remain included under Unlearned.
