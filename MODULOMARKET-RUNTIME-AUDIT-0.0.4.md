# Modulo Market Runtime Audit 0.0.5 — first Auction House snapshot slice

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.5  
**Package:** standalone ZIP; not part of MODULO 1.0.48.

## Player problem and observable result

The player needs a reliable, timestamped view of current Auction House commodity/item summary prices as the foundation for market analysis. This slice adds a player-accessible full-house snapshot: open the Auction House, run `/mm`, start a scan, then inspect/export the completed in-memory scan as JSON.

## Direction and ownership

- **Adopted owner:** separate optional addon `ModuloMarket`, not an internal MODULO module.
- **Parent relationship:** TOC Category `Modulo By Wells`, Group `Modulo`, dependency `Modulo`; MODULO never depends on Market.
- **Specialist boundary:** Auctionator owns economy workflows (search/buy/sell/post/cancel). Market is read-only observation and analysis; it does not call those mutation APIs or depend on Auctionator. ProfessionMaster retains profession management.
- **Changed files:** `AddOns/ModuloMarket/ModuloMarket.toc`, `Core.lua`, new `Scanner.lua`, `README.md`, `MANIFEST.json`, focused tests and this audit. MODULO 1.0.48 is unchanged.

## Evidence and counter-evidence

### Supporting evidence

- User directly checked on Forever `1.60.1 Build 70862 Date Nov 6 2026 Interface 16001` that `C_AuctionHouse.SendBrowseQuery`, `RequestMoreBrowseResults`, `GetBrowseResults`, `HasFullBrowseResults`, and `IsThrottledMessageSystemReady` are functions.
- Supplied Forever Auctionator source `AddOns/Auctionator/Source_ModernAH/IncrementalScan/Mixins/Frame.lua` uses an empty browse query (`searchString=""`, empty `sorts`, `filters`, `itemClassFilters`), reads `GetBrowseResults()` on `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED`, consumes `AUCTION_HOUSE_BROWSE_RESULTS_ADDED`, and calls `RequestMoreBrowseResults()` until `HasFullBrowseResults()`.
- Supplied Forever Auctionator `AH/Wrappers.lua` queues browse and page requests; `AH/Mixins/Throttling.lua` uses `IsThrottledMessageSystemReady()` and throttle events.
- `xIGBClutchIx/ForeverPlusPlus` `docs/forever-api.md` records a Forever-specific report that back-to-back full-house pagination without waiting for throttle readiness left the Sell tab empty and posting broken. It describes a two-second quiet delay after Blizzard AH queries as the cautious mitigation used by that addon, but notes the fix is not verified. This is a third-party report, not Market runtime evidence.

### Counter-evidence / unresolved risks

- API presence does not prove request acceptance, event order, complete pagination, result schema, or persistence on the current live build.
- Auctionator's queue is private and Market does not share it. The two-second throttle-ready/quiet gate reduces request frequency but cannot guarantee serialization against Auctionator or other addons.
- A browse query occupies the shared Browse results channel and may replace the player's current Browse results. The UI warns not to browse/buy/sell/post while scanning.
- The current scanner does not know whether another addon has an active queued request. First runtime acceptance must be isolated: no other AH activity or concurrent scan.
- Browse result summaries expose `itemKey.itemID`, `minPrice`, and `totalQuantity` in Auctionator's scan path. Item-name resolution and detailed auction-level rows are not yet implemented.
- Result deduplication uses item ID, item level, suffix, pet species, bonus lists and modifiers as exposed by the item key; any omitted key dimensions could merge variants.
- No runtime evidence currently establishes that the page events deliver each page exactly once or that the 2-second pacing prevents Sell-tab disruption.

## Implementation

- `/mm` opens the scanner UI; `/mmdebug` retains the read-only profession/API diagnostics.
- Full scan starts only while `AuctionHouseFrame:IsShown()` and the required APIs are present.
- Initial request is the documented empty browse query.
- Subsequent pages are requested only after `IsThrottledMessageSystemReady()` returns true and at least two seconds have elapsed since the last throttle/result activity.
- Event handlers consume initial updated results and subsequent added results; `HasFullBrowseResults()` is the only completion signal.
- Bounded stops: 15-minute timeout, 500 pages, 25,000 unique result rows, browse failure, dropped throttle message, or Auction House close.
- Stop/abort discards partial rows and does not overwrite the last completed in-memory scan. A request already sent cannot be cancelled.
- In-memory completed scan fields: schema version, completeness, Unix and display timestamps, client/build/interface, source, copper price unit, page/result counts and numeric row data. SavedVariables persistence/history is intentionally deferred until the first complete client scan and Sell-tab safety acceptance pass.
- Export JSON contains only numeric item/price/quantity fields and explicit copper units.

## Security, compatibility and performance

- No buying, bidding, selling, posting, cancelling, crafting, or profession mutation.
- No Auctionator dependency or calls into its private queue/database.
- No background autoscan; the player explicitly starts it from the scanner UI.
- Per-frame driver work occurs only during an active scan and checks throttle state; no unbounded scan loop or immediate page burst.
- Forever API/event behavior and current build result shapes remain to be confirmed in the actual client.

## Persistence gate

The previous 0.0.3 audit explicitly required one controlled, complete Auction House browse query before implementing persistent snapshots. This 0.0.5 slice therefore **does not write scan data to SavedVariables**. A completed result is held in memory and can be exported as JSON. Only after the player confirms a complete scan and safe Sell-tab behavior should the next slice add timestamped persistent snapshot history.

## Tests and runtime evidence

- Focused static tests: `python -m pytest -q tests` — **8 passed** (grouping regression plus snapshot scanner tests).
- Lua syntax: `texluac -p` on `Core.lua`, `Scanner.lua`, and `Diagnostics.lua` — **PASS**.
- Scanner model harness: `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS** (initial request, paced next page, completion, in-memory result retention and JSON fields). This is a stubbed model, not client runtime evidence.
- ZIP integrity, inventory and fresh extraction: recorded below.
- Forever client 1.60.1 build 70862: API presence user-observed; Market full scan and player-visible acceptance **NOT RUN**.
- Retail runtime: NOT RUN.
- Sell-tab safety: NOT RUN.
- Profession profitability, disenchant expected value and Fishing commodity valuation: NOT IMPLEMENTED.

## Acceptance / exit criteria

1. Enable Market and open the Auction House.
2. Run `/mm`; scanner opens without Lua errors.
3. Start one full snapshot while no other AH activity or other addon scan is running.
4. Confirm scan completes, page count advances, and row count is plausible/non-zero.
5. Confirm the completed in-memory snapshot is marked complete and timestamped; export JSON parses and reports copper prices.
6. Confirm Sell tab still lists items and buying/selling/posting still works after the scan.
7. Run a second scan only after the first result is understood.

Until all client checks pass, scan behavior remains **UNKNOWN / NOT RUN**, and the capability must not be described as Forever runtime verified.

## Package record

- Version: 0.0.5
- Standalone child addon ZIP only; MODULO core bundle remains 1.0.48 and is not modified.
- ZIP integrity/CRC: PASS; exact inventory: 11 files; fresh extraction: PASS.
- Fresh-extraction full Market test set: 8 passed; Lua syntax: PASS; scanner model harness: PASS.
- Forever runtime: NOT RUN; Sell-tab safety: NOT RUN.
