# MODULOMARKET-RUNTIME-AUDIT-0.11.7

**Release:** Modulo Market 0.11.7  
**Audit date:** 2026-11-14  
**Source baseline:** `ModuloMarket-GitHub-Update-0.11.6.zip`  
**Baseline SHA-256:** `7a3d87858853db752c58152747391d30eb011fa5ff5587bb17575309ed269186`  
**Baseline integrity:** ZIP CRC PASS; 251 archive entries; 251 manifest entries; manifest, Core, TOC and TurnInData all `0.11.6`.  
**Parent MODULO:** supplied project context reports MODULO source `1.0.48`; no parent MODULO files were changed.

## 1. Player problem and observable result

The player supplied screenshots showing:
- Both market windows could reopen at a stale saved position, leaving much of the window off-screen.
- All visible item names remained white rather than taking the item's WoW rarity colour.
- Modern numeric headers/values were fixed-width, causing `TOTAL UNI...` truncation and inconsistent alignment on All Items, Economics, Materials and History. Crafts needed the same shared layout rule.
- Shift-click inserted plain-looking text in chat and did not reliably populate the Auction House Browse field.
- Modern's inspector used `INSPECTED ITEM` for both the outer panel and inner item card.
- Modern search appeared broken and showed `0–0 / 0`.
- The player supplied the Artisan crate reward schedule and requested that it be used directly.

## 2. Root-cause analysis

### Window placement

**Confirmed source cause:** both `CreateUI` functions restored the last dragged centre coordinates. The explicit `/mm` show/toggle paths showed the frame without clearing that anchor. A stale position therefore survived relog/reload and was restored outside the current visible game area.

### Item rarity

**Confirmed source weakness:** `GetItemQualityHex` correctly used `GetItemInfo` and `GetItemQualityColor`, but returned white when item quality was not yet in the client item cache. It did not itself request missing item data. The separate icon/vendor/search code could load some items, but that was incidental and not a reliable row-colour lifecycle.

**Competing possibility:** Forever could expose a nil/unknown quality for an item even after a request completes. The diagnostic is the `GetItemInfo(itemID)` quality return plus `GetItemQualityColor(quality)` after `GET_ITEM_INFO_RECEIVED` / `ITEM_DATA_LOAD_RESULT`. The implementation now requests only visible rows and refreshes both UIs on completion; actual target-client colour acceptance remains NOT RUN.

### Shift-click

**Confirmed source cause:** Modulo Market called the legacy global `ChatEdit_InsertLink` directly, then implemented its own `BrowseName` path. The supplied Auctionator source (`AddOns/Auctionator/Source/Shopping/Hooks.lua`) hooks `ChatFrameUtil.InsertLink` when that namespaced dispatcher exists, and only falls back to the global alias when it does not. A recent Forever/Era compatibility note for Dibs likewise records that modified clicks on those clients route through `ChatFrameUtil.InsertLink`, while the global is a deprecated alias.

Blizzard's dispatcher is the correct owner of the focused-chat versus Auction House destination choice. The current Blizzard source shows `ChatFrameUtil.InsertLink` handling the active chat window and native Auction House search dispatch; this source is supporting API research, not proof of the exact Forever 1.60.1 implementation. References:
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/ChatFrameUtilOverrides.lua
- https://www.curseforge.com/wow/addons/dibs/files/9151146/dependencies

### Modern table layout

**Confirmed source cause:** Modern headers and row fields used fixed x offsets and fixed widths. No content measurement/recalculation was performed as rows changed. The screenshot's truncated `TOTAL UNI...` is consistent with that fixed geometry.

### Search

Two competing hypotheses were retained:

1. **Snapshot coverage:** the searched item ID may not exist in `ModuloMarketDB.lastMarketSnapshot.rows`. Auctionator Shopping showing `Enchantresses' Spire` proves only that Auctionator found it; it does not prove the same item was in Modulo Market's saved Full Market snapshot.
2. **Search/cache lifecycle:** `GetItemName` previously gated its legacy `GetItemInfo` lookup behind `C_Item.IsItemDataCachedByID`. If that probe returned false while the legacy item cache could already return the name, the search helper would unnecessarily fall back to `Item #ID`. Modern also cleared its displayed rows while the shared incremental filter/tooltip warm-up was running, but its result counter showed only `0–0 / 0`, concealing progress.

0.11.7 removes the separate cache-probe gate and exposes filtering, tooltip warm-up and sorting progress. It preserves the snapshot-only search boundary.

**Evidence gap:** the supplied `WTF.zip` was inspected; it contains no `ModuloMarket.lua` SavedVariables file/export. The exact `Enchantresses' Spire` item ID therefore cannot be compared with `lastMarketSnapshot.rows`. This specific membership question remains UNKNOWN.

## 3. Implementation in 0.11.7

### Window centering

- Both Blizz-like and Modern explicitly clear their prior point and anchor to the centre of `UIParent` whenever `/mm` opens the window.
- Dragging remains enabled while open. Drag coordinates are still saved, but centering deliberately supersedes them at the next open.

### Rarity

