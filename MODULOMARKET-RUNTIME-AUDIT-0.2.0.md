# Modulo Market Runtime Audit 0.2.0 — responsiveness and grouped market experience

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.2.0  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release class:** separate optional child addon; player-facing capability/fix slice.  
**Runtime status:** offline tests and source checks PASS; new Forever runtime behavior NOT RUN.

## 1. Player problem and observable result

The player installed 0.1.0 and reported that opening `/mm` populated the 16,574-variant Browse snapshot but repeatedly froze the entire game window. The game resumed, froze again, and remained intermittently unresponsive even after the Market window was closed. The player described the addon as unusable.

The supplied screenshots establish that:
- the 0.1.0 Market window opened and populated from a saved Browse snapshot of 16,574 variants;
- the result list contained repeated-looking item names, such as multiple Archer's Belt rows with different prices;
- the separate Browse scanner could be opened over the Market and its controls visibly overlapped the Market detail panel;
- the Market labels/columns and selected-item area were cramped and visually confusing.

The target 0.2.0 observable result is:
- opening `/mm` returns immediately and starts any large data preparation incrementally;
- the list displays one row per item ID;
- each row shows cheapest unit price, quantity at that cheapest price when known, and total quantity across the saved variants;
- the player can search, inspect an item, enter a cost and quantity, compare current and target sale-price scenarios, view known-cost profitability rankings, filter low-supply items and compare historical prices;
- only the visible list rows are rendered and reused.

## 2. Source of truth and evidence actually available

### Canonical parent and child

- Parent: `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, 506 members, ZIP CRC PASS. This is the highest-version complete parent bundle supplied in this task.
- Parent archive includes and was checked for `PROJECT-START-HERE.txt`, `README.txt`, `WORKFLOW.txt`, `PROJECT-PROGRESS.md`, `PROJECT-DECISIONS.txt`, `QA.txt`, `SOURCE-REVIEW-LEDGER.md`, `MODULO-ARCHITECTURE.md` and `FOREVER-COMPATIBILITY-CONTRACT.md`.
- Previous child: `ModuloMarket-0.1.0.zip`, 103,161 bytes, SHA-256 `997fcfd6504a081d1ea903c5f51b7d11d83f50f66275fe9a70425607e05ec12e`, 36 members, ZIP CRC PASS.
- Previous child 0.0.13 and the supplied parent/AddOns archives remain available as earlier provenance. No MODULO parent source was changed.
- User-provided screenshots and runtime description are the evidence for the 0.1.0 freeze report. They are not a Lua profiler trace or a measured frame-time capture.

### Player evidence

**FOREVER OBSERVED — player report, 0.1.0:**
- `/mm` opened and showed the saved 16,574-variant Browse snapshot.
- The player experienced repeated whole-game UI hangs while the Market was open and intermittent hangs after closing it.
- Screenshots show repeated item names and overlapping/confusing controls.

**Counter-evidence / unknown:**
- No profiler, script execution time, frame trace, stack trace, event counter or SavedVariables export was supplied for the freeze.
- The screenshot does not establish that Market was the only loaded addon contributing to every stall.
- The user-visible report is accepted as a real defect. The exact contribution of any external addon remains unmeasured.

## 3. Competing root-cause hypotheses

### Hypothesis A — synchronous full-list construction and repeated sorting (strong source support)

0.1.0 `MarketUI.lua`:
- `RefreshList()` traversed every saved row.
- It called `GetRowName()` while filtering each row. When a row did not already contain a name, that function called `C_Item.GetItemNameByID`.
- It synchronously `table.sort`ed the entire matching result list.
- `CreateUI()` called `UI.Refresh()` during construction.
- The first `frame:Show()` then ran `OnShow -> UI.Refresh()` again, causing a second full traversal/filter/sort on initial open.
- A 16,574-row dataset therefore incurred two synchronous list rebuilds before the player could interact.

This is directly established by the supplied 0.1.0 source. It is the strongest code-level explanation for the initial repeated stall.

### Hypothesis B — repeated event/lifecycle refreshes (possible, not proven)

0.1.0 also registered `ITEM_DATA_LOAD_RESULT` on the main UI frame. That handler cleared the item-name cache and called `RefreshList()` again. Selecting items could request item data. Repeated item-data completions could therefore cause additional full-list rebuilds. The first-open double refresh is proven by source; a high-frequency event loop during the player's report is not proven by the screenshots.

### Diagnostic distinction

The 0.2.0 implementation removes name API calls and item-data requests from the catalogue/list path, removes the main UI's item-data event-driven full refresh, and records bounded index row count and elapsed build duration. In a client retest:
- if stalls disappear, the source-supported synchronous list work was a material cause;
- if stalls continue while the Market is closed or while its incremental index is paused, an external addon/client interaction remains a competing explanation;
- the visible status timing gives a bounded measurement of Market's own catalogue preparation, but does not measure total game frame time.

No source-only or offline test can establish actual Forever frame-time acceptance.

## 4. Scope and ownership

### Player problem and result
Make Market useful on large saved datasets without locking the client, remove duplicate-looking variant rows, and provide at-a-glance trading context.

### Ownership
- `ModuloMarket` owns the UI, grouped item catalogue, cost scenarios, profitability ranking, low-supply view and compact market history.
- Parent `Modulo` 1.0.48 is unchanged.
- Auctionator remains the specialist auction-economy addon; ProfessionMaster remains the profession-management specialist.
- Market does not depend on either addon and does not read their SavedVariables/private APIs.
- Profession recipe/material data integration is not implemented. The cost field accepts a player-entered total purchase or crafting/material cost per unit; it does not infer recipes or import ProfessionMaster state.

### Dependencies and compatibility
- Uses the existing 0.1.0 SavedVariables and Auction House APIs.
- Legacy `costBasisByItemKey` values are migrated to `costBasisByItemID` when the corresponding cheapest variant is selected and no item-ID cost exists.
- No new addon dependencies, protected Auction House transaction APIs, purchase/post/cancel actions or external addon calls were added.
- Parent dependency direction remains `ModuloMarket -> Modulo`, never the reverse.

## 5. 0.2.0 changes

### 5.1 Responsive catalogue construction

Replaced synchronous `RefreshList()` with:
- `StartCatalog(snapshot)` — creates an empty build state and returns without traversing all rows;
- `StepCatalog()` — processes at most 250 source rows per UI frame;
- `StartViewBuild()` / `StepView()` — processes search and tab filters in batches of at most 250 items per frame;
- a snapshot identity cache — reopening the same snapshot reuses the completed in-memory catalogue;
- a UI-owned `OnUpdate` driver — preparation pauses while the Market frame is hidden;
- status output showing indexed source-row count, unique item count and elapsed index duration.

The main window is no longer refreshed once in `CreateUI()` and then a second time on `OnShow`. `CreateUI()` constructs controls; the first visible `OnShow` begins data preparation.

### 5.2 No item-data API work in the list path

The catalogue builder and renderer use only the saved row names/item IDs. They do not call `C_Item.GetItemNameByID` or `RequestLoadItemDataByID` for every row and the main Market UI no longer listens for item-data events to rebuild the full list.

Unknown item names are displayed as `Item #<id>` rather than triggering thousands of cache requests. The existing snapshot remains authoritative; no guessed name is written into SavedVariables.

