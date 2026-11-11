# Modulo Market Runtime Audit 0.0.5 — Auction House Sell-tab safety gate

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.5  
**Package:** standalone ZIP; not part of MODULO 1.0.48.

## Player problem and observable result

The first live full-house scan must not compete with an Auction House Sell operation. The 0.0.4 scanner already waited for throttle readiness and a two-second quiet interval, but it did not independently detect a staged Sell-tab item. This slice makes that condition a hard, fail-closed gate: Market refuses to start, or aborts before requesting another page, when the Auction House reports an active listing state with an item staged in ItemSellFrame or CommoditiesSellFrame.

## Direction and ownership

- **Owner:** separate optional companion addon `ModuloMarket`.
- **Parent:** `Modulo`; MODULO never depends on Market.
- **Specialist boundary:** Auctionator remains responsible for economy mutation workflows. Market is read-only observation.
- **MODULO source:** unchanged at 1.0.48.
- **Market persistence:** still deferred.

## Evidence

### Supporting evidence

- The supplied 0.0.4 source already implements the empty browse query, paginated results, throttle readiness and two-second quiet interval.
- Forever API research records that whole-house browse scans use the empty `SendBrowseQuery` path and that paging shares the Auction House throttle. It also records a reported failure mode where back-to-back paging left the Sell tab empty/broken, and describes a cautious implementation that avoids paging while `ItemSellFrame` or `CommoditiesSellFrame` holds an item. citeturn690387search4
- Blizzard Auction House UI source exposes `AuctionHouseFrame:GetDisplayMode()`, `IsListingAuctions()`, and the Sell-frame `GetItem()` checks used to identify an active post item. citeturn690387search0turn690387search3

### Counter-evidence / limits

- These sources do not prove the exact behavior of the user's live Forever 1.60.1 build 70862.
- The scanner still cannot see another addon's private queued request. The first runtime test must therefore remain isolated.
- API presence and source compatibility are not runtime acceptance.

## Implementation

`Scanner.lua` now adds:

1. `HasActiveSellItem()` — checks `AuctionHouseFrame:IsListingAuctions()` when available and inspects `ItemSellFrame:GetItem()` / `CommoditiesSellFrame:GetItem()`; if the client reports listing mode but the child accessors cannot be inspected, it fails closed.
2. `CanScanSafely()` — returns a safety result rather than guessing.
3. Start gate — `/mm` cannot initiate a scan while a Sell-tab item is staged.
4. Page gate — a scan aborts before sending another page if the player stages a Sell-tab item during the scan.

No buy, bid, post, cancel, craft, Auctionator database or Auctionator private queue APIs were added.

## Tests and package validation

- Focused/static test suite: `python -m pytest -q tests` — **8 passed** after the new test was added.
- Lua syntax: `texluac -p` on all Market Lua files — **PASS**.
- Scanner model harness: `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- ZIP integrity: **PASS**.
- Fresh extraction: **PASS**.

## Runtime status

- Forever 1.60.1 build 70862 complete full-house scan: **NOT RUN**.
- Forever Sell-tab safety gate: **NOT RUN**.
- Result-page event sequence: **NOT RUN**.
- Sell-tab recovery/posting regression after scan: **NOT RUN**.
- Retail: **NOT RUN**.

Therefore Market remains **UNKNOWN / NOT RUN** for live scan behavior and is not Forever runtime verified.

## Next acceptance gate

On the target client:

1. Install Market 0.0.5 beside MODULO 1.0.48.
2. Open Auction House with no Sell item staged and no other Auction House activity.
3. Start one full snapshot.
4. Record whether the initial query is accepted, whether result pages arrive, page count increases, and whether `HasFullBrowseResults()` completes.
5. Do not browse/buy/sell/post during the scan.
6. After completion, test Sell tab and normal posting/selling behavior.
7. If the scan fails, capture Market diagnostics and BugGrabber/BugSack output before changing code.

Persistence and profitability remain blocked until this live gate passes.

## Package record

- Version: **0.0.5**
- Files: 12
- Standalone child ZIP; MODULO core remains 1.0.48.
- Runtime status: NOT RUN / UNKNOWN.
