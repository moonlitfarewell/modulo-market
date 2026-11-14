# Modulo Market 0.12.0 Search and Item-Information Audit

Date: 2026-11-14

## Player problem and intended result

The player reports that typing into search appears to start filtering immediately/repeatedly, that `Empresses' Spire` was visible on the Auction House but not returned by a `spire` search, and that item rarity colours remain absent. The player also confirmed 0.11.9 opens and populates the 6,317-item catalogue without the prior Windows hard hang.

Acceptance goals for this slice:
- Typing uses a clear trailing debounce and ordinary matching does not trigger a full tooltip search.
- Deep tooltip search remains available only through an explicit action.
- Search can use item names embedded in auction hyperlinks when the snapshot's `itemName` field is absent or generic.
- Forever item-info access follows the compatibility approach used by ProfessionMaster without introducing a dependency on it.
- Rarity uses Blizzard's quality table when the client's item cache already has quality; unknown quality remains neutral and no rarity-specific item-data requests are made.

## Source evidence inspected

- `ModuloMarket-GitHub-Update-0.11.6.zip`, `0.11.7.zip`, and `0.11.9.zip`; all were opened from the supplied archives. The 0.11.9 ZIP CRC test passes.
- Supplied `WTF.zip`, including `WTF/Account/453173582#1/SavedVariables/ModuloMarket.lua`.
- Supplied `AddOns.zip`, including the ProfessionMaster source tree.
- Supplied screenshot showing ProfessionMaster's own item-name colour presentation.

## Debounce and search diagnosis

0.11.9's `SEARCH_DEBOUNCE_SECONDS` was 0.35 seconds. `Now()` uses `_G.GetTime()`, so this is 350 milliseconds. `OnTextChanged` schedules/resets the due time. `OnEnterPressed` intentionally bypasses the timer and starts a deeper search immediately. When the timer elapsed, however, the OnUpdate handler set `tooltipSearchMode = true`; consequently every debounced typed search enabled the tooltip warm-up and description pass. This broad second stage could look like repeated searching even though the initial text-change handler was debounced.

0.12.0 changes the trailing debounce to 0.5 seconds. The debounced path explicitly keeps `tooltipSearchMode = false`; ordinary typing searches names, IDs, recipes, professions and variant names only. Enter remains the explicit opt-in to the existing deep tooltip-description search. Search-generation invalidation remains in place so an older filter build/warm-up cannot become the current result after newer text is entered.

## Empresses' Spire coverage diagnosis

