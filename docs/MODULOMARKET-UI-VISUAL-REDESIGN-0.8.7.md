# ModuloMarket UI Visual Refinement 0.8.7 — Dark Foundry alignment

## Purpose
This is a narrow continuation of the approved Dark Foundry redesign. The annotated All Items reference v2 is the controlling guidance where older annotations differ: retain six tabs; My Crafts remains absent; preserve the three-panel layout; improve hierarchy and spacing without adding controls or changing market behavior.

## Player problem and observable result
- The Profit / Craft heading is positioned 16px to the right of its right-anchored row value in the standard market, Economics and Crafts views. The Materials view's final heading also does not align to its right-anchored final value.
- The Relationships card is visually cramped despite unused inspector space. Its scroll viewport is 74px.
- The player-visible change is a corrected profit-column heading and a taller Relationships viewport. Market History remains present in a more compact lower card.

## Implementation
- Standard market and Economics views: Profit / Craft header starts at x=914, matching the right-anchored 176px row value. At Price and Total remain at their already-aligned coordinates.
- Crafts view: Profit / Craft header starts at x=920, matching the right-anchored 170px row value.
- Materials view: the final heading starts at x=836, matching the right-anchored 254px row value.
- Relationships card grows from 120px to 152px; scroll viewport and initial child grow from 74px to 106px. Existing `RenderMarketRecipeContext` and `RenderCraftDetail` sources remain unchanged and continue to size longer content dynamically.
- Market History card moves down 32px and contracts from 256px to 224px. Its text and four-point graph are repositioned; graph height changes from 145px to 126px. The existing saved-history data and percentage-change calculations are untouched.

## Preserved boundaries
- Six tabs remain All Items, Economics, Crafts, Materials, Low Supply and History. My Crafts is not reintroduced.
- Existing search, profession, item-role, item-type and quick-filter semantics are unchanged.
- No item/recipe/gathering mappings, market formulas, auction scan acquisition, exact-build compatibility checks, SavedVariables, external dependencies, parent MODULO source or specialist addons changed.
- No new API calls, requests, assets, or security surface.

## Evidence and limits
- The user-provided All Items screenshot demonstrates the 0.8.4 interface rendered on Forever build 70938; it is not evidence for this 0.8.7 source change.
- The user-provided annotated visual reference v2 supports the six-tab, three-panel and inspector-space direction.
- Offline source regressions and harnesses pass as recorded in the 0.8.7 runtime audit.
- Forever 1.60.1 runtime acceptance of 0.8.7 is NOT RUN. Actual rendering, text wrapping, scrolling, and graph fit must be checked in the target client.
