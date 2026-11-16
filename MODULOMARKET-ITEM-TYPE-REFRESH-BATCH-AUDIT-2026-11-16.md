# Modulo Market 0.12.17 — item-type refresh batching audit

**Date:** 2026-11-16
**Change type:** targeted player-visible performance fix
**Parent:** supplied 0.12.16 source and its standalone item-refresh/sort-loop diagnostics slice
**Target runtime:** Forever 1.60.1, build 70938

## Player problem and runtime evidence

The player reports repeated list depopulation, repopulation and `Sorting…` while the Equipment item-type filter is active.

The supplied 0.12.16 runtime sample showed:
- 6,353 item-data events (6,311 `GET_ITEM_INFO_RECEIVED`, 42 `ITEM_DATA_LOAD_RESULT`)
- 6,314 unique item IDs
- 6,352 refresh schedules and 6,347 timer reschedules
- only 5 refresh triggers
- 6 sort starts, 5 completions, 0 recorded sort restarts
- last sort: 4,176 result rows and 1.133 seconds

This identifies a repeated item-data refresh scheduling storm rather than a sort-restart storm. The old 250 ms timer was reset by nearly every successful item-data notification. Each timer expiry cleared the visible result rows and started another full filtering/sorting pass.

## Implementation

- Capture whether the item-data event belongs to an outstanding item-class request before invalidating request/cache state.
- Only a successful class resolution for a requested item marks the filtered market view as needing refresh. Unrelated item data and duplicate notifications no longer schedule a full catalogue rebuild.
- Replace the per-event 250 ms rescheduling timer with one pending batch.
- Wait until the item-class warmup queue is drained and outstanding item-class requests have responded.
- Wait until catalogue, economics, view, rank-sort and tooltip warmup queues are idle before the final rebuild.
- Add a bounded 10-second fallback: unresolved item-class requests are marked failed and the filtered view is rebuilt once, rather than waiting forever.
- Keep classification rules, sorting order, price data, scan/snapshot code, SavedVariables and user settings unchanged.

## Competing hypotheses and distinguishing evidence

1. **Metadata-notification storm:** supported by the supplied counters. Thousands of item events repeatedly reset a 250 ms timer, creating multiple full rebuilds.
2. **Independent expensive sort:** sort itself is non-trivial (1.133 seconds for 4,176 rows), but zero sort restarts and only five completed sorts do not explain the repeated timer scheduling. The new batching removes repeated refresh triggers during the metadata wave; one final sort remains necessary.

This patch addresses hypothesis 1. It does not claim that a single full sort is free or that all future lag is eliminated.

## Ownership, dependencies and risk

The defect is inside ModuloMarket's item-class cache and filtered view lifecycle. No MODULO core, optional-addon, Auctionator or specialist-addon dependencies are added. The only changed runtime behaviour is when the filtered market view is rebuilt after requested item-class metadata arrives.

Risk: a client that never returns item metadata now waits at most 10 seconds before unresolved requests are treated as unavailable and one final view build is started. This is bounded and does not alter persisted data.

## Verification

- Focused tests: **13 passed**.
- Full suite: **185 passed, 33 failed**. Exact 0.12.16 parent baseline: **181 passed, 33 failed**. Failure-ID comparison: **zero new failing test IDs**.
- Lua syntax: **14/14 addon Lua files parsed successfully** using `/usr/bin/texlua` and a `loadfile` validation script.
- Forever runtime acceptance on build 70938: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Player acceptance

1. Install 0.12.17 on Forever 1.60.1 build 70938.
2. Open Market, select All Items, then Equipment.
3. Observe whether the list now builds once after metadata arrives instead of repeatedly emptying and showing `Sorting…`.
4. Run `/mmtabperf reset`, `/mmtabperf on`, reproduce once, then `/mmtabperf`.
5. Expected: refresh schedules should be near one per metadata wave, reschedules should be zero, and refresh triggers should be one per completed batch (or a small number if a new separate batch begins after the 10-second fallback). The final sort remains measurable.
6. Run `/mmtabperf off` and send the output plus Freeloader sample.

**Status: SOURCE FIX IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN.**
