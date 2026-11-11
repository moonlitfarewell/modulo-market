# Modulo Market Runtime Audit 0.0.10 — one-shot Replicate API diagnostic probe

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.10  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release type:** standalone optional child addon; experimental diagnostic only.

## Player problem and observable result

The 0.0.9 browse scanner completed a full snapshot of 16,574 variants across 34 pages in 21.1 seconds, with 16.8 seconds measured while `IsThrottledMessageSystemReady()` returned false. The player approved investigating one controlled `C_AuctionHouse.ReplicateItems()` request as a possible route to a substantially faster full-house scan.

This slice adds a two-step, explicit in-game diagnostic probe. It does not replace the working browse scanner and does not attempt a full replicate scan.

## Before implementation: decision gate

### Player problem and observable result

Determine whether the Forever client returns a credible initial Replicate list response, how many auction records it reports, how long the initial response takes, and whether a tiny sample of records exposes the expected return shape.

### Exact supporting evidence

- User screenshot of 0.0.9: 16,574 variants, 34 pages, 21.1 seconds elapsed, 16.8 seconds throttle wait.
- Supplied Auctionator source contains a distinct `Source_ModernAH/FullScan/Mixins/Frame.lua` implementation using `C_AuctionHouse.ReplicateItems()`, `REPLICATE_ITEM_LIST_UPDATE`, `GetNumReplicateItems()`, `GetReplicateItemInfo()`, `GetReplicateItemLink()` and `GetReplicateItemTimeLeft()`.
- That source reads the 17th and 18th return values from `GetReplicateItemInfo()` as item ID and `hasAllInfo`.
- Supplied Forever API research documents the functions for Forever 1.60.1 but does not demonstrate a completed Replicate scan on the player's build.

### Counter-evidence and uncertainty

- API presence does not prove successful response or safe operation on build 70862.
- Historical documentation reports a 15-minute account-wide cooldown and disconnect risk on very busy Auction Houses.
- Replicate records are auction-level and not equivalent to the browse API's summarized `minPrice` and `totalQuantity`.
- The live auction count and whether it exceeds the historical risk range are unknown.
- The exact timing/semantics of later item-data update events on this target client remain unknown.

### Ownership and dependencies

- Owner: separate optional addon `ModuloMarket`.
- Parent: MODULO 1.0.48; dependency remains one-way from Market to MODULO.
- Auctionator source is a behavioral reference only; no Auctionator dependency or private queue/database access.
- MODULO source and version remain unchanged.
- No specialist ownership is displaced; Market remains read-only observation.

### Scope, risks and limits

- One API request at most per loaded client session.
- A persisted attempt timestamp enforces a 15-minute cooldown across normal reloads/logins when SavedVariables are flushed.
- The probe warns the player before a separate confirmation click.
- The probe does not read the full list, load item data, aggregate prices, create a snapshot, or replace the last-known-good snapshot.
- A 90-second timeout consumes the attempt; no retry is automatic or permitted in that session.
- `REPLICATE_ITEM_LIST_UPDATE` is a shared event. If another addon has an outstanding Replicate request, the event cannot be attributed conclusively to Market. The probe must be run with no other Auction House activity.
- If WoW crashes before SavedVariables are flushed, the persisted cooldown timestamp may not reach disk. The in-session one-shot guard remains effective only while the addon remains loaded. The client/server cooldown is not bypassed.

## Implementation

### UI

- Added **Prepare Replicate Probe**.
- Preparation displays the cooldown/disconnect warning and reveals **Confirm & Send One Request**.
- No Replicate API is called during addon load, scanner window open, or preparation.
- The probe is blocked while a browse scan is active, the Auction House is closed, required APIs are missing, a Sell item is staged, the session has already attempted a probe, or the saved 15-minute cooldown is active.

### Request and response behavior

- On confirmation, consumes the session attempt before calling the API.
- Stores `ModuloMarketDB.replicateProbeAttemptAt` before calling `ReplicateItems()`.
- Calls `C_AuctionHouse.ReplicateItems()` exactly once.
- Waits for the first `REPLICATE_ITEM_LIST_UPDATE`, with a 90-second timeout.
- Reads `GetNumReplicateItems()` once.
- Samples at most zero-based indices 0, floor((count-1)/2), and count-1.
- For each sample, records the item ID and `hasAllInfo` fields from the 17th/18th return values, item link, and time-left value where available.
- Records `completeScan=false`.
- Does not call `GetItemInfo`, `RequestLoadItemDataByID`, or iterate the full auction list.
- Does not assign to `ModuloMarketDB.lastSnapshot`.

### Competing hypotheses and diagnostic

1. **Replicate initial response is usable on the target client.** Distinguished by receiving `REPLICATE_ITEM_LIST_UPDATE`, a numeric auction count, and sample records without API errors.
2. **Replicate API is present but unusable/incompatible on the target build or current Auction House state.** Distinguished by no event within 90 seconds, an API exception, invalid count, or sample accessor failures.

The diagnostic deliberately does not infer full-scan feasibility from a successful initial response. A separate bounded aggregation experiment would be needed after reviewing the probe result.

## Tests and validation

- Python static/regression tests: to be recorded by build command.
- Existing Market test suite: to be recorded by build command.
- Lua syntax: to be recorded by `texluac -p`.
- Existing browse scanner model harness: to be recorded by `texlua`.
- New Replicate probe model harness: to be recorded by `texlua`.
- ZIP integrity, fresh extraction, manifest/TOC agreement and SHA-256: to be recorded by build command.
- Forever runtime probe: **NOT RUN** (requires player to install 0.0.10 and explicitly confirm in-game).
- Replicate completion, full aggregation, price equivalence, Sell-tab recovery and performance: **NOT RUN / UNKNOWN**.
- Retail runtime: **NOT RUN**.

## Player acceptance / exit criteria

1. Install Market 0.0.10 beside MODULO 1.0.48.
2. Open the Auction House with no other browse, buy, sell, post, or other addon scan activity.
3. Open `/mm`; confirm the normal browse snapshot and previously saved snapshot are still present.
4. Click **Prepare Replicate Probe**; verify the warning appears and no request is sent.
5. If willing to accept the stated cooldown/disconnect risk, click **Confirm & Send One Request** exactly once.
6. Record whether the response event arrives within 90 seconds, reported auction count, response time, and the at-most-three sample records' item ID/hasAllInfo/link availability.
7. Confirm the previous `lastSnapshot` remains unchanged.
8. Do not retry, even if the request times out or errors. Respect the 15-minute account-wide cooldown.
9. Verify normal Auction House browsing and Sell-tab behavior after the diagnostic.

A successful probe is **FOREVER OBSERVED** only for the exact response facts actually observed. Event attribution remains uncertain if any other addon had a Replicate request outstanding. It does not make the full Replicate scan FOREVER VERIFIED.

## Package record

- Addon version: 0.0.10.
- Parent MODULO version: 1.0.48, unchanged.
- Package: standalone optional child addon ZIP.
- Full test/package results and SHA-256: recorded in the accompanying build handoff.
