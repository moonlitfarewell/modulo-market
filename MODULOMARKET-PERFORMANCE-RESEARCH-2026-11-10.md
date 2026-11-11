# Modulo Market Performance Research — 2026-11-10

**Reviewed addon:** Modulo Market 0.0.9  
**Parent:** MODULO 1.0.48 (unchanged)  
**Scope:** source/API research only; no addon source changes and no live API calls made.

## Executive finding

The 0.0.9 scan is already sending each browse-page request only after `C_AuctionHouse.IsThrottledMessageSystemReady()` reports ready. The supplied live run completed 16,574 item variants across 34 pages in 21.1 seconds, with 16.8 seconds (79.6%) measured while that readiness API reported not-ready.

The 50% target (about 10.55 seconds for a comparable scan) cannot be reached by optimizing Lua processing alone. The current client readiness gate accounts for more than the entire target duration. Research found:

1. The browse-pagination API exposes no page-size/batch-size argument to increase rows per page.
2. Auctionator's incremental scanner uses the same empty browse query and the same `RequestMoreBrowseResults()` page-by-page pattern. Its FIFO queue reacts to throttle-ready events rather than polling, but it does not bypass the throttle. Porting that event-driven pattern could remove a small per-page polling delay, not the 16.8 seconds spent throttle-blocked.
3. `C_AuctionHouse.ReplicateItems()` is a materially different bulk path that requests all auctions at once. It is documented for Forever 1.60.1, and Auctionator contains a separate full-scan implementation using it. However, Forever-specific research says its presence is known but a completed Replicate scan has not been demonstrated on Forever. It has a 15-minute account-wide cooldown and documented historical disconnect/performance risks on very busy Auction Houses. This is the only plausible route to a major speed improvement, but it must be tested separately and cautiously.

**Recommendation:** keep the proven 0.0.9 summary scanner intact. Do not weaken or bypass the readiness gate. The next meaningful experiment is a one-shot, player-confirmed Replicate API probe, not a replacement of the production scanner.

## Player problem and observed result

The player wants a full-house market snapshot in at least 50% less time than the existing scan, without dropped pages, Sell-tab interference, or loss of the persistent last-known-good snapshot.

### Exact live evidence supplied

- Build: Modulo Market 0.0.9.
- Completed snapshot: 16,574 item variants.
- Pages: 34.
- Total elapsed: 21.1 seconds.
- Time measured with `IsThrottledMessageSystemReady() == false`: 16.8 seconds.
- Remaining time: approximately 4.3 seconds (20.4%).
- Throttle-wait share: approximately 79.6%.
- The player screenshot shows the complete-snapshot-saved status.

This is one live run, not a statistically controlled before/after benchmark. It proves the scan completed and provides a useful first timing baseline. It does not prove Sell-tab behavior during or after the scan, or a 50% speed improvement.

## Current Market 0.0.9 implementation

Source reviewed: `AddOns/ModuloMarket/Scanner.lua`.

- Initial request: `C_AuctionHouse.SendBrowseQuery({ searchString = "", sorts = {}, filters = {}, itemClassFilters = {} })`.
- Subsequent request: `C_AuctionHouse.RequestMoreBrowseResults()` with no arguments.
- Result handling: `AUCTION_HOUSE_BROWSE_RESULTS_UPDATED` and `AUCTION_HOUSE_BROWSE_RESULTS_ADDED`.
- Completion: `C_AuctionHouse.HasFullBrowseResults()`.
- Safety gate: `C_AuctionHouse.IsThrottledMessageSystemReady()` must return true before each request.
- Scheduler: an `OnUpdate` driver polls the readiness API while a page is due.
- No fixed extra quiet interval remains in 0.0.9.
- Snapshot persistence remains last-known-good: only a completed scan replaces `ModuloMarketDB.lastSnapshot`; start/abort does not overwrite it.
- Sell-tab checks and page/result/time limits remain in place.

`IsThrottledMessageSystemReady()` is documented as returning whether the next query will be throttled, delayed, or cancelled. It is a readiness gate, not a control for changing the server's throttle rate.

## Avenue 1 — request larger browse batches

### Finding: no supported page-size control found

The documented `RequestMoreBrowseResults()` API has no arguments. `GetBrowseResults()` returns the currently loaded summary result array, whose records contain an item key, total quantity and minimum price. The documented browse query structure has search/sort/filter fields but no page-size or result-limit field.

