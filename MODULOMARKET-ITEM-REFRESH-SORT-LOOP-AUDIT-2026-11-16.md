# Modulo Market 0.12.16 — item refresh and sort-loop diagnostics audit

**Date:** 2026-11-16
**Change type:** opt-in diagnostics-only instrumentation; no behavioural fix claimed
**Parent source:** 0.12.15 tab-build diagnostics slice derived from the supplied `modulo-market.zip` plus the delivered 0.12.15 patch
**Original repository parent:** `moonlitfarewell/modulo-market`, branch `main`, commit `d6b1f8a7e443586c28382ea9e619e9116035856e`
**Original uploaded ZIP SHA-256:** `ad0af83c984a1f708d1a1fed86bf47f0e92349eaa06ff544f7ac689e8851856c`
**Current parent addon version:** 0.12.15

## Player problem and observed evidence

On Forever 1.60.1 build 70938 with ModuloMarket 0.12.15, the player reports that selecting the Equipment item-type filter can cause the All Items list to repeatedly empty, display `Sorting…`, repopulate, then empty and sort again. This is a player-visible refresh loop, not merely a profiler label.

The accompanying `/mmtabperf` sample showed:
- market: 7 requests, 7 builds, 3 completed, 4 cancelled; 46,424 source rows; 19,896 processed rows; 17,440 result rows; 5.300 seconds aggregate elapsed
- economics: 11 requests, 10 builds, 9 completed, 1 cancelled; 66,320 source rows; 59,688 processed rows; 27,377 result rows; 9.318 seconds aggregate elapsed
- history: 2 requests, 2 builds, 1 completed, 1 cancelled
- materials: 7 requests/builds, all 7 completed
- same-tab selections: 1 of 22

The player clarified that “spamming sort” means the list visibly depopulates/repopulates and the header displays `Sorting…` repeatedly. The initial large spike while choosing Equipment was not captured because diagnostics were enabled after it occurred.

## Source findings

The MarketUI item-data event handler (`GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT`) invalidates item class/vendor/icon caches. When a successful event resolves a class ID while a non-default item-type filter is active on the market tab, it sets `UI.itemTypeRefreshDueAt = Now() + 0.25`.

The OnUpdate loop starts that delayed view build when catalog/economics/view/sort work is idle. `UI.StartViewBuild()` clears `UI.viewRows` and `UI.rankSort`, and the view later starts the incremental merge sort. Therefore each delayed refresh can produce the visible empty-list/`Sorting…`/repopulate sequence.

Two competing explanations remain:
1. A finite wave of distinct item metadata arriving as Equipment filtering warms item classes, with each successful event rescheduling the refresh timer.
2. Duplicate/repeated item-data notifications or newly requested item data during each pass repeatedly rescheduling refreshes, preventing the list from settling.

A third possible contributor is the cost of the sort itself. The prior diagnostics included sort time inside total build elapsed and could not distinguish it from filtering. The new counters separate sort starts/completions/restarts and comparator calls.

## Change scope

- Extend `/mmtabperf` with event counters for `GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT`.
- Count total events, unique item IDs, class resolutions, refresh schedules, timer reschedules, and refresh triggers.
- Capture last event, item ID and active item-type filter.
- Count sort starts, completions, restarts, and comparator calls; capture last sort tab/filter/row count/elapsed time.
- Counters are opt-in, in-memory only, and disabled by default.
- No item-data refresh, filter, sorting, price, recipe, scan, snapshot or SavedVariables behaviour is changed.
- Version metadata is 0.12.16. This is a diagnostics slice, not a performance fix.

## Distinguishing runtime test

1. Install 0.12.16 on Forever 1.60.1 build 70938.
2. Open Market, set All Items and select the Equipment item-type filter.
3. Before selecting Equipment, run `/mmtabperf reset` then `/mmtabperf on`.
4. Let the list settle (or reproduce the repeated empty/`Sorting…` cycle), then run `/mmtabperf`.
5. Capture the full output and Freeloader sample. Then run `/mmtabperf off`.

Interpretation:
- High `refreshScheduled` and `refreshRescheduled`, with `refreshTriggered` repeatedly increasing, supports metadata notifications repeatedly postponing/restarting the view.
- `unique` close to `total` supports a finite wave of distinct IDs; a large gap indicates repeated notifications for the same IDs.
- High `sort.restarted` relative to `sort.started` confirms sorts are being abandoned and restarted.
- High comparator calls and sort elapsed with few restarts supports one expensive sort rather than a refresh loop.
- High refresh counts but low sort restart count suggests refreshes occur before or after sorting rather than repeatedly interrupting it.

## Ownership and dependencies

This is ModuloMarket's own item metadata, view refresh and incremental sorting pipeline. No MODULO core changes, optional addon dependencies, Auctionator integration, or specialist-addon responsibilities are introduced.

## Verification

- Focused diagnostics tests: **9 passed**.
- Full pytest suite: **181 passed, 33 failed**.
- Exact 0.12.15 parent baseline (fresh extraction of uploaded source plus delivered 0.12.15 patch): **176 passed, 33 failed**.
- Failure-ID comparison: **zero new failing test IDs**.
- Lua syntax validation: **14/14 addon Lua files parsed successfully** with `/usr/bin/texlua` and a `loadfile` check script.
- Forever 1.60.1 build 70938 runtime for 0.12.16: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Acceptance and exit criteria

- [x] Item event counts by event type and unique item ID.
- [x] Refresh scheduling/rescheduling/trigger counters.
- [x] Sort lifecycle and comparator counters.
- [x] Diagnostics remain opt-in and in-memory only.
- [x] Focused tests pass.
- [x] No new failing test IDs against the exact 0.12.15 parent.
- [x] Lua syntax check 14/14.
- [ ] Forever runtime acceptance and capture of the Equipment-filter loop.
- [ ] Evidence identifies whether the loop is distinct metadata arrival, duplicate events, or sort cost.
- [ ] Implement the smallest targeted behaviour fix only after that evidence.

**Status: SOURCE IMPLEMENTED; OFFLINE TESTS PASS WITH UNCHANGED BASELINE FAILURES; FOREVER RUNTIME NOT RUN.**
