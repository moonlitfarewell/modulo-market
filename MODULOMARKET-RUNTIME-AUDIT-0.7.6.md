# ModuloMarket Runtime Audit 0.7.6 — first-open filter overlap and complete tooltip cache gating

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.5.zip`  
**Previous bundle bytes:** 1,697,779  
**Previous bundle SHA-256:** `959d142b8318e887f15803c78b2200a2cfa6ac2e524e3cb9953d3d53ac13a777`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.

## Player-visible defects and evidence

1. On first opening the Market window, controls from the Crafts and Economics filter groups overlap in the left filter panel. Clicking any tab corrects the layout. The supplied screenshot shows both groups visible at the same coordinates while the active tab is All Items.
2. Searching `spirit` initially returned only Egg Nog, although a later result set showed seven matches including Wicked Smoothie. `/mmtooltipdebug 249876` returned structured tooltip text containing `20 spirit for 15 min`. The same submitted search subsequently found multiple rows. This proves the extraction API can return the desired effect text on this client, but the first-search inconsistency was not yet explained by a controlled runtime trace.

## Root cause and competing hypotheses

### First-open overlap — source-confirmed root cause

`CreateUI()` constructs the Craft and Economics checkbox groups with visible-by-default frames. `SetTab()` owns the visibility rules, but prior to 0.7.6 it was only invoked by tab button clicks. It was never called during initial construction. The inactive controls therefore remained visible until the player changed tabs.

### Inconsistent first tooltip search — hypotheses

1. **Partial structured tooltip read before item data cache completion.** In 0.7.5 `GetTooltipSearchText()` called `C_TooltipInfo.GetItemByID()` before checking `C_Item.IsItemDataCachedByID()`. If the structured API returned a non-empty but incomplete tooltip for an uncached item, the code could cache that partial text and never request the completed item data. This is a source-supported defect path, but not yet confirmed as the exact cause of the player's first one-result search.
2. **Search submission/warmup lifecycle or stale view completion.** A first pass could be superseded or observed before its final tooltip-warmed pass. This remains a competing explanation until the same item is traced through request, item-data event, extraction and final view completion.

The distinguishing runtime diagnostic is whether the target item is reported uncached when first examined, whether a load request is sent, and whether structured extraction happens only after the cache API reports ready. The updated `/mmsearchdebug` and `/mmtooltipdebug 249876` remain available.

## Implementation in 0.7.6

- Calls `SetTab(UI.activeTab or "market")` once at the end of initial UI construction, after all tab-specific filter controls and event handlers exist. This applies the same visibility rules used by later tab clicks before the first frame is shown.
- Checks `C_Item.IsItemDataCachedByID(itemID)` before calling the structured tooltip API whenever that cache API exists.
- If the item is not cached, requests its item data through `C_Item.RequestLoadItemDataByID`, returns pending, and lets the existing bounded warmup/event path retry after the item-data event.
- Uses `GetItemInfo` as the readiness fallback only when the cache API is unavailable.
- Keeps structured `C_TooltipInfo.GetItemByID` extraction and the guarded GameTooltip fallback unchanged once item data is ready.
- No new dependency, saved-variable state, manual reporting or cooldown state.

## Ownership and scope

- ModuloMarket remains a separate optional addon depending on MODULO.
- Parent MODULO 1.0.48 is unchanged and does not depend on ModuloMarket.
- No ForeverDB dataset, importer, recipe acquisition records, prices, auction snapshots or other tabs were changed.

## Offline verification

- Focused 0.7.6 regression tests: **4 passed**.
- Changed Lua files `MarketUI.lua` and `Core.lua`: `texlua` `loadfile` syntax checks PASS.
- Core/TOC/manifest version agreement: **0.7.6**, PASS.
- Manifest inventory and package extraction checks: recorded at handoff.
- Full historical suite: NOT RUN for this correction; prior 0.7.5 historical run was 180 passed / 59 failed due retained version-pinned and superseded UI assertions.

## Forever runtime acceptance — NOT RUN

1. Open ModuloMarket fresh without clicking another tab. On All Items, only All Items filters should be visible; no Craft or Economics filter labels/checkboxes may overlap.
2. Click Crafts, Economics, Materials and back to All Items. Each tab should show only its own relevant filter group.
3. In Crafts / Cooking, submit `spirit` with Enter on a cold item cache. Wait for the warmup to finish. Wicked Smoothie must appear when its item tooltip is loaded because its effect grants Spirit.
4. Run `/mmtooltipdebug 249876`; output must include the `20 spirit for 15 min` effect text.
5. Run `/mmsearchdebug`; confirm requests/events/warmup complete without repeated full search restarts.
6. Repeat with `healing` and `spell damage`; results must settle and include tooltip-only matches.
7. No Lua errors, freezes, taint or broken interactions.

**Exit status:** SOURCE IMPLEMENTED; focused offline checks PASS; Forever runtime NOT RUN. Keep both runtime defects open until the player confirms first-open layout and cold-cache search behavior on build 70888.
