# Modulo Market — Replicate Probe Runtime Observation

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.11  
**Scope:** one explicitly confirmed `C_AuctionHouse.ReplicateItems()` diagnostic request. No production scanner change.

## Result

**FOREVER OBSERVED — initial Replicate response only.**

The player supplied two screenshots:
1. Immediately after confirmation: “One ReplicateItems request sent. Waiting up to 90 seconds for REPLICATE_ITEM_LIST_UPDATE; no retry will occur.”
2. Completion: “Replicate probe response: 291276 auctions in 17.0s; sampled 3 records (3 report hasAllInfo=true). No snapshot data was read or saved. Attempt consumed; do not retry during cooldown.”

Observed facts:
- One request was sent after the separate confirmation action.
- `REPLICATE_ITEM_LIST_UPDATE` arrived and the probe completed.
- `GetNumReplicateItems()` returned **291,276**.
- Time from the probe's request timestamp to the response event was **17.0 seconds**.
- Three sample indices (first, middle and last) were inspected.
- All three sampled records returned `hasAllInfo == true`.
- The probe's status explicitly says no snapshot data was read or saved.
- The one-shot attempt was consumed; no retry was made.

The earlier supplied snapshot export recorded Forever client 1.60.1, build 70862, interface 16001. The result screenshot itself does not display build information, so the exact build association is based on the surrounding test session rather than metadata embedded in this screenshot.

## Interpretation

This is strong evidence that the initial `ReplicateItems()` request and the first result event work on the tested Forever client. It does **not** demonstrate that a full 291,276-record traversal, item-data completion, variant mapping, aggregation, or snapshot persistence works.

The result is approximately 3.64 times the historically cited 80,000-auction risk level. The client did not disconnect during this initial request, which is useful counter-evidence to the historical risk report, but one successful request does not establish that full-list processing is safe at this scale.

The 17.0 seconds is the initial replication response time only. It is not the time required to read, enrich, aggregate and persist all auction records.

## Source research relevant to the next stage

The supplied Auctionator source (`Source_ModernAH/FullScan/Mixins/Frame.lua`) uses this approach:
- Treat the first `REPLICATE_ITEM_LIST_UPDATE` as the initial list response.
- Read `GetNumReplicateItems()`.
- Process zero-based records in batches of 250, yielding with a short timer.
- Read `GetReplicateItemInfo`, `GetReplicateItemLink` and `GetReplicateItemTimeLeft`.
- For records with `hasAllInfo == false`, request item data and revisit the record after `ITEM_DATA_LOAD_RESULT`.
- Ignore records whose item IDs do not exist.
- Build its own item database keys from item links.
- Aggregate auction buyout and stack count into unit-price and available-quantity data.

The documented API confirms:
- `GetReplicateItemInfo(index)` uses zero-based indices from 0 to `GetNumReplicateItems()-1`; its 17th and 18th returns are `itemID` and `hasAllInfo`.
- `GetReplicateItemLink(index)` may return nil until item data is loaded.
- `REPLICATE_ITEM_LIST_UPDATE` also fires as item information is cached after calls to `GetReplicateItemInfo`.
- The API history records a hotfix that removed seller names from most replicated records after historical disconnect reports. It also records reports of excessive item-info reads causing event floods or slowdown.

References:
- https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.ReplicateItems
- https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.GetReplicateItemInfo
- https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.GetReplicateItemLink
- https://warcraft.wiki.gg/wiki/API_C_AuctionHouse.GetNumReplicateItems

## Critical data-model issue to resolve before implementation

Market's current browse snapshot rows contain `itemID`, `itemLevel`, `itemSuffix`, `minPriceCopper`, and `totalQuantity`; the browse identity helper also considers bonus lists and modifiers when present.

A Replicate row is an individual auction, not a browse-summary row. To reproduce the current summary snapshot correctly, the next implementation must establish a stable variant identity from the full item link and prove how that identity maps to the browse `itemKey`. It must not silently merge distinct variants by `itemID` alone.

Price and quantity aggregation must be explicitly validated:
- Stack count is `GetReplicateItemInfo` return 3.
- Total buyout is return 10.
- Candidate unit price is `ceil(buyoutPrice / count)` for positive count and positive buyout; bid-only or zero-buyout listings must be classified rather than silently treated as zero-priced.
- Candidate total quantity is the sum of stack counts, not the number of auction records.
- Candidate minimum unit price and total quantity must be compared against browse-summary results for matched variants.

The existing Market export currently omits bonus-list/modifier arrays from serialized rows even though its deduplication identity considers them. This is a separate schema-fidelity concern and must be resolved rather than copied into the Replicate path.

## Competing hypotheses for a full traversal

1. **The client can safely expose and process the entire 291,276-record cache in bounded batches.** Distinguish by processing a small bounded batch first, inspecting return shapes, link availability, `hasAllInfo`, and frame responsiveness; then scale only after the small batch passes.
2. **The initial list arrives, but large-scale record access or item-data enrichment causes event floods, stalls, nil links or incomplete records.** Distinguish through per-batch counters, error capture, pending-item counts, item-data timeouts and elapsed-time/frame-yield measurements.

A third correctness risk is that Replicate-derived variant keys or price/quantity aggregation may not match browse-summary results. Distinguish with side-by-side comparisons for a representative set of common and suffixed/equipment variants.

## Next action

Do not issue another Replicate request during the 15-minute account-wide cooldown.

Prepare a separate, opt-in, bounded processing prototype that:
1. Reuses the replicated cache only if it is still available; otherwise waits for the documented cooldown before a new explicitly confirmed request.
2. Reads a small initial batch (e.g. 250 records), never the entire list in one frame.
3. Captures sample return tuples, nil-link rate, `hasAllInfo` rate, item IDs, count, buyout, item links and processing time.
4. Uses no seller/bidder identity.
5. Does not change the saved browse snapshot.
6. Stops safely on Auction House close, Sell-tab activity, API error, or timeout.
7. Does not call `ReplicateItems()` automatically or retry.
8. Only after the bounded batch succeeds, designs a resumable full traversal with bounded item-data loading and a last-known-good commit.

Full traversal, aggregation, variant equivalence, saved-snapshot replacement, Sell-tab safety and performance remain **NOT RUN / UNKNOWN**.

## Acceptance state

| Capability | Evidence state |
|---|---|
| Explicit one-shot Replicate request | FOREVER OBSERVED |
| Initial `REPLICATE_ITEM_LIST_UPDATE` response | FOREVER OBSERVED |
| 291,276 reported auction records | FOREVER OBSERVED |
| 17.0-second initial response | FOREVER OBSERVED |
| Three sampled records report `hasAllInfo=true` | FOREVER OBSERVED |
| Three sample links/item IDs independently reviewed | UNKNOWN — not visible in supplied screenshot |
| Full 291,276-record traversal | NOT RUN |
| Item-data enrichment for all rows | NOT RUN |
| Variant mapping to browse item keys | NOT RUN |
| Unit-price and total-quantity equivalence | NOT RUN |
| Persistent Replicate snapshot | NOT RUN |
| No Sell-tab interference during full traversal | NOT RUN |
| 50% overall scan improvement | NOT RUN |

**Decision:** preserve the existing browse scanner and last-known-good snapshot path. The Replicate route is now a viable experimentally observed candidate, but not yet an accepted replacement.