The supplied SavedVariables contains a `lastMarketSnapshot` with:
- `source = C_AuctionHouse.ReplicateItems`
- `complete = true` and `dataComplete = true`
- `timestampText = 2026-11-14 14:12:48`
- `auctionCount = 268656`
- `processedAuctionCount = 268656`
- `resultCount = 29351` item variants
- 6,317 distinct item IDs after catalogue grouping (as shown in the player's runtime screenshot)

The exact string `Empresses' Spire` does not occur in the supplied saved variables, including the saved Full Market and Browse snapshot data. `Spire of the Stoneshaper` does occur. The saved snapshot therefore cannot return an exact-name result for `Empresses' Spire` unless the item is represented under a different name/ID or its listing appears in a newer scan.

`Replicate.lua` marks its snapshot complete when every record returned by `GetNumReplicateItems` has been processed and all records resolve without the tracked invalid/unresolved conditions. This establishes processing completeness for the returned replication dataset; it does not independently establish that a listing visible at another time was present in that response. Competing explanations remain:
1. The item was not in the server's replication response at the time of the saved scan (or was listed later/earlier than that scan).
2. The item was present under another item ID/name, or the row's name field was missing while its item hyperlink contained the display name.

The distinguishing evidence is the exact in-game item hyperlink/item ID and a fresh Full Market scan while the listing is visible. Without that item ID, the precise cause and broader missing-item count remain UNKNOWN. Do not claim that all Auction House listings are represented merely because `complete=true`.

## ProfessionMaster comparison

The supplied ProfessionMaster source uses `self.addon.compat.GetItemInfo(itemId)` and then `ITEM_QUALITY_COLORS[itemQuality].hex` in `views/cooldown-view.lua` and `views/guild-cooldowns-panel.lua`. Its `LibMasterAddons-1.1.26.lua` compatibility layer explicitly defines missing Classic `GetItemInfo` through `C_Item.GetItemInfo` without writing a global. Its leveling planner separately uses `Item:CreateFromItemID()` and `ContinueOnItemLoad()` for a bounded plan-level loading operation, then renders after the batch or a timeout.

Modulo Market adopts the passive lookup pattern for rarity and the local global-or-`C_Item.GetItemInfo` compatibility fallback. It does not depend on ProfessionMaster and does not copy its broader planner-loading workflow. The 0.11.7 render-triggered rarity request path remains removed.

## 0.12.0 implementation

- Increase trailing debounce from 350 ms to 500 ms.
- Keep ordinary typing on name/ID/recipe/profession/variant matching only.
- Preserve Enter as the explicit deep tooltip-search action.
- Preserve search-generation invalidation and obsolete build/warm-up cancellation.
- Add display-name extraction from `|h[Item Name]|h` auction hyperlink strings as a fallback for aggregate and variant rows.
- Add a local `GetItemInfoCompat` helper: use `_G.GetItemInfo` when present, otherwise `C_Item.GetItemInfo`, matching ProfessionMaster's compatibility behaviour without depending on it.
- Use `ITEM_QUALITY_COLORS[quality].hex` for cached rarity, with `GetItemQualityColor` as a fallback and neutral white when quality is unavailable.
- No rarity-triggered item-data requests, SavedVariables schema changes, addon dependencies, scan-source changes, or market-data boundary changes.

## Ownership, dependencies and scope

Modulo Market owns its own market catalogue, search and presentation. ProfessionMaster is reference evidence only. No dependency on ProfessionMaster was added. The Full Market and Browse snapshot boundary remains unchanged. No parent MODULO source was used as an implementation baseline.

## Validation and acceptance

- Focused search/compatibility/rareness tests: **21 passed**.
- Full historical suite on the exact 0.11.9 archive: **362 passed / 90 failed**. The 0.12.0 working tree: **368 passed / 90 failed**; the same 90 failing test IDs remain, with **zero new failing IDs** and six additional passes.
- Lua syntax: **14/14 addon Lua files passed** `texluac -p`.
- Fresh-extraction focused tests, ZIP integrity, exact manifest inventory and SHA-256: recorded after final packaging.
- Forever runtime: NOT RUN for 0.12.0; 0.11.9 opening/population is FOREVER OBSERVED by the player's screenshot/report, but search/rarity acceptance is not yet established.
- Retail runtime: NOT RUN.

## Risks and remaining unknowns

- The exact `Empresses' Spire` item ID is unknown because the player has not supplied its item hyperlink. Its absence from the saved snapshot is confirmed, but whether it was present in the live replication response is unknown.
- A 500 ms debounce is a deliberate UX adjustment; the user's perceived latency must be checked in-game.
- Passive quality lookup may still show neutral white for uncached items. This is intentional; no new item-data request workload is introduced.
- Enter-triggered deep tooltip search retains its existing bounded warm-up and timeout behaviour. It should be used only when the user explicitly wants tooltip-description matching.
- The previous hard hang is improved in the user's 0.11.9 runtime test, but the root cause is not conclusively isolated. Preserve 0.11.9 as the comparison baseline; do not reintroduce render-triggered rarity requests.

## Acceptance test on Forever

1. Install 0.12.0 over 0.11.9 without deleting SavedVariables.
2. Open `/mm`; confirm it remains responsive for at least 30 seconds.
3. Type `spire` with ordinary typing; confirm results update only after approximately 500 ms of inactivity and that no tooltip warm-up starts.
4. Press Enter with a query to explicitly run deep tooltip search; confirm progress and completion/timeout are visible.
5. Test a known item whose `itemName` is absent/generic but whose auction item link contains a display name, if available.
6. Check rarity colours on cached items and neutral fallback on uncached items.
7. While `Empresses' Spire` is visibly listed in the Auction House, provide its item link and run a fresh Full Market scan; then compare its item ID against the saved rows and search result.

## Documentation completeness gate

- Source changes and rationale: recorded here and in README.
- Durable capability state: updated in `MANIFEST.json`.
- Historical decisions: no existing decision superseded; this is a scoped implementation pass.
- QA and runtime evidence: offline results recorded after completion; Forever/retail limitations explicit.
- Bundle provenance and SHA-256: recorded after final package creation.

## Final package evidence

- Complete bundle: `ModuloMarket-GitHub-Update-0.12.0.zip`
- Manifest inventory: 261 files; exact archive inventory match.
- ZIP CRC/integrity: PASS (`ZipFile.testzip() == None`).
- Fresh extraction: 261/261 inventory match; focused tests 21 passed; Lua syntax 14/14 passed.
- Full historical suite: 368 passed / 90 failed, with the exact same 90 failing test IDs as the extracted 0.11.9 baseline (362 passed / 90 failed); zero new failing IDs.
- Bundle SHA-256 is provided in the delivery message. The audit is embedded in the bundle and also delivered as a standalone copy.