### 5.3 One row per item ID

The stored snapshot remains variant-aware. The UI builds a separate item-ID-level presentation aggregate:
- lowest positive unit buyout across all saved variants;
- sum of quantities at that lowest price when the source provides depth;
- total listed quantity across every saved variant, including no-buyout rows;
- auction count only when the source actually provides it;
- variant count and the underlying cheapest variant reference.

For Browse snapshots, lowest-price depth and auction count are not exposed by the saved Browse row schema; the UI displays `—` / “listing count unavailable” rather than inventing those facts. Replicate rows provide depth/auction counts and can populate them. The presentation grouping does not alter the underlying saved variant records.

No full catalogue sort is performed. The first-seen item order is preserved: Browse source order and the Replicate snapshot's existing committed order.

### 5.4 Virtualized list and Blizzard-native controls

- Reuses 18 visible row buttons rather than creating a frame for each item.
- Only visible rows are updated during scroll/render.
- Uses `BasicFrameTemplateWithInset`, `UIPanelButtonTemplate`, `InputBoxTemplate` and standard Blizzard font objects.
- Removes the crowded long warning paragraph and overlapping labels from the old layout.
- The Market's Browse scan button hides the Market before opening the separate scanner, avoiding the overlapping two-window state shown in the player's screenshot.
- Separates the All items, Profitable, Low supply and Price history views.
- Restores explicit Confirm full scan and Cancel controls for the Replicate safety gate.

### 5.5 Profitability and scenarios

- `costBasisByItemID` stores manually entered unit cost in copper.
- Profitable tab includes only items with a known cost and positive profit at the current cheapest ask.
- Ranking is descending estimated profit per unit; the merge-sort work is bounded to 500 output operations per frame, avoiding a large synchronous sort.
- Low supply tab uses `lowSupplyThreshold`, default 5 combined listed units.
- The selected item supports current-lowest-ask and optional custom target-price scenarios.
- Both scenarios apply the configured AH cut and show net proceeds/profit; break-even and margin remain visible.