- Visible rows request item data through `C_Item.RequestLoadItemDataByID` when quality is not cached.
- Pending IDs prevent duplicate requests; failed item-data requests fail closed without retry loops.
- On item-data completion, the quality cache/pending state is cleared and both Blizz-like and Modern rows rerender.
- Real quality colours are used when returned by the client. White remains the neutral fallback while quality is unavailable; no rarity is invented.
- Existing learning-state row-edge markers remain independent and unchanged.

### Modern columns

- A shared content-measured column layout is applied on All Items, Economics, Crafts, Materials, Turn-Ins and History.
- Each visible numeric column measures its header and visible row values, applies bounded width limits and aligns right.
- Item/Recipe is left-aligned and receives the remaining width.
- Recalculation runs on row render, so tab changes, sorting, filtering and scrolling update the geometry.

### Shift-click

- `ChatFrameUtil.InsertLink(itemLink)` is now the preferred dispatcher.
- This passes a real item hyperlink to Blizzard's modified-click path. Focused chat should receive a clickable item link; without chat focus, the native Auction House path can fill its search field with the plain item name.
- A compatibility fallback uses the global `ChatEdit_InsertLink` only when the namespaced dispatcher is unavailable, and a legacy `BrowseName` fallback fills plain text without brackets or submitting the search.
- Modulo Market does not replace or hook Blizzard's global chat-link functions.

### Search

- `GetItemName` always attempts `GetItemInfo(itemID)` when the snapshot row has no name.
- Modern now shows `Searching…`, filter row progress, tooltip description warm-up progress or sorting state instead of appearing idle at `0–0 / 0`.
- Search continues to use the saved snapshot only. No live Auction House query or implicit snapshot expansion was introduced.

### Inspector

- Modern outer panel: `INSPECTED ITEM`.
- Modern inner item card: `SELECTED ITEM`.
- Blizz-like keeps its single `Inspected Item` heading.

### Artisan Waylaid Crates

The eight Artisan crate records now use the player's supplied schedule:
- Herbs, Ore, Textiles, Curiosities: **20 Favor / 1,000 copper (10 Silver)**.
- Fabrics, Ingots, Parts: **40 Favor / 2,000 copper (20 Silver)**.
- Cash conversion is 50 copper per Favor.
- Reputation remains `nil` because no reputation quantity was supplied. Favor and cash are now known in the display and calculations.
- The one-time Shipping Label reward remains separate from repeatable crate calculations.

## 4. Ownership, dependencies and preserved scope

- Owner: standalone Modulo Market addon.
- Parent MODULO remains unchanged; no optional addon dependency was added.
- No SavedVariables schema change.
- Three-snapshot Market History is preserved.
- Learning-state markers, native hover tooltips, scan flow, pricing, market depth, Writ calculations, recipe capture and fail-closed rules are preserved.

## 5. Offline validation

- Focused 0.11.7 + current release regression gates: **90 passed**.
- All addon Lua files compiled with `texluac -p`: **14/14 passed**.
- Modern UI harness: **34 checks passed**, including right-aligned numeric cells and left-aligned Item/Recipe.
- Turn-In crate harness: **9 checks passed**, including raw/processed Artisan Favor/cash values, 30 crate records, 96 one-of bundle alternatives, pricing depth and missing-price fail-closed behaviour.
- Writ harness: **11 Writ checks + explicit crate-type check passed**; 145/150 exact recipe coverage matched against embedded ForeverDB data.
- Scan state-machine harness: **8 checks passed**.
- Custom utility TGA assets: **6/6 valid RGBA 64×64**.
- Full regression suite: **359 passed / 87 failed / 446 total**.
- 0.11.6 baseline: **350 passed / 87 failed / 437 total**.
- The exact same **87 failing test IDs** remain; **zero new failing IDs** were introduced. Nine additional tests passed. The 87 failures are historical suite failures and are not runtime acceptance evidence.

## 6. Package and runtime evidence

- Source tree version agreement: Core, TOC, TurnInData, WritData and manifest all `0.11.7`.
- Final ZIP CRC: **PASS** (`ZipFile.testzip() == None`); **254** archive entries.
- Fresh extraction: **PASS**; all 254 extracted paths exactly match the 254 paths in `MANIFEST.json`.
- Forever runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.
- GitHub push: **NOT RUN**; the prior remote write attempt was blocked with HTTP 403. This release is supplied as a complete local bundle.

## 7. Acceptance and exit criteria

Source/offline acceptance is complete. Forever runtime acceptance remains open until the player confirms:

1. `/mm` centres both presentations after relog, and after closing/reopening.
2. Uncommon/rare/epic item names receive their actual quality colours in all six tabs after the item cache loads.
3. Modern numeric columns fit and right-align on every tab, including long visible values after scroll/sort/filter.
4. Shift-click in focused chat inserts a clickable item hyperlink; without chat focus and with the native Auction House open, the Browse search receives plain text without brackets and without auto-submit.
5. Searching a known snapshot item returns results. `Enchantresses' Spire` is diagnosed by comparing its exact item ID with the saved snapshot.
6. Modern inspector shows outer `Inspected Item` and inner `Selected Item`.
7. Artisan crates show the supplied category-specific Favor/cash returns.

**Exit status:** 0.11.7 source implementation and offline validation PASS; Forever and Retail runtime acceptance NOT RUN; `Spire` snapshot membership UNKNOWN pending the Modulo Market SavedVariables export.
