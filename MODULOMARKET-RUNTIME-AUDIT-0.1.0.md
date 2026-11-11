# Modulo Market Runtime Audit 0.1.0 — first Market product milestone

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.1.0  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release class:** separate optional child addon; first product-facing Market milestone.  
**Runtime status:** source and offline model tests PASS; new Forever runtime behavior NOT RUN.

## 1. Player problem and observable result

The previous releases proved that Market could collect and preserve a Browse-summary snapshot and that Forever could return an initial Replicate auction-list response. They did not give the player a useful trading workflow. The player could not search a practical market database, inspect a variant's current supply/lowest price, or compare an acquisition cost against expected sale proceeds.

0.1.0 makes `/mm` open a dedicated Market screen with:
- search by item name or item ID;
- a result list with variant name, lowest unit buyout and listed quantity;
- item detail with item ID, item level and suffix;
- manually entered acquisition cost per unit;
- planned sale quantity;
- configurable Auction House cut (default 5%);
- estimated net per unit, break-even gross price, per-unit and total profit/loss, and margin.

It also implements a full Replicate acquisition path with bounded traversal, item-data retry, item-variant aggregation and transactional persistence. The existing Browse-summary scanner remains available at `/mmscan` and its last-known-good snapshot remains separate.

## 2. Evidence and counter-evidence

### Supporting evidence

