# Modulo Market 0.11.6 — item status, quality, history and inspection

## Player problem and observable result

The player reported inconsistent row-edge learning markers across tabs, missing item-rarity name colours, a tooltip that replaced the native item tooltip with a Shift-click instruction, a Shift-click action that did not insert links into chat, an item missing from snapshot search, four history bars instead of the agreed three snapshots, and inconsistent inspector layout/titles.

0.11.6 provides:

- Learning-state edge markers are rendered in both Blizz-like and Modern for every item tab, including Crafts and Turn-Ins. Craft rows use their explicit recipe learning state; other rows use the existing item-level profession aggregation. A Waylaid crate with no profession status remains neutral.
- Item names use the client-reported WoW item quality colour (uncommon green, rare blue, epic purple, etc.) in all tabs and both presentations. The learning-state marker remains a separate visual channel.
- Market History stores at most the latest three completed Full Market snapshots and renders only those three. There is no wall-clock cutoff. The chart has three bars in both presentations.
- Hovering a row restores the native item tooltip (or recipe/spell tooltip for craft rows). The Shift-click instruction is removed from the tooltip.
- Shift-click first uses `ChatEdit_InsertLink` with the real item hyperlink when a WoW chat edit box is active. Otherwise, if the native Classic Auction House is open, it fills the Browse field with the plain item name, focuses/highlights it and does not submit.
- Search name matching now falls back to the client item cache via `GetItemInfo` when a saved snapshot row has no item name, before using the existing asynchronous tooltip-search warmup. Search still indexes the complete saved snapshot catalogue; it does not silently start a live AH query.
- Both presentations call the right-hand inspection area **Inspected Item**. Blizz-like now has a bordered item card like Modern. Turn-In column header is **REP / FAV** and remains right-aligned with its numeric values.

## Exact evidence and counter-evidence

### Row-edge learning markers

- Blizz-like `MarketUI.RenderRows` previously hid `statusMarker` for Crafts and explicitly hid it again for Turn-In rows.
- Modern `RefreshRowText` hid the marker whenever `state.tab == "crafts"`.
- The shared marker logic already distinguished known, learnable, unlearnable and unknown recipe states. 0.11.6 routes each row through a shared row-marker resolver and renders the marker for every tab. Recipe rows use `craftSourceStatus`; other items use the existing profession-data aggregation. Missing profession data does not become a learned/learnable state.

### Item rarity colour

- `GetItemQualityHex` already used the client `GetItemInfo(itemID)` quality result and `GetItemQualityColor` palette. It safely fell back to white when the client item data was not yet loaded.
- Non-Crafts rows already used `GetItemDisplayName`; Crafts rows replaced that with a learning-state font colour, and Modern rows displayed plain names.
- 0.11.6 reserves row-edge colour for learning state and applies the client quality colour to the item name in all rows/presentations. Name lookup falls back to cached `GetItemInfo` when the saved snapshot's `itemName` is missing. Unavailable quality data remains neutral white; no rarity is guessed.

### Three-snapshot history

- The 0.11.5 implementation used a 72-hour cutoff and allowed four snapshots.
- The new contract is count-based: `Replicate.SaveHistoryPoint` trims SavedVariables to three completed full-market points; the renderer reads only the last three points even when an older SavedVariables list still contains more. Both UI graphs allocate three bars/labels. The elapsed time represented by the chart is simply the time between those three scans.

### Native tooltip and Shift-click

- The previous Blizz-like hover appended "Shift-click to fill the Auction House search field" to the tooltip; Modern replaced the tooltip with the item name and the same instruction.
- The previous Shift-click helper inserted a display name containing WoW colour markup into `BrowseName` and did not call `ChatEdit_InsertLink`.
- 0.11.6 shares `ShowMarketItemTooltip` with Modern and uses the real item ID/hyperlink. When a chat edit box is active, Shift-click invokes the native `ChatEdit_InsertLink(itemLink)` path. Otherwise it fills the native `BrowseName` with the uncoloured item name. It never auto-submits an Auction House search and does not install a global chat-link hook.

### Snapshot search coverage

