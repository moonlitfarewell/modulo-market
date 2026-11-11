# ModuloMarket Runtime Audit — 0.5.6

**Date:** 2026-11-11  
**Addon / bundle version:** 0.5.6  
**Parent MODULO:** 1.0.48 — unchanged  
**Scope:** Dark Foundry three-column workspace redesign; automatic known-profession capture deduplication; All Crafts economic column expansion.

## 1. Player problem and observable result

The user selected `Modulo Market_ All Crafts Dashboard.png` as the visual premise. The existing Market UI had seven tabs, but its 1220×760 layout placed search and profession controls across the top and the market table/detail pane in a two-area layout. The requested premise is a full-width global market toolbar, full-width tabs, contextual filters at left, the active tab's complete information in the centre, and a persistent selected-entry inspection at right.

The user also supplied a runtime screenshot showing repeated chat output:

```text
ModuloMarket: Captured known Tailoring recipes (31).
```

repeatedly while crafting. The previous capture path scheduled a full recipe schematic capture after every `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE`, and `TRADE_SKILL_DATA_SOURCE_CHANGED` event, without comparing the current profession list with the saved list.

## 2. Evidence and competing hypotheses

### UI evidence

- The attached dashboard image is the user-selected design premise (not a pixel-perfect spec).
- The 0.5.5 source confirms seven existing tabs and virtualized 25-row rendering.
- The 0.5.5 README and manifest document the existing seven market views, recipe economics, market scans, filters, price history, gathering/material roles and selected-item detail behavior.

### Craft-capture hypotheses

1. A profession-list event fires after each craft, and every event causes a full recipe/schematic recapture.
2. Multiple profession events are queued in quick succession and each independently starts a full capture.

Source inspection confirms the first mechanism is possible and sufficient: all three events unconditionally scheduled capture; the 0.25-second timer only coalesced events that arrived before it ran. No list signature or completed-capture cache existed.

A recipe-ID signature alone is not enough to detect learning. `C_TradeSkillUI.GetAllRecipeIDs()` returns all recipes, learned and unlearned, while `GetRecipeInfo(...).learned` carries the per-recipe learned state. The implementation therefore uses the recipe-list signature to suppress ordinary unchanged-list events and `NEW_RECIPE_LEARNED` to force a refresh when a recipe becomes learned without changing the ID set. References:
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetAllRecipeIDs
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetRecipeInfo
- https://wowlua.dev/api/events/NEW_RECIPE_LEARNED
- https://wowlua.dev/api/events/TRADE_SKILL_LIST_UPDATE

The exact Forever build event cadence still needs live confirmation.

## 3. Implementation

### Workspace redesign

- Logical frame size: 1460×850, with screen-fit scaling when screen dimensions are available.
- Global market actions remain at the top: Update Full Market, confirmation/cancel flow, Browse Scan, Close and background opacity.
- All seven tabs remain visible and directly accessible.
- Contextual Search, Profession and Recipe Source / Item Role controls move into the left filter column.
- The centre column becomes the primary tab workspace and retains virtualized rows, incremental filtering and incremental sorting.
- The right column remains the persistent selected-entry inspection area.
- Search, profession and role filters are stored independently per tab.
- Dark Foundry styling uses near-black surfaces, muted bronze framing and restrained gold accents.

### All Crafts information

All Crafts now displays six distinct columns:
- Recipe
- Sale / Unit
- Materials
- At Price
- Total
- Profit / Craft

`At Price` is the available quantity at the lowest ask (`minPriceQuantity`). `Total` is total listed quantity (`totalQuantity`). Profit remains unavailable when required prices/quantities are missing or the saved auction snapshot does not match the current client build.

The other tab views retain their own data interpretation in the expanded six-column table. No tab or market workflow is intentionally removed.

### Automatic recipe capture cache

- `RecipeListSignature()` sorts and serializes the current profession's recipe IDs.
- The signature is saved alongside the existing character/profession recipe store.
- An unchanged signature suppresses another full schematic capture and suppresses repeated capture chat output.
- A 0.50-second timer coalesces event bursts.
- `NEW_RECIPE_LEARNED` forces capture even when the full recipe-ID set is unchanged.
- If a forced learn event arrives while a same-profession capture is active, one follow-up forced capture is queued.
- The capture remains automatic. No manual recipe reporting or manual correction workflow was introduced.