- Player screenshot/runtime evidence: Forever client 1.60.1/build 70862/interface 16001 completed a Browse snapshot of **16,574 variants across 34 pages in 21.1 seconds**, with **16.8 seconds waiting for the Auction House throttle**.
- Player screenshots: Market 0.0.7 saved Browse snapshot data survived `/reload`.
- Player screenshots: one explicitly confirmed `ReplicateItems()` request returned **291,276 auctions in 17.0 seconds**. Three sampled records reported `hasAllInfo=true`. This is FOREVER OBSERVED for the initial response only.
- Player screenshot: ProfessionMaster-style data-age/countdown presentation from 0.0.13 rendered in the target UI.
- Supplied Auctionator 341 source: `Source_ModernAH/FullScan/Mixins/Frame.lua` uses `GetReplicateItemInfo`, `GetReplicateItemLink`, and `GetReplicateItemTimeLeft`; reads stack count from return 3, total buyout from return 10, itemID from return 17 and `hasAllInfo` from return 18; processes bounded 250-record batches; requests missing item data and revisits records; and aggregates per-unit price and stack quantity. This is reference evidence only, not a dependency or proof of Market correctness.
- Supplied Auctionator utility `Source/Utilities/DBKeyFromLink.lua` demonstrates that item-link identity may require item ID plus equipment item level and suffix/variant information, rather than item ID alone.
- Supplied ProfessionMaster source confirms its modern-client countdown is based on its own locally recorded scan timestamp. It does not provide a global account-wide Replicate history.
- Forever API reference identifies the `GetReplicateItemInfo` tuple and zero-based indices, `GetReplicateItemLink`, `GetReplicateItemBattlePetInfo`, `C_Item.GetItemNameByID`, `C_Item.GetDetailedItemLevelInfo`, `C_Item.RequestLoadItemDataByID`, and `ITEM_DATA_LOAD_RESULT`. Relevant API references: [GetReplicateItemInfo](https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.GetReplicateItemInfo), [ReplicateItems and shared throttle/event behavior](https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.ReplicateItems), [GetReplicateItemBattlePetInfo](https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.GetReplicateItemBattlePetInfo), and [C_Item APIs](https://warcraft.wiki.gg/wiki/API).
- Supplied AddOns archive contains Auctionator **344** and ProfessionMaster **7.2.10**. ProfessionMaster's `services/auction-scan-service.lua` documents a 15-minute scan cooldown, uses 1,000-record processing batches for its relevant-item price service, and describes the local character timestamp as a countdown source that cannot independently identify an external scan. Auctionator 344's full scan uses 250-record batches and item-data callbacks; these implementations are behavioral references, not dependencies.

### Counter-evidence and unknowns

- The player's 291,276 count is auction-level records, not unique item variants.
- Three `hasAllInfo=true` samples do not prove that all 291,276 records are complete.
- The later no-response attempt followed recent Auctionator and ProfessionMaster scans; shared cooldown interference is plausible but was not proven.
- The initial 17.0-second response is not full traversal, enrichment, variant parsing, aggregation or persistence time.
- A documented historical disconnect/slowdown risk exists for very busy Replicate lists. One successful initial response above the older cited 80,000-auction threshold is useful counter-evidence but does not establish safe full traversal.
- Exact equality between Replicate-derived variants/prices/quantities and Browse-summary results remains unproven.
- `C_Item` cache/load behavior and `ITEM_DATA_LOAD_RESULT` completion rates on the user's Forever build remain UNKNOWN until the player runs 0.1.0.

## 3. Direction gate and ownership

### Player problem
The player needs a usable way to decide whether buying an item at a given cost and selling it at the current lowest listing price appears profitable after the Auction House cut.

### Finished result
The player can search saved market data, select an item variant, enter cost/quantity/cut, and see an explicitly qualified estimate. The full scan path can produce a new persistent market dataset without replacing the previous good dataset on failure.

### Ownership
- Owner: separate optional child addon `ModuloMarket`.
- Parent MODULO 1.0.48 remains unchanged.
- Dependency direction remains one-way: Market depends on MODULO; MODULO does not depend on Market.
- Auctionator owns its own auction-economy workflow; ProfessionMaster owns profession management. Their source is reference-only.
- Market does not read their SavedVariables/private APIs, import their queues, or require either addon.
- The new screen and manual cost-basis calculator are Market-owned.

### Rejected shortcuts
- Do not aggregate by itemID alone.
- Do not treat missing buyout as zero-copper price.
- Do not replace the previous Market snapshot at scan start or on partial completion.
- Do not automatically send or retry a Replicate request.
- Do not claim the local 15-minute countdown is a global cooldown oracle.
- Do not claim a lowest asking price guarantees a sale.

## 4. 0.1.0 implementation

### 4.1 Full Replicate acquisition

New file: `AddOns/ModuloMarket/Replicate.lua`.

- Player starts with **Update Market (Bulk)**.
- A warning explains the account-wide 15-minute cooldown, external-addon consumption, historical busy-AH risk, and no-retry rule.
- A separate **Confirm Full Scan** action is required.
- The local attempt timestamp is saved before calling `C_AuctionHouse.ReplicateItems()`.
- One attempt per session is enforced; the persisted local timer also blocks immediate attempts after reload.
- Waits up to 90 seconds for the initial `REPLICATE_ITEM_LIST_UPDATE`.
- The initial event is unregistered immediately after receipt because the same event can also fire as item data is cached while records are read.
- Reads zero-based auction indices in batches of 250 per frame.
- Requests at most 20 unique item IDs per frame through `C_Item.RequestLoadItemDataByID`.
- Tracks pending auction indices by item ID and revisits them after `ITEM_DATA_LOAD_RESULT`.
- 15-minute total processing timeout and maximum 500,000 auction-record safety cap.
- Stops on Auction House close, staged Sell-tab item, initial response timeout, processing timeout, invalid/missing data, or API failures.
- No seller/bidder identity is read or stored.

### 4.2 Item variant identity

Item links are parsed into:
- item ID;
- detailed item level from `C_Item.GetDetailedItemLevelInfo` when available;
- suffix ID;
- bonus-list IDs;
- modifier type/value pairs;
- battle-pet species identity where exposed by the battle-pet item link.

This matches the dimensions already considered by the Browse scanner's `ItemKeyIdentity` helper. Browse snapshots now also persist the full item-key dimensions available in Browse results. The Browse JSON schema advances to 3 and includes item name, pet identity, bonus lists and modifiers.

The link parser is deliberately fail-closed: an invalid/unsupported link or unresolved item data increments the unresolved count and prevents snapshot commit.

### 4.3 Auction aggregation

For each identified auction:
- stack count is `GetReplicateItemInfo` return 3;
- total buyout is return 10;
- item ID is return 17;
- `hasAllInfo` is return 18;
- candidate unit buyout is `ceil(totalBuyoutCopper / stackCount)` for positive buyout and stack count;
- total listed quantity sums all valid stack counts, including listings without a buyout;
- priced quantity and unpriced quantity are tracked separately;
- minimum-price depth sums stack counts at the current minimum unit price;
- auction counts are tracked separately from item quantities.

Bid-only/no-buyout auctions do not become a fake zero-price listing. Rows with no buyout have `minPriceCopper=nil`.

### 4.4 Transactional persistence

The Replicate result is saved under `ModuloMarketDB.lastMarketSnapshot`, separately from `ModuloMarketDB.lastSnapshot`.

Commit requires:
- every reported auction index processed;
- no unresolved auction records;
- no invalid item IDs or stack counts;
- no info or link accessor errors;
- SavedVariables available.

Only then is `lastMarketSnapshot` replaced. If acquisition or enrichment is incomplete, the previous `lastMarketSnapshot` remains unchanged. Replicate scans never overwrite the Browse snapshot.

### 4.5 Player-facing Market and profitability

New file: `AddOns/ModuloMarket/MarketUI.lua`.

- `/mm` now opens the Market interface.
- `/mmscan` opens the retained Browse-summary scanner and JSON copy/export tools.
- `/mmdebug` remains the read-only profession/API diagnostic panel.
- The Market screen searches by name or item ID and displays variant, lowest unit price and listed quantity.
- Item-name resolution is cached per item ID to avoid repeating item-name API calls across the full result set. Selecting an older row whose name is not cached requests item data.
- Cost basis is saved per item variant in `ModuloMarketDB.costBasisByItemKey`, in copper.
- The configured AH cut is saved in `ModuloMarketDB.auctionHouseCutPercent`, default 5%.

Profit model:
- `netUnit = floor(lowestUnitBuyout * (1 - cutPercent / 100))`
- `profitPerUnit = netUnit - acquisitionCostPerUnit`
- `totalProfit = profitPerUnit * plannedQuantity`
- `breakEvenGross = ceil(acquisitionCostPerUnit / (1 - cutPercent / 100))`

The screen warns when planned quantity exceeds total listed supply or known lowest-price depth. Browse snapshots do not expose lowest-price depth, so the UI says the Browse-based estimate assumes all units sell at the current lowest ask.

This is a planning estimate. It excludes posting deposits, materials/crafting costs, vendor costs, unsold inventory, undercuts, and sale probability. It does not buy, bid, post, cancel or modify auctions.

## 5. Dependencies, compatibility and security

- Parent MODULO 1.0.48 is unchanged.
- No new addon dependency was added.
- Auctionator and ProfessionMaster remain optional and independent.
- No private SavedVariables or private APIs from either addon are read.
- Uses Forever 1.60.1 Auction House Replicate API and C_Item item-data API surfaces.
- The 15-minute cooldown is shared account-wide. Market's persisted timer only tracks Market's own attempts; external request times remain UNKNOWN.
- Sell-tab safety is fail-closed using the existing Market safety gate.
- No Auction House transaction API is called.
- No protected purchase/post/cancel action is added.

## 6. Files and source review

### Canonical sources
- Parent: `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, ZIP CRC PASS, 506 members. Project file ID `file_000000001a2482128af00913b054f6f9`.
- Previous child: `ModuloMarket-0.0.13.zip`, 76,623 bytes, SHA-256 `427461ceebcf7d13147ece48ee6f01167ffa8e256546fe76493a790ab4fb8bcb`, ZIP CRC PASS.
- Supplied ecosystem archive: `AddOns.zip`, 143,179,120 bytes, SHA-256 `2b595d3de2d8a73b166a98535e4d843b939c7b7ad5afe51dd8f76a1369a4efb2`, ZIP CRC PASS.

### Reviewed
- Parent project start, README, workflow, progress, decisions, QA, source-review ledger, architecture, Forever compatibility contract, product direction and reference environment.
- Current Market `Core.lua`, `Scanner.lua`, `Diagnostics.lua`, TOC, manifest, README, prior runtime audits and focused tests.
- Supplied Auctionator full-scan frame and DBKeyFromLink utility.
- Supplied ProfessionMaster scan button and scan service for its local cooldown presentation.
- Relevant Forever API documentation for Replicate tuple, events, item links and item-data loading.

### Changed
- `Core.lua`: version and slash command routing (`/mm`, `/mmscan`, `/mmdebug`).
- `ModuloMarket.toc`: version 0.1.0 and new Replicate/Market UI load order.
- `Scanner.lua`: full Browse item-key persistence, schema-3 JSON export, Market status/UI refresh integration.
- `Replicate.lua`: new bounded full-list acquisition, item-data queue, variant aggregation, and last-known-good Market snapshot commit.
- `MarketUI.lua`: search, item detail, cost basis, quantity and profit/loss estimator.
- `README.md`, `MANIFEST.json`, this audit and tests.

Unrelated MODULO source modules and unrelated Market profession diagnostics were not changed.

## 7. Automated tests and package validation

Expected commands and results for the completed build:
- `python -m pytest -q tests` — **52 passed**.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**. Covers explicit request, bounded traversal, item-data queue, variant separation, buyout aggregation, unpriced supply, last-known-good preservation and profit/break-even math.
- `texlua tests/market_ui_0_1_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**. Covers Market window construction, snapshot metadata, item selection, price formatting, profit/break-even display, saved cost basis and name filtering.
- Fresh extraction tests and ZIP CRC — **PASS** (see final package handoff).
- Forever runtime of the new full traversal and Market UI — **NOT RUN**.
- Retail runtime — **NOT RUN**.

## 8. Player acceptance and exit criteria

### First UI check (does not consume Replicate cooldown)
1. Install Market 0.1.0 beside MODULO 1.0.48.
2. `/reload`, open the Auction House, type `/mm`.
3. Confirm the Market window opens, previous Browse snapshot appears, search by an item ID, select a result and enter a test cost/quantity.
4. Confirm net proceeds, break-even and profit/loss update when cost, quantity or AH cut changes.
5. Confirm `/mmscan` still opens the Browse scanner and JSON copy/export remains available.

### Full Replicate test (consumes shared cooldown)
1. Ensure no Auctionator, ProfessionMaster or other Replicate scan is running.
2. Wait at least 15 minutes after the last Replicate scan from any addon.
3. Open the Auction House, `/mm`, choose **Update Market (Bulk)**, read the warning, then explicitly confirm.
4. Keep the Auction House open and do not browse, buy, sell, post or run another AH scan while processing.
5. Capture the progress/completion status and any Lua errors.
6. After a normal reload/logout flushes SavedVariables, provide `WTF/Account/<account>/SavedVariables/ModuloMarket.lua` so the actual variant rows, counts, names, quantities, prices and timestamp can be checked.
7. Compare matched variants and prices against a fresh Browse-summary snapshot. Do not treat the new Replicate snapshot as equivalent until this comparison passes.

### Acceptance requirements
- Full auction list traverses without UI freeze/Lua error/disconnect.
- All records resolve to item variants, or Market refuses to replace the prior snapshot and reports unresolved records.
- Price and quantity aggregation are correct for stacks, suffixes, bonus lists and modifiers.
- Profit/loss values match independently calculated scenarios.
- Existing Browse snapshot remains intact.
- Full client restart persistence is confirmed separately from `/reload`.

## 9. Exit state

0.1.0 delivers a player-facing Market search and profit/loss estimator plus a source-implemented production Replicate acquisition/aggregation path. It is the first real Market product milestone, not a claim of Forever runtime acceptance.

**FOREVER OBSERVED:** Browse snapshots and initial Replicate response only.  
**SOURCE IMPLEMENTED; FOREVER RUNTIME NOT RUN:** full Replicate traversal, item data enrichment, variant aggregation, transactional Market snapshot, Market UI and profit/loss.  
**NOT RUN / UNKNOWN:** full 291,276-record traversal on Forever, API/item data behavior at scale, Browse equivalence, full-client restart persistence, and 50% end-to-end performance improvement.
