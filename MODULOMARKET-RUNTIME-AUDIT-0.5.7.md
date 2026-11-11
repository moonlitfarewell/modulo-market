# ModuloMarket Runtime Audit — 0.5.7

**Date:** 2026-11-11  
**Addon / bundle version:** 0.5.7  
**Parent MODULO:** 1.0.48 — unchanged  
**Scope:** Forever-client UI feedback fixes: item/recipe hover tooltips, tooltip strata, whole-window opacity, contextual filter help, Materials column layout, and Dark Foundry panel refinement.

## 1. Player problem and observable result

The user supplied 0.5.6 screenshots from Forever client build `1.60.1.70888` showing:

1. Item and recipe hover tooltips were absent.
2. Hovering a tab produced a tooltip behind the Market window.
3. The opacity slider changed only the frame/template background rather than the complete window.
4. The Materials tab included a Listings column the user did not need.
5. The UI needed to move closer to the user-selected Dark Foundry reference while retaining all tab information and functionality.

Acceptance target: item/recipe hover details are visible above the Market; tab and filter help is visible; opacity affects the whole Market window; Materials uses its space for Best Craft Profit rather than Listings; other tabs retain their relevant listing information; all seven tabs and their data remain intact.

## 2. Source findings and competing causes

### Tooltip layering

- 0.5.6 set the main Market frame to `TOOLTIP` strata.
- `GameTooltip` was also set to `TOOLTIP` strata. Raising frame level within the same strata did not guarantee the tooltip would appear above the Market on the target client.
- The fix separates the strata: Market `DIALOG`; GameTooltip and dropdown menus `TOOLTIP`; tooltip frame level is raised relative to its owner.

### Missing item and recipe tooltips

- The virtualized row buttons had click selection handlers but no `OnEnter` item/recipe tooltip handlers.
- Selected-item and recipe metadata text had no independent hover targets.
- 0.5.7 adds hover targets to the row's name region and selected item/recipe detail regions. It tries the client item/spell tooltip methods and hyperlink fallbacks, with a plain-text fallback if the client cannot resolve a native tooltip.

### Opacity

- 0.5.6 changed template backdrop/inset alpha, while the custom left, centre and right panel textures used fixed alpha values.
- 0.5.7 uses `frame:SetAlpha(alpha)`, so all child UI (panels, controls, text and frame contents) fades together. Independent GameTooltip content remains separate. Slider range is 35–100%.

### Materials table

- Materials previously reused the generic item-view six-column header set, including Listings.
- 0.5.7 gives Materials five visible columns and moves Best Craft Profit into the former Listings position. Other tabs retain Listings where meaningful.

## 3. Implementation and retained capability

- Seven tabs remain: All Items, Economics, My Crafts, All Crafts, Materials, Low Supply and History.
- Global market actions, contextual filters, centre data workspace and right selected-entry inspector remain.
- All Crafts retains Recipe, Sale / Unit, Materials, At Price, Total and Profit / Craft.
- Materials retains item, cheapest price, at-price quantity, total units and best craft profit; only the redundant Listings column is removed from that tab.
- Known/future/borrowed/unknown role option descriptions remain. Search, profession and role controls now also have explanatory hover help.
- The 70862 ForeverDB recipe baseline, four review flags, and exact-current-client auction snapshot gate are unchanged.
- The 0.5.6 profession capture cache/deduplication behavior is unchanged.
- No parent MODULO files or dependency direction changed.

## 4. Risks and compatibility gaps

- `GameTooltip:SetItemByID`, `GameTooltip:SetSpellByID`, `GameTooltip:SetHyperlink` and `GameTooltip:NumLines` may vary on the Forever client. Calls are guarded; a text fallback is used when no native tooltip content is available.
- The exact tooltip strata/frame-level ordering must be checked in the target client.
- Whole-window opacity intentionally fades labels, controls and text as well as backgrounds. The 35% lower bound is intended to avoid fully obscuring the UI, but visual legibility needs player acceptance.
- The Materials column alignment and all tab table layouts need live visual checks at the user's UI scale/resolution.
- This release does not claim new recipe or market-data verification.

## 5. Offline verification

Commands run from the extracted `modulo-market/` project root:

- `python -m pytest -q` — **141 passed**.
- `find AddOns/ModuloMarket -name '*.lua' -print0 | xargs -0 -n1 texluac -p` — **9 Lua files syntax PASS**.
- Focused 0.5.7 source tests cover strata separation, item/recipe hover targets, filter help, whole-window opacity and Materials' five-column layout.
- The previous 0.5.6 profession-capture cache regression tests remain in the suite and pass.

These are offline/source checks, not Forever runtime acceptance.

## 6. Forever runtime acceptance

**Status: NOT RUN — user must install 0.5.7 on Forever build `1.60.1.70888`.**

1. Hover a market item name. Confirm its item tooltip appears above the Market.
2. Hover a recipe name in My Crafts and All Crafts. Confirm recipe information appears above the Market; verify selected item and recipe detail hover targets separately.
3. Hover every tab. Confirm its description appears in front of the window.
4. Hover Search, Profession, Recipe Source / Item Role, and each future/borrowed/unknown dropdown option. Confirm useful descriptions appear in front.
5. Move opacity from 100% to 50% and back. Confirm the whole Market window, including text and controls, changes opacity while tooltips remain legible.
6. Open Materials. Confirm there is no Listings column and Best Craft Profit occupies the freed space. Check All Items and Low Supply still retain their appropriate listing information.
7. Visit all seven tabs and confirm the full data, filtering, sorting, selection and right-side inspection still work.
8. Confirm no Lua errors.

No Forever runtime result is claimed in this audit. Any failure remains open until reproduced and player-visible acceptance passes on the target client.
