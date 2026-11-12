# ModuloMarket Runtime Audit 0.6.7 — simplified recipe-source filters

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.6.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The recipe-source dropdown split unlearned recipes into `confirmed`, `borrowed` and `unknown` categories. The player asked to apply the same source-selection rule used by the inspector: use a direct Forever source when available, otherwise use the Classic source as a practical fallback, without displaying provenance categories.

The filters now distinguish only learning state:

- All recipes
- Known by you
- Unlearned

The item-role filter similarly uses All item types, Known craft outputs and Unlearned craft outputs, while retaining Gathering resources and Crafting reagents. The UI no longer asks the player to decide whether an acquisition record is Forever or Classic.

## Evidence and counter-evidence

- 0.6.6 already implements the compact single-source presentation and preserves all acquisition evidence internally.
- The canonical 70888 data contains mixed Forever-observed, Classic-borrowed and unknown source rows. A single recipe can have multiple evidence classes.
- Recipe learning state (`known` versus unlearned) is separate from acquisition provenance. Treating every borrowed row as unavailable would contradict the product rule to use Classic information as fallback.
- A recipe with no established source remains unlearned; the filter does not claim that its acquisition route is known.
- No evidence was found that the 0.6.7 filter change requires a new ForeverDB capture or API request.

## Implementation

- All Crafts dropdown now exposes All recipes, Known by you and Unlearned.
- All Items item-role dropdown now exposes All item types, Known craft outputs and Unlearned craft outputs, plus the existing gathering/material roles.
- All Crafts unlearned matching accepts every non-known source status, including future, borrowed, unknown and automatic.
- `ProfessionData.Matches(..., "unlearned")` includes outputs with either supported future recipes or unknown-source future recipes, provided no known recipe already takes precedence.
- Evidence labels and alternative acquisition rows remain in canonical/runtime data; only player-facing filter categories were simplified.
- Filter heading and tooltip now describe recipe status and item roles rather than acquisition evidence.

## Scope, ownership and risks

- Only the optional ModuloMarket child repository changes. Parent MODULO 1.0.48 is unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No API calls, API-key handling, SavedVariables schema changes, new dependencies, recipe catalogue data changes, auction snapshot changes or source-selection precedence changes.
- The `Unlearned` filter includes recipes whose acquisition source is unknown. This is intentional: it is a learning-state filter, not an availability guarantee.

## Tests and verification

- Focused regression set: **28 passed**. Includes the new 0.6.7 filter tests and regression tests for acquisition source preservation, compact inspector, layout and 70888 refresh.
- Full historical pytest suite: **156 passed, 38 failed**. Failures are legacy tests pinned to older UI/version contracts (0.5.9/0.6.0/0.6.2/0.6.3 and 0.5.4-era version reporting); they are not counted as passes. The focused set passes.
- Lua interpreter/compiler (`lua`/`luac`) is not installed in this build environment; Lua syntax was therefore **NOT RUN** in this slice.
- Archive CRC and fresh extraction are checked in the release handoff below.
- Forever runtime: **NOT RUN**.

## Player acceptance

1. Open All Crafts. Dropdown shows All recipes, Known by you and Unlearned only.
2. Select Unlearned. Verify recipes with Forever sources, Classic fallback sources and unknown sources are all included.
3. Open All Items. Dropdown shows All item types, Known craft outputs and Unlearned craft outputs, plus Gathering resources and Crafting reagents.
4. Verify no filter tooltip labels a source as confirmed, borrowed or unknown.
5. Verify inspector still chooses one preferred acquisition route and continues to use Classic as fallback only when no direct Forever source supersedes it.
6. Verify all seven tabs and no Lua errors.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.