- The view builder searches every unique item aggregate created from the selected complete saved snapshot (`snapshot.rows`), not only the currently visible page.
- The prior name matcher used only `item.itemName` from the saved snapshot. If that optional field was absent, it searched the placeholder `Item #<id>` and relied on the tooltip path.
- 0.11.6 also checks the client cache name returned by `GetItemInfo` before the asynchronous tooltip path. The search does not add items that are absent from the saved snapshot and does not issue a new AH search.
- The supplied screenshot shows an Auctionator Shopping result while Modulo Market displays a Full Market snapshot, but it does not include a SavedVariables export or the item's ID. Therefore we cannot prove whether that exact item was absent from the snapshot or merely had an unloaded/missing snapshot name. If it is not in the completed snapshot at all, a snapshot-only search cannot return it; the result count indicates the snapshot catalogue size. Runtime acceptance should repeat the `Spire` query and compare the item ID against the saved snapshot.

### Artisan Waylaid Crate rewards

- The current `TurnInData.lua` contains eight Artisan crate rows (Earthly/Flowering Herbs, Ore, Textiles, Curiosities, Fabrics, Ingots and Parts). All eight deliberately have `rewardFavor=nil`, `rewardCashCopper=nil`, and `reputation=nil`; they are not zero-reward records.
- Current public references still do not provide the missing Artisan payout. Wowhead Forever's current faction guides list known Apprentice/Journeyman reward rows and say the complete crate list is still forthcoming. The 60.tools Merchant's Favor guide explicitly lists Expert/Artisan rewards as unknown. ForeverSpec also marks Artisan Favor unconfirmed. Sources checked 2026-11-14:
  - https://www.wowhead.com/forever/guide/durotar-supply-and-logistics-reputation-professions
  - https://www.wowhead.com/forever/guide/azeroth-commerce-authority-reputation-professions
  - https://www.60.tools/guides/merchants-favor
  - https://foreverspec.com/quests/waylaid-crates/
- The values remain UNKNOWN. No Expert-tier value, quality multiplier or player-level assumption is copied onto Artisan rows. A player quest-completion screenshot, quest ID/reward data or authoritative updated Forever source is required to change them.

### Inspector layout and Turn-In headers

- Blizz-like previously had no independent bordered item card above Market Information. 0.11.6 adds the item card within the right inspector and labels it Inspected Item. Modern's outer inspector and inner item card use the same title.
- The Turn-In data columns are still aligned by the existing dynamic right-aligned layout in Blizz-like and right-aligned numeric header geometry in Modern. The shared fourth column label is now `REP / FAV`.

## Ownership, dependencies and compatibility

- Owner: standalone Modulo Market addon.
- Parent MODULO source remains unchanged.
- No optional addon dependency added.
- No SavedVariables schema change. Existing histories with more than three points are trimmed on the next completed Full Market scan; the UI immediately renders only the newest three.
- Turn-In calculations, Writ reputation provenance, crate completion costs, scanner flow, market snapshots, and pricing/depth fail-closed behavior are unchanged.

## Validation plan and acceptance

1. In both presentations, inspect All Items, Economics, Crafts, Materials, Turn-Ins and History. Confirm row-edge status markers appear wherever a supported learning state exists.
2. Confirm item name colours follow client item quality, while edge markers continue to represent learning state.
3. Run three Full Market scans and confirm exactly three history records/bars are retained; old SavedVariables entries should not show a fourth bar.
4. Hover ordinary item rows and Crafts rows; confirm native item/spell tooltip appears without Shift-click instructional copy.
5. Shift-click a row while chat edit is active; confirm the real item link inserts. Shift-click with no chat edit active and native AH Browse open; confirm plain item name fills the Browse field without auto-search.
6. Search `Spire` against a complete snapshot and compare the exact item ID against snapshot rows. If absent from the snapshot, classify as snapshot coverage/data capture, not a name-search defect.
7. Confirm Artisan rows remain UNKNOWN until reward evidence is available.
8. Confirm both inspectors use Inspected Item and the Turn-In header reads REP / FAV.

Forever runtime acceptance is NOT RUN until the player tests this build on the target client. Retail runtime is NOT RUN.
