# Modulo Market 0.11.7 — centered windows, native links, Modern table fit and Artisan rewards

## Player problem and observable result

The player reported:
- `/mm` reopened a saved window position that could leave most of the window outside the visible game area.
- Item names in both presentations remained white despite the 0.11.6 rarity-colour implementation.
- Modern numeric columns were fixed-width: `TOTAL UNI...` was truncated and numeric columns were not consistently right-aligned/content-sized.
- Crafts looked acceptable but needed the same layout rule applied as the other tabs.
- Shift-click inserted only the item name in chat, and did not consistently fill the native Auction House search box.
- Modern showed `INSPECTED ITEM` twice, instead of the outer inspector heading plus an inner `SELECTED ITEM` card.
- Modern search displayed `0–0 / 0` and appeared not to return matches.
- Artisan Waylaid Crates should use the player-supplied raw/processed Favor and cash schedule.

## Implementation

### Window placement

- Both Blizz-like and Modern windows now clear their saved anchor and center against `UIParent` every time the player explicitly opens `/mm` (including the open branch of the toggle).
- The player can still drag either window while it is open. Drag coordinates continue to be saved for diagnostics/position reset compatibility, but are intentionally superseded by centering on the next open.
- The invisible Blizz-like backend used by Modern is not shown as a user-facing window and does not affect Modern placement.

### Item rarity colours

- `GetItemQualityHex` still reads the real client item quality and `GetItemQualityColor`; rarity is never guessed.
- When the visible row's item information is not yet cached, the addon now calls `C_Item.RequestLoadItemDataByID` once per item ID.
- `GET_ITEM_INFO_RECEIVED` / `ITEM_DATA_LOAD_RESULT` clears the pending marker and quality cache, then rerenders both presentations. The visible row transitions from the neutral white fallback to the actual client rarity colour when the client supplies quality data.
- This is limited to currently rendered rows; the addon does not request the entire 6,000-item catalogue at once.
- Learning-state edge markers remain independent and unchanged.

### Modern table layout

- All Items, Economics, Crafts, Materials, Turn-Ins and History now share one measured-column layout.
- Numeric widths are based on the current tab's header strings and visible row values, with bounded minimum/maximum widths.
- Numeric columns are right-aligned and anchored to the right edge. The Item/Recipe column is left-aligned and takes the remaining width.
- Widths are recalculated during row rendering, including after tab changes, sorting, filtering and scrolling.
- Crafts is included in the same shared measurement path; its data and calculations are unchanged.

### Native Shift-click

- The previous implementation called the legacy global `ChatEdit_InsertLink` directly before its custom Auction House fallback.
- The supplied Auctionator source hooks `ChatFrameUtil.InsertLink` when available, and falls back to the legacy global only when that dispatcher is unavailable. A recent Forever/Era addon compatibility note likewise reports that modified clicks route through `ChatFrameUtil.InsertLink`, while the global is a deprecated alias.
- Modulo Market now calls `ChatFrameUtil.InsertLink(itemLink)` first. Blizzard's dispatcher decides whether to insert the actual hyperlink into focused chat or place the plain item name into the Auction House search UI.
- If the dispatcher is unavailable or returns false, the legacy fallback inserts the link into a genuinely focused chat edit box, or fills `BrowseName` with the plain name (without brackets and without submitting a search).
- No global Blizzard function is replaced or hooked by Modulo Market.

### Search

- `GetItemName` now always attempts the legacy `GetItemInfo(itemID)` lookup when the snapshot row has no name. It no longer lets a separate `C_Item.IsItemDataCachedByID` result suppress a name already available through the target client's legacy item cache.
- Modern's result counter now shows `Searching…`, row-filter progress, tooltip-description warm-up progress, or sorting state instead of appearing to be stuck at `0–0 / 0` while the shared incremental pipeline is working.
- The search remains scoped to the saved Full Market snapshot. It does not silently query the live Auction House or add rows that are absent from the snapshot.
- **Spire membership remains UNKNOWN:** the supplied `WTF.zip` was inspected and contains no `ModuloMarket.lua` SavedVariables export. The screenshots prove the item appeared in Auctionator Shopping, not that its item ID was present in Modulo Market's saved Full Market snapshot. Compare the exact item ID against `ModuloMarketDB.lastMarketSnapshot.rows` to determine whether this is a missing snapshot record or a search/index defect.

### Inspector labels

- Modern's outer panel remains `INSPECTED ITEM`.
- The item card inside it is now `SELECTED ITEM`.
- Blizz-like retains its single `Inspected Item` heading and card structure.

### Artisan Waylaid Crate rewards

The eight Artisan records now use the supplied category schedule:
- Raw-material categories — Herbs, Ore, Textiles and Curiosities: **20 Merchant's Favor and 1,000 copper (10 Silver)**.
- Processed-material categories — Fabrics, Ingots and Parts: **40 Merchant's Favor and 2,000 copper (20 Silver)**.
- Both schedules use **50 copper per Favor**.
- Reputation remains `nil` because the supplied schedule did not specify a reputation quantity. The UI displays the known Favor reward rather than treating Favor/cash as unknown.
- No one-time Shipping Label bonus is included in repeatable crate calculations.

### Preserved behaviour

- Three latest completed Full Market snapshots in History.
- Learning-state row-edge markers on every tab in both presentations.
- Native item and recipe tooltips on hover.
- Existing market snapshot, scan lifecycle, item grouping, pricing/depth fail-closed rules, Writ calculations, recipe capture and SavedVariables schema.
- No parent MODULO source change and no optional addon dependency.

## Ownership and compatibility

- Owner: standalone Modulo Market addon.
- MODULO remains unchanged; no optional addon dependency is introduced.
- Target client remains Forever 1.60.1 build 70938. Current runtime compatibility is not inferred from Retail source or current Mainline API behavior.

## Runtime acceptance

Forever runtime: **NOT RUN**. Retail runtime: **NOT RUN**.

Required in-client checks:
1. Open `/mm` after relog with an intentionally off-centre saved position; both presentations should open centred. Drag while open, close and reopen; it should centre again.
2. Confirm uncommon/rare/epic item names acquire the actual client quality colours after item data loads in all six tabs, while learning markers remain unchanged.
3. Verify all Modern tabs: numeric headings/values align right, longest visible `Total Units` is not truncated, and Item/Recipe uses remaining width. Scroll and sort to long values.
4. Shift-click with chat focused; chat should receive a clickable item hyperlink. With chat unfocused and native Auction House open, the native Browse field should receive the plain item name without brackets and without starting the search.
5. Search a known item already present in the saved snapshot; observe progress and final results. For `Enchantresses' Spire`, compare its exact item ID against the saved snapshot.
6. Confirm Modern outer `Inspected Item` / inner `Selected Item`.
7. Confirm all eight Artisan rows show the category-specific Favor/cash return and known completion-cost math.

**Exit status:** source/offline implementation complete. Target-client runtime acceptance and exact `Spire` snapshot membership remain open.