## 4. Ownership, dependencies and data safety

- Both changes belong to the separate optional ModuloMarket child addon.
- Parent MODULO 1.0.48 is unchanged.
- No new addon dependency, network request, API credential, or market provider was added.
- The ForeverDB 1.60.1.70862 baseline and its source provenance are untouched.
- Four hotfix-linked review flags remain intact.
- Exact-current-client auction snapshot gating remains intact; old-build auction prices are not joined to current-client craft profitability.

## 5. Risks and scope limits

- The 1460×850 layout is screen-scaled where `GetScreenWidth`/`GetScreenHeight` are available; actual readability and click targets need Forever runtime review at the user's resolution.
- The six-column layouts and selected-entry panel require visual/runtime review across all seven tabs; offline tests cannot prove every field fits at all UI scales.
- The capture cache relies on `NEW_RECIPE_LEARNED` being emitted on the target Forever client when a new recipe is learned. If Forever does not emit it, new-learn detection may require a bounded alternate signal. This is NOT yet runtime verified.
- The signature check still reads the current recipe-ID list on a profession-list event, but avoids rereading every recipe schematic when the list is unchanged. The repeated full capture and repeated chat output are the behaviours this slice is designed to stop.

## 6. Verification

### Offline tests

- Full Python suite: **136 passed**.
- Recipe capture Lua harness: **PASS**; initial known recipes captured, unchanged list skipped without a capture message, and a newly learned recipe was captured by forced refresh even though the recipe-ID list stayed identical.
- Market UI Lua integration harnesses: included in the full suite and passed.
- Lua syntax: all 9 addon Lua files checked with `texluac -p` — PASS.

### Package checks

- GitHub update ZIP is rooted entirely under `modulo-market/`.
- ZIP CRC/integrity and exact manifest inventory: PASS after final package generation.
- Fresh extraction: `/mnt/data/mm_056_final_fresh/modulo-market`; full Python suite **136 passed** and all 9 Lua files pass `texluac -p` — PASS.
- Parent MODULO 1.0.48: no files changed by this slice.

## 7. Runtime status and acceptance

| Capability / test | Status |
|---|---|
| 0.5.5 baseline-plus-delta recipe data behavior | Preserved; prior source/offline verification retained |
| Exact current-client auction snapshot gate | Preserved; prior source/offline verification retained |
| Seven-tab workspace layout | SOURCE/OFFLINE VERIFIED; Forever runtime NOT RUN |
| All Crafts Sale / Unit, Materials, At Price, Total, Profit columns | SOURCE/OFFLINE VERIFIED; Forever runtime NOT RUN |
| Per-tab filter state | SOURCE/OFFLINE VERIFIED; Forever runtime NOT RUN |
| Unchanged profession list suppresses full capture | OFFLINE HARNESS PASS; Forever runtime NOT RUN |
| NEW_RECIPE_LEARNED forced refresh | OFFLINE HARNESS PASS; Forever runtime NOT RUN |
| Crafting spam defect resolved on Forever | NOT RUN — user acceptance required |
| Layout readability and interactions across all seven tabs | NOT RUN — user acceptance required |
| Forever 1.60.1 build 70888 runtime | NOT YET VERIFIED for this release |

## 8. Player acceptance checklist

1. Install 0.5.6 and open `/mm`.
2. Confirm the top toolbar and all seven tabs are visible.
3. Visit every tab; confirm the left filters, full middle data and right selected-entry details update correctly.
4. In All Crafts, verify Sale / Unit, Materials, At Price, Total and Profit / Craft are distinct and correctly populated.
5. Switch tabs after entering different searches/filters; confirm each tab restores its own values.
6. Open Tailoring, craft several items, and confirm the repeated `Captured known Tailoring recipes (31).` message no longer appears for unchanged recipe lists.
7. Learn a recipe, then confirm it is detected and added automatically without manual reporting.
8. Confirm no Lua errors, no lost recipe data, and that the 70862 baseline provenance/review warnings and 70888 auction snapshot gate remain correct.

**Release readiness is not Forever runtime verification. All target-client acceptance above remains NOT RUN until the user tests it.**