These are estimates, not sale predictions. Deposits, unsold inventory, undercuts, sale probability and unentered costs are excluded.

### 5.6 Historical prices

Each successfully completed full Replicate scan appends one compact history point keyed by item ID, with timestamp, cheapest unit price and combined total quantity. The latest four completed full-scan points are retained. Incomplete scans do not append history or replace the last-known-good Market snapshot.

Browse snapshots are not silently mixed into Replicate history. The first historical comparison becomes available after a successful full Replicate scan in 0.2.0.

## 6. Tests and current acceptance evidence

### Offline tests
- `python -m pytest -q tests` — **62 passed**.
- Lua syntax checks for Core, Scanner, Replicate, MarketUI and Diagnostics.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**, including item-ID-level historical price and quantity capture.
- `texlua tests/market_ui_0_2_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**; 16,574 synthetic source rows, grouped into 4,002 item IDs and processed over 84 simulated UI frames, plus search, detail, scenarios, history, opportunity ranking and low-supply filtering.
- New `market_ui_0_2_0_harness.lua`:
  - loads a 16,574-row synthetic snapshot;
  - proves opening does not synchronously traverse the snapshot;
  - proves catalogue and filter work completes over multiple frames;
  - proves grouping by item ID and lowest-price depth/total quantity aggregation;
  - verifies search, item selection, current profit, target scenario, history display, profitability ranking and low-supply filter.
- New static tests enforce bounded processing, no name API calls in render, one-row-per-item grouping, history cap, explicit scan confirmation and complete manifest inventory.
- Fresh extraction, archive CRC, manifest inventory and version agreement are checked in the package handoff.

Offline harness evidence is not a Forever runtime pass.

### Forever runtime
- 0.1.0 hang: FOREVER OBSERVED player report; root cause strongest source hypothesis, not a measured profiler diagnosis.
- 0.2.0 responsiveness: NOT RUN.
- 0.2.0 visual/layout acceptance: NOT RUN.
- Full Replicate traversal: NOT RUN on Forever.
- Full-client restart persistence of `marketHistory` and new cost basis: NOT RUN.

## 7. Player acceptance plan

### A. UI responsiveness — do this first; no Replicate request
1. Install Market 0.2.0 over the existing Market addon, with MODULO 1.0.48 unchanged.
2. `/reload`, open the Auction House, type `/mm`.
3. The window should appear promptly and show “Preparing market index…” progress rather than freezing.
4. Wait for the status to report the unique item count and index duration.
5. Confirm one row per item ID; repeated same-name variant rows should collapse.
6. Check that cheapest price, cheapest-price quantity (where known), and total quantity are correct for a few familiar items.
7. Search, scroll, change tabs, select an item, enter a cost and compare a target price.
8. Close and reopen `/mm`; the already-built catalogue should be reused without a second index pass.
9. If the game still hangs, capture the final status line and whether the hang continues while the Market is closed. Do not run a Replicate scan yet.

### B. Full-market history and Replicate — only after UI passes
1. Wait at least 15 minutes since any addon's last Replicate scan.
2. Ensure no other AH scan is running and no item is staged in Sell.
3. `/mm` → Update full market → Confirm full scan.
4. Keep the Auction House open and avoid other Browse/Sell/scan activity.
5. Capture completion status/errors and provide `ModuloMarket.lua` after SavedVariables flush.
6. Confirm `marketHistory` appends only on complete scan, keeps at most four points, and survives full client restart.
7. Compare item-ID group cheapest price/total quantity with the source variant rows and an independent Browse snapshot where comparable.

## 8. Exit state

0.2.0 is a source implementation of the responsive grouped Market experience and additional trading-analysis views. It directly removes the source-identified repeated synchronous 16,574-row list rebuild path and the per-row item-name API behavior. It is **not** yet proof that the user's reported Forever game hangs are fixed.

**FOREVER OBSERVED:** 0.1.0 UI rendered and the player reported repeated whole-game stalls on a 16,574-row snapshot.  
**SOURCE IMPLEMENTED:** incremental catalogue/filter, grouped item-ID list, 18-row virtualization, native Blizzard templates, opportunity/low-supply tabs, target scenarios and four-point Replicate history.  
**NOT RUN / UNKNOWN:** actual Forever 0.2.0 responsiveness, visual acceptance, external-addon contribution to stalls, full Replicate traversal, and full restart persistence.
