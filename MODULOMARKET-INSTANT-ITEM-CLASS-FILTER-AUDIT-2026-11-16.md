# Modulo Market 0.12.18 — Instant item-class filter audit

**Date:** 2026-11-16  
**Change type:** targeted correctness and performance fix for All Items item-type filtering  
**Parent addon version:** 0.12.17  
**Target client:** Forever 1.60.1, build 70938  
**Repository parent:** `moonlitfarewell/modulo-market`, branch `main`, commit `d6b1f8a7e443586c28382ea9e619e9116035856e`  
**Original supplied source ZIP SHA-256:** `ad0af83c984a1f708d1a1fed86bf47f0e92349eaa06ff544f7ac689e8851856c`  
**0.12.17 parent patch SHA-256:** `f59ef011092a3f55b54682974d05f0aad02890c9e0c2da36ac63f3277ac13ad8`

## Player problem and runtime evidence

The player reported that after the earlier Equipment-filter changes, selecting All Items → Equipment caused a long `Searching N/...` progress sequence, returned only 32–35 items despite the unfiltered catalogue containing thousands, and produced substantial lag.

The supplied 0.12.17 Forever capture showed:
- one market build, 6,632 source rows processed, 35 results;
- build elapsed time 8.271 seconds;
- sort time 0.351 seconds for 35 rows;
- 6,548 item-data notifications, 6,460 unique item IDs;
- zero class resolutions counted by the previous event-driven class-request path;
- 1,540 ModuloMarket profiler spikes over 5 ms.

Counter-evidence: this capture does not prove that the Instant API is implemented or functioning on the live client; it is evidence of the old full-record lookup path failing to resolve enough classes. The current result count must be checked again after installing 0.12.18.

## Source diagnosis

`MatchesItemType()` calls `GetItemClassID(itemID, true)` for each candidate row. Before this patch, `GetItemClassID()` tried the full `C_Item.GetItemInfo` record and legacy-compatible `GetItemInfoCompat()`. When full item information was not cached, it queued asynchronous class requests. That is excessive for a filter that needs only the item's numeric class ID.

The API documentation for Forever 1.60.1 specifies:

`itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID = C_Item.GetItemInfoInstant(itemInfo)`

The class ID is the sixth return value. The API returns readily available item information without requiring a full item-data query. Reference: https://warcraft.wiki.gg/wiki/API:C_Item.GetItemInfoInstant

The full `C_Item.GetItemInfo` API returns a different tuple, including `classID` as its twelfth value, and may return nil while an item is not cached. Reference: https://warcraft.wiki.gg/wiki/API:C_Item.GetItemInfo

The previous code did not call `GetItemInfoInstant` at all. This is the concrete API gap addressed here.

## Implementation

- `GetItemClassID()` now tries `C_Item.GetItemInfoInstant` first, with global `GetItemInfoInstant` as compatibility fallback.
- It reads `classID` from the sixth return value and caches it in `UI.itemClassCache`.
- Full `C_Item.GetItemInfo` / `GetItemInfoCompat` calls and asynchronous warmup remain fallback-only when Instant metadata is unavailable.
- `CacheVendorInfo()` also populates the item-class cache when its full-record path already provides a class ID.
- Existing class mapping remains unchanged: Consumables `0`, Equipment `2` or `4`, Trade Goods `7`, Other all remaining classes.
- Existing incremental view-processing budget remains 250 source positions per update. This slice does not increase that budget or remove incremental safeguards.
- No scan, snapshot, auction data, recipe data, SavedVariables schema, MODULO core, Auctionator, or optional-addon dependency changes.

## Competing hypotheses

1. **Full item-info cache misses caused the tiny result count and metadata work.** Strongly supported by the source call chain and the runtime's zero successful class resolutions. Instant class lookup directly addresses this.
2. **A separate catalogue aggregation defect dropped items before filtering.** Not supported by the supplied evidence: the build processed 6,632 source rows, and the reported All Items catalogue already contained thousands of items. This remains a secondary possibility if 0.12.18 still returns a materially incomplete count.
3. **The 250-row incremental budget is the primary lag source.** Not established. It explains the visible 250-step progress increments, but does not by itself explain the 8.271-second build or 35 results. The budget is preserved pending runtime timing after class lookups become synchronous.

## Ownership, dependencies and risks

This is ModuloMarket's own catalogue filter and client item metadata lookup. No MODULO core change, specialist-addon responsibility, or dependency is introduced. The Instant API is documented for Forever 1.60.1; the full-info path remains as fallback for other compatible clients.

Risk: if the target client's Instant API differs from its documented return contract, the fallback will still queue full item data and the filter may remain slow/incomplete. This is why runtime acceptance is mandatory.

## Verification

- Focused tests, including an executable Lua contract harness that extracts and runs the actual `GetItemClassID()` implementation against representative Instant tuples: **17 passed**.
- Full pytest suite: **189 passed, 33 failed**.
- Exact 0.12.17 parent baseline: **185 passed, 33 failed**.
- Failure-ID comparison: **zero new failing test IDs**.
- Lua syntax: **14/14 addon Lua files parsed successfully** with `/usr/bin/texlua` and `loadfile` checks.
- Manifest inventory: **382 paths, 381 hashes, zero missing files or hash mismatches**.
- ZIP CRC/fresh extraction: **PASS**; all 11 patch entries extracted cleanly and matched the working-tree bytes.
- Forever build 70938 runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Player acceptance / exit criteria

1. Install 0.12.18 on Forever 1.60.1 build 70938 and `/reload`.
2. Open Market, choose All Items, then Equipment.
3. Confirm the result count is plausible and materially larger than 35; verify sample weapons and armour from different item families are present.
4. Confirm the progress counter completes and the list does not repeatedly empty/re-sort.
5. Switch All Items → Equipment → All Items → Equipment again. The second Equipment selection should reuse the in-session class cache and be faster.
6. Capture `/mmtabperf` and Freeloader output. Compare market `elapsed`, result count and spike count against the 0.12.17 capture.

**Status: SOURCE FIX IMPLEMENTED; OFFLINE TESTS PASS WITH UNCHANGED BASELINE FAILURES; FOREVER RUNTIME ACCEPTANCE NOT RUN.**
