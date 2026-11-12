# ModuloMarket Runtime Audit — 0.6.0

**Date:** 2026-11-12  
**Addon / update version:** 0.6.0  
**Parent MODULO:** 1.0.48 — unchanged  
**Scope:** Dark Foundry workspace completion: contextual craft filters, ingredient-led craft table, selected-entry memory/default selection, and expanded recipe inspector.

## Player problem and observable result

The user compared the live 0.5.9 Market with the approved All Crafts Dashboard mockup. The three-column layout and icon-led rows were present, but the My Crafts screenshot showed an empty selected-item panel on tab entry, generic filters, and a centre table that did not expose ingredient identities. The target is a fully populated and tab-aware workspace, not a reduced feature set.

## Evidence reviewed

- 0.5.9 GitHub update ZIP: `/mnt/data/mm_060_start/ModuloMarket-GitHub-Update-0.5.9.zip`; 929,726 bytes; SHA-256 `a4b9fca3b7a4ab6b12a0a2ff355754782236532506b938e96e09fe3d218b4625`; ZIP CRC PASS.
- 0.5.9 standalone runtime audit and UI polish documentation.
- 0.5.9 README and MANIFEST; TOC version `0.5.9`; seven tab models and 0.5.9 UI source/tests.
- User screenshots of live 0.5.9 My Crafts and the All Crafts dashboard mockup.
- Parent MODULO 1.0.48 source archive: 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; CRC PASS. Parent unchanged.

## Pre-change findings

- `SetTab` unconditionally cleared `UI.selectedItem`; `FinishView` rendered rows without selecting one. A newly opened tab therefore left the inspector empty until a manual click.
- The craft filter area had profession and recipe-source dropdowns but lacked the mockup's explicit craftability/profitability/review controls.
- Craft rows displayed numeric material cost but not ingredient identity in the centre table; reagent lines were available in recipe economics for detail display.
- `SetTab` changed craft columns but did not fully restore all row text positions when switching back to non-craft tabs.

## Change

- Added per-tab selected item/recipe identity memory. On view completion, restore the previous selected item when it remains in the filtered result set; otherwise select the first result. Empty result sets show an explicit no-match state.
- Added My Crafts / All Crafts filters:
  - Craftable only: known recipe, resolved output item/quantity and complete reagent cost.
  - Profitable only: calculated profit must be positive.
  - Review items only: explicit `freshnessStatus == "review"` only.
  - Hide non-profitable: removes calculated zero/negative profit but retains incomplete-profit rows.
- The craft table's Materials (cost) column now shows up to two real reagent icons and quantities plus total material cost. Hovering it exposes the complete reagent list, quantities, individual line costs/unknown-price state and total cost. Full reagent details remain in the right inspector.
- Recipe inspector now explicitly shows at-price quantity, total listed units, total material cost and acquisition classification alongside existing recipe identity, reagent, profit and warning information. Profit margin is displayed only when net sale value is available.
- Craft-specific columns have their own positions; non-craft item columns are restored when switching away from craft tabs.
- All seven tab data sources, existing market actions, Materials no-Listings layout, tooltip strata, whole-window opacity, 70862 baseline provenance and exact-current-build auction snapshot gate remain unchanged.

## Ownership and dependencies

All changes are in optional ModuloMarket. It continues to depend only on MODULO; MODULO 1.0.48 is unchanged and does not depend on ModuloMarket. No Auctionator, ProfessionMaster or other optional dependency was added.

## Risks and scope limits

- “Craftable only” is deliberately a data-completeness filter, not a claim that the character has the required current skill or materials in inventory.
- The compact centre table previews at most two reagent icons; hover and inspector retain every reagent.
- Automatic first-row selection is only a display default and does not infer recipe availability, READY state or acquisition certainty.
- Selection memory is per tab in the current UI session; it is not represented as persistent SavedVariables.
- Forever client checkbox interaction, tooltip display and exact layout remain runtime-unverified.

## Verification

- Full Python regression suite: `python -m pytest -q tests` — 157 passed.
- All nine addon Lua files: `texluac -p AddOns/ModuloMarket/*.lua` — PASS.
- Focused tests cover default/per-tab selection, filter semantics, ingredient-led table, full reagent hover, inspector fields and column restoration.
- Manifest file inventory, addon/TOC/README/manifest version agreement and fresh extraction are recorded in final release results.

## Runtime acceptance

**FOREVER runtime: NOT RUN.** On Forever client build `1.60.1.70888`, verify:

1. Opening My Crafts and All Crafts automatically selects the first visible result and fills the right inspector.
2. Switching between tabs restores each tab's previous selection when it remains visible; changing filters to exclude it selects the first remaining result.
3. Craftable only, Profitable only, Review items only and Hide non-profitable match their documented definitions.
4. Known, confirmed-future, borrowed, unknown and review states are not conflated.
5. All Crafts shows reagent icons/quantities and material cost; hovering the column shows every reagent and cost.
6. Selected recipe details show item/recipe identity, sale, at-price quantity, total units, full reagents, material cost, acquisition status, profit and review notes where applicable.
7. Switching repeatedly between craft and non-craft tabs does not misalign columns or hide market fields.
8. All seven tabs, tooltip layering, opacity, scanning, capture-cache behavior and data safeguards remain intact; no Lua errors occur.

Do not mark runtime acceptance PASS until the player confirms on the target client.