Auctionator's Forever-compatible incremental scan also requests the next page once per results event; its wrapper calls `C_AuctionHouse.RequestMoreBrowseResults()` without page-size arguments.

### Conclusion

There is no evidence-backed way to ask the browse-summary API for two or more pages in one request. Do not invent undocumented query fields or issue parallel page requests. Parallel calls would also conflict with the shared Auction House throttle.

**Status:** no larger-batch implementation recommended.

## Avenue 2 — mirror Auctionator's throttle queue/events

### Local Auctionator source inspected

From the supplied `AddOns.zip`:

- `AddOns/Auctionator/Source/AH/Mixins/Queue.lua`
- `AddOns/Auctionator/Source_ModernAH/AH/Mixins/Throttling.lua`
- `AddOns/Auctionator/Source_ModernAH/AH/Wrappers.lua`
- `AddOns/Auctionator/Source_ModernAH/IncrementalScan/Mixins/Frame.lua`

Auctionator's queue:

- Appends a request to a FIFO queue.
- Dequeues immediately if `C_AuctionHouse.IsThrottledMessageSystemReady()` is true.
- Otherwise waits for its throttle component to detect a transition back to ready.
- The throttle component listens for `AUCTION_HOUSE_THROTTLED_SYSTEM_READY`, queued/sent/response/dropped events, checks `IsThrottledMessageSystemReady()`, and emits a queue-ready event when readiness changes to true.
- Its incremental scanner uses the same empty browse query and calls `RequestMoreBrowseResults()` after each result event until `HasFullBrowseResults()`.

### Comparison with Market

Market already enforces the same readiness boolean before each request, so it is not bypassing the throttle. The difference is scheduling: Market polls readiness on `OnUpdate`, while Auctionator reacts to throttle state-change events and serializes its own Auctionator requests.

An event-driven Market scheduler could avoid waiting until the next frame to notice readiness. At 60 FPS, the theoretical polling-detection delay is less than one frame per page (about 0.57 seconds across 34 page transitions, before other scheduling effects). That is only a small fraction of the measured 21.1-second scan and cannot explain or remove the 16.8 seconds where the client says the throttle is not ready.

Auctionator's queue is private and must not become a Market dependency. A Market-owned event-driven scheduler could be implemented without calling Auctionator.

### Conclusion

A local event-driven scheduler is a reasonable robustness/cleanliness improvement, but it is not the 50% performance solution. It should not be presented as one.

**Status:** optional minor optimization; not implemented in this research pass.

## Avenue 3 — `C_AuctionHouse.ReplicateItems()` bulk path

### API evidence

The current API reference lists `C_AuctionHouse.ReplicateItems`, `GetNumReplicateItems`, `GetReplicateItemInfo`, `GetReplicateItemLink`, and `GetReplicateItemTimeLeft` for Forever 1.60.1. The API is distinct from browse-summary pagination: `ReplicateItems()` requests all current auctions, and the count/info functions expose individual auction records.

The Forever API research document (`ForeverPlusPlus/docs/forever-api.md`, latest search result dated last month) records these functions in the Forever client API and says the functions were present in the build 70009 executable. It explicitly says no one had demonstrated a completed Replicate scan on Forever; Auctionator's replicate scan was off by default in that research. API presence is not proof of working runtime behavior on the player's build 70862.

### Auctionator implementation inspected

The supplied Auctionator source has a separate `Source_ModernAH/FullScan/Mixins/Frame.lua` path:

- Calls `C_AuctionHouse.ReplicateItems()`.
- Waits for `REPLICATE_ITEM_LIST_UPDATE`.
- Reads `C_AuctionHouse.GetNumReplicateItems()`.
- Iterates auction records with `GetReplicateItemInfo`, `GetReplicateItemLink`, and `GetReplicateItemTimeLeft`.
- Processes records in bounded batches (250 records per step, then a short timer yield).
- Loads missing item data asynchronously.
- Aggregates individual auction rows into item database keys.

This is materially different from the incremental summary scan used by Auctionator's other scanner. It is not simply a faster call to `RequestMoreBrowseResults()`.

### Important constraints and risks

The API reference documents:

- A 15-minute account-wide cooldown between successful `ReplicateItems()` calls.
- `REPLICATE_ITEM_LIST_UPDATE` on the initial list response, and further events as item details are cached after `GetReplicateItemInfo()` calls.
- Historical disconnects on busy Auction Houses above roughly 80,000 auctions; a hotfix removed seller names from most results, but the reference still records the historical failure.
- A reported limit of roughly 2,000 item-info update events per frame, with excessive reads potentially being ignored or slowing the client.

