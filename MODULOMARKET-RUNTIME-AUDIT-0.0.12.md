# Modulo Market Runtime Audit 0.0.12 — bounded Replicate record inspection

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.12  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release type:** separate optional child addon; bounded, read-only diagnostic capability.

## 1. Player problem and observable result

The player has confirmed that one explicitly requested `C_AuctionHouse.ReplicateItems()` call returned 291,276 auction records in 17.0 seconds on the target Forever client. Three initial sample records reported `hasAllInfo=true`. The next blocker is understanding whether Market can read actual auction-level fields at scale without locking the UI, losing data or changing the existing browse snapshot.

0.0.12 adds a player-triggered **Inspect 250 Cached Records** action. It reads the existing in-memory replicated cache only. It does not call `ReplicateItems()`, does not request item data, does not traverse the full auction list, and does not change `lastSnapshot`.

## 2. Direction / implementation gate

### Evidence supporting this slice

- 0.0.11 player screenshots: initial Replicate request response event arrived; count 291,276; elapsed 17.0 seconds; three sample records all reported `hasAllInfo=true`.
- 0.0.11 source: `GetReplicateItemInfo` already captures return positions 17 and 18 for itemID and hasAllInfo.
- Supplied Auctionator 341 source: `Source_ModernAH/FullScan/Mixins/Frame.lua` reads `GetReplicateItemInfo`, `GetReplicateItemLink`, `GetReplicateItemTimeLeft`; treats return 3 as stack count and return 10 as buyout; processes in 250-record batches with a 0.01-second yield. This is reference behavior, not a dependency or proof of Market's result.
- Existing browse snapshot: 16,574 variants / 34 pages / 21.1 seconds, with 16.8 seconds waiting for throttle (player screenshot).

### Counter-evidence / unknowns

- The 291,276 count is a count of auction-level records, not unique item variants.
- The three original sample records' actual IDs/links/price tuples were not visible in the player's screenshot.
- The 250-record diagnostic has not yet run on Forever.
- Full-list processing may trigger repeated cache update events or client slowdown. The exact target-client cost is unknown.
- The replicated cache may no longer be present after `/reload`, closing the Auction House, or session changes. The action checks availability and count; it never requests a replacement list.
- `hasAllInfo=true` for three records is not evidence that all 291,276 records are complete.
- Variant identity and price/quantity equivalence to Browse remain unproven.

### Competing hypotheses and distinguishing diagnostic

1. **Bounded reads are inexpensive and records expose usable fields.** The 250-record sample should complete within the 20-second guard, with few API errors, valid item IDs, stack counts and links, and no visible UI stall.
2. **Even bounded reads expose incomplete/unstable fields or cause slowdowns.** The sample counters will show missing IDs, `hasAllInfo=false`, nil links, invalid stack counts, API errors or timeout; the player can also report visible UI responsiveness.
3. **Auction-level fields are readable but cannot yet map to Browse's variant identity.** The five retained item links and tuple fields provide evidence for the next item-key mapping investigation; they do not resolve mapping by themselves.

## 3. Ownership and dependency boundary

- Owner: `ModuloMarket`, a separate optional child addon.
- Parent MODULO 1.0.48 remains unchanged.
- Dependency remains one-way: Market depends on MODULO; MODULO does not depend on Market.
- Auctionator source is a behavioral reference only. Market does not depend on Auctionator or call its private queues/database.
- This capability is read-only. It does not buy, sell, post, cancel, mutate professions or change Auction House listings.

## 4. Implementation details

### Player action and bounded workload

- Button: **Inspect 250 Cached Records**.
- Always visible; it only reads the existing cache if available and never sends a new request.
- Calls `GetNumReplicateItems()` to check whether a cached list currently exists. If zero/unavailable, reports that no cached records are available; it does not issue a new request.
- Inspects up to 250 evenly spaced zero-based indices from the cached list, not merely the first 250 records.
- Processes at most 25 records per `OnUpdate` frame.
- 20-second total timeout.
- Checks the Auction House is still open, the existing Sell-tab safety gate remains clear, and the reported list count remains stable before each batch.
- Stops on Auction House close, Sell-tab safety failure, cache count change, or the 20-second timeout. Per-record accessor errors are counted and processing continues through the bounded sample so the failure rate can be measured.
- Reads `GetReplicateItemInfo`, `GetReplicateItemLink`, and `GetReplicateItemTimeLeft` where available.
- Field positions based on supplied Auctionator source and Forever API research: return 3 stack count; return 10 buyout copper; return 17 itemID; return 18 hasAllInfo.
- Does not call `RequestLoadItemDataByID`, `C_Item.DoesItemExistByID`, `ReplicateItems`, Browse APIs, or item-data loaders.
- Retains at most five detailed sample rows in SavedVariables; aggregates counters for all inspected rows.
- Candidate unit price is displayed only when stack count and buyout are positive: `ceil(buyoutCopper / stackCount)`. It is explicitly a candidate derived from the observed tuple, not yet validated against Browse.
- Saves the diagnostic result under `ModuloMarketDB.lastReplicateInspection`.
- Never assigns to `ModuloMarketDB.lastSnapshot`.