`GetReplicateItemInfo()` returns auction-level data (including stack count and total buyout) plus a `hasAllInfo` flag. Some item information may not be ready immediately. A correct Market adapter would need to:
- Wait for the initial replicate response.
- Read each auction safely in bounded batches.
- Handle `hasAllInfo == false` and asynchronous item data.
- Derive item variants from the returned item link/key.
- Aggregate minimum unit buyout and available quantity consistently.
- Exclude or explicitly classify auctions without a usable buyout.
- Enforce the account-wide cooldown and prevent repeat attempts.
- Abort safely if the Auction House closes or the API fails.

A raw replicate result is not automatically equivalent to Market's current summary snapshot. The current summary contains one row per browse item variant with server-reported `minPrice` and `totalQuantity`; replicate data contains individual auction listings that must be aggregated. We must validate the aggregation against a normal summary scan before replacing the current path.

### Conclusion

This is the only researched path with a plausible chance of substantially reducing elapsed time, because it uses one bulk request instead of 34 throttled browse-page requests. But it has a 15-minute account-wide cooldown and meaningful compatibility/stability risk. No speed result is guaranteed.

**Status:** API documented for Forever 1.60.1; completion and behavior on Forever build 70862 UNKNOWN / NOT RUN. Do not call it automatically or as part of every Market scan.

## Ownership and dependencies

- Market remains a separate optional addon depending on MODULO.
- MODULO must not depend on Market.
- Market must not depend on Auctionator or call Auctionator's private queue/database.
- Auctionator source is a behavioral reference only.
- No MODULO 1.0.48 files are changed.

## Recommendation and next action

Keep the existing 0.0.9 summary scanner as the safe baseline.

Before implementing a Replicate-based production scanner, perform a one-shot, explicit player-confirmed diagnostic probe that:
1. Warns about the 15-minute account-wide cooldown and possible disconnect risk on a very busy Auction House.
2. Calls `ReplicateItems()` at most once per attempt.
3. Waits for the initial `REPLICATE_ITEM_LIST_UPDATE`.
4. Records `GetNumReplicateItems()` and elapsed response time.
5. Optionally reads only a tiny bounded sample (first, middle and last record) to verify return shape and `hasAllInfo`, without walking the full list.
6. Does not persist data or replace `lastSnapshot`.
7. Has a hard no-retry rule for that session and preserves the existing scanner unchanged.

If the initial request does not return a credible list, do not retry within the cooldown. If it succeeds, separately design and validate a complete aggregation prototype, then compare it with the 0.9 summary snapshot.

## Risks, tests and acceptance

### Evidence available

- 0.9 complete summary scan: **FOREVER OBSERVED**, 16,574 variants / 34 pages / 21.1s / 16.8s throttle wait (user screenshot).
- 0.7 SavedVariables restore and last-known-good behavior across `/reload`: **FOREVER OBSERVED** (user screenshots).
- 0.9 scanner source and supplied Auctionator source reviewed.
- Forever API reference lists Replicate functions for Forever 1.60.1.

### Not established

- ReplicateItems successful completion on Forever build 70862: **NOT RUN / UNKNOWN**.
- Actual replicate auction count on the user's realm: **UNKNOWN**.
- Whether auction count exceeds the historical 80k risk threshold: **UNKNOWN**.
- Replicate response time on Forever: **NOT RUN**.
- Sell-tab safety after ReplicateItems: **NOT RUN**.
- Full aggregation equivalence to summary browse: **NOT RUN**.
- Full client restart persistence: **NOT RUN**.
- 50% performance target: **NOT ACHIEVED / UNKNOWN for alternate path**.

### Acceptance for any future replicate experiment

1. Player explicitly confirms the one-off diagnostic after seeing the cooldown/disconnect warning.
2. Only one `ReplicateItems()` call is made.
3. The initial response arrives within a bounded timeout.
4. The returned auction count is recorded; no unbounded full-list processing is performed during the probe.
5. The old saved snapshot remains unchanged.
6. Normal browse scanning and Sell-tab functions remain usable afterwards.
7. Any failure is captured before any retry or code change.

**Decision:** no change to production scan strategy in this research pass. Preserve 0.0.9. The Replicate path is a promising but risky experimental avenue requiring explicit runtime validation.