### Persistent metadata

0.0.12 persists compact initial-probe metadata under `ModuloMarketDB.lastReplicateProbe`: timestamp, response time, auction count, sample count, sample hasAllInfo count and `completeScan=false`. The earlier 0.0.11 request timestamp remains the cooldown source. No auction-list rows are persisted by the initial probe.

### Known risk / limitation

`REPLICATE_ITEM_LIST_UPDATE` may fire as item data is cached. The inspection action does not register for or act on those events; it only checks the count before each batch. The diagnostic is bounded to 250 records, but the actual client performance effect remains unknown until player runtime acceptance.

## 5. Source review and scope

Reviewed:
- `AddOns/ModuloMarket/Scanner.lua`: probe lifecycle, new inspection action, shared Sell safety gate, Auction House close handling, saved snapshot restore/commit, UI placement.
- `AddOns/ModuloMarket/Core.lua`: addon identity, SavedVariables initialization and command lifecycle.
- `AddOns/ModuloMarket/ModuloMarket.toc`: version, load order, SavedVariables and parent dependency.
- `README.md`, `MANIFEST.json`, existing focused tests and both Lua model harnesses.
- Supplied Auctionator `Source_ModernAH/FullScan/Mixins/Frame.lua` for return positions, batching, cache processing and item-data loading reference.
- Parent MODULO 1.0.48: project start/README/workflow, progress, decisions, QA, review ledger, architecture, product direction, reference environment and Forever compatibility contract. No MODULO source files changed.
- Canonical parent: `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, ZIP CRC PASS. Project file ID `file_000000001a2482128af00913b054f6f9`, source_kind `project`, uploaded_by `developer`.
- Prior child source: `ModuloMarket-0.0.11.zip`, 49,784 bytes, SHA-256 `5c7fe9369bfe45f9048dc3225d9248071aef9a18d82bdc3aa9a0156ec217486b`, ZIP CRC PASS. Project file ID `file_000000001b7481f49a64a0249aca8163`, source_kind `project`, uploaded_by `developer`.

Not inspected line-by-line: unrelated MODULO source modules, unrelated Market profession diagnostics implementation and unrelated historical audit prose. They are outside this slice and no caller/ownership changes were made to them.

## 6. Tests and package validation

- `python -m pytest -q tests` — **PASS, 36 passed**.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**; includes bounded 250-record sampling, no second Replicate call, tuple parsing, and last-known-good preservation.
- ZIP CRC, exact manifest inventory, fresh extraction, version agreement and SHA-256 — **PASS**, recorded in the final handoff.
- FOREVER runtime inspection: **NOT RUN** until player installs 0.0.12 and clicks the inspection action.
- Retail runtime: **NOT RUN**.
- Full-list processing, enrichment, aggregation and Browse equivalence: **NOT RUN**.

## 7. Player acceptance / exit criteria

1. Install Modulo Market 0.0.12 beside MODULO 1.0.48.
2. Open the Auction House and `/mm`.
3. If the replicated cache is still available, click **Inspect 250 Cached Records**. This action does not make a new Replicate request.
4. If it reports no cached records, do not attempt to work around the cooldown. Wait until the 15-minute account-wide cooldown has elapsed before considering another explicitly confirmed Replicate request.
5. Allow the bounded sample to complete; do not browse, buy, sell or post during the sample.
6. Send the completion screenshot and, after a normal reload/logout has flushed SavedVariables, `WTF/Account/<account>/SavedVariables/ModuloMarket.lua` if the five sample rows' links and exact tuple values are needed.
7. Confirm the previous Browse `lastSnapshot` remains intact and normal Auction House/Sell behavior remains available.

Acceptance requires:
- exactly up to 250 records inspected;
- no new `ReplicateItems()` call from the inspection action;
- no `lastSnapshot` replacement;
- completion without a client stall/Lua error;
- counters and sample fields captured;
- no Sell-tab interference.

## 8. Exit state

0.0.12 delivers a player-accessible bounded cached-record inspection capability. It is not a full scanner. No full Replicate list traversal, missing-item enrichment, variant mapping, aggregation, snapshot replacement or 50% end-to-end speed claim is accepted by this slice.

**FOREVER status:** initial Replicate response is **FOREVER OBSERVED** from the 0.0.11 player screenshot (291,276 records in 17.0s; 3/3 samples `hasAllInfo=true`). The new 250-record inspection is **SOURCE IMPLEMENTED; FOREVER RUNTIME NOT RUN**.
