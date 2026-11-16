# Modulo Market 0.12.19 — first-load pipeline diagnostics audit

**Date:** 2026-11-16
**Change type:** opt-in diagnostics only; no performance behaviour change claimed
**Parent addon version:** 0.12.18
**Repository:** `moonlitfarewell/modulo-market`, branch `main`
**Parent commit:** `d6b1f8a7e443586c28382ea9e619e9116035856e`
**0.12.18 patch ZIP SHA-256:** `7ba1143f299d189bf92342c98eedac7b995908b69ee53f85669213fb6625ed6`

## Player problem and evidence

The player reports that the first-time All Items/catalogue or filtered-view population remains noticeably hitchy after the 0.12.18 Instant item-class lookup improvement. Subsequent filter work is improved, but initial loading remains a separate cost. No fresh `/mmtabperf` capture of the first load was supplied with this request, so the exact cost centre is not yet established.

## Source findings

The current implementation has two distinct incremental stages:

1. `StartCatalog()` / `StepCatalog()` aggregates the saved auction snapshot's auction-level rows into one aggregate per item ID. `StepCatalog()` currently processes at most 250 source rows per OnUpdate. When complete, it performs a separate pass to materialize `UI.catalog` from the ordered IDs.
2. `StartViewBuild()` / `StepView()` filters the unique-item catalogue for the active tab. `StepView()` also processes at most 250 source positions per OnUpdate. For the Market item-type filter, `MatchesItemType()` calls `GetItemClassID()`, which uses the Instant API and caches the result.

These stages are currently conflated in broad addon profiler totals. Existing tab diagnostics measure aggregate wall time for view builds and sort time, but do not measure catalogue aggregation CPU per frame, final catalogue materialization, view-filter CPU per frame, or Instant class-cache hit/miss ratios.

## Change scope

`/mmtabperf` gains opt-in high-resolution counters for:

- Catalogue indexing starts/completions/cancellations.
- Auction source rows processed, unique item aggregates created, variant merges and frames used.
- Cumulative and maximum per-frame catalogue aggregation time.
- Final `UI.catalog` materialization time and total catalogue elapsed milliseconds.
- View-filter frames, rows processed, cumulative and maximum per-frame processing time, last frame rows, tab and item-type filter.
- Item-class lookup calls, cache hits, Instant API calls/resolutions, full-info fallback calls/resolutions, unresolved lookups and async requests queued.

Timing uses `debugprofilestop()` when available, with `GetTime()` as a lower-resolution fallback. Collection remains disabled by default. No SavedVariables, auction data, class rules, row budgets, scan code or filtering behaviour is changed.

To capture the first catalogue build, the player must run `/mmtabperf reset`, then `/mmtabperf on`, **before opening Market** after `/reload`.

## Competing hypotheses

1. **Catalogue aggregation dominates:** many auction rows and variant merges make `StepCatalog()` the hitch source; the per-frame max will be high or the cumulative work will dominate.
2. **Final materialization dominates:** the final ordered-ID-to-aggregate copy loop creates a single frame hitch after the incremental aggregation.
3. **First view filtering / class lookup dominates:** catalogue indexing is modest, but the first `StepView()` pass spends time on class lookups or other per-item filtering; the first-pass class counters will show cache misses and Instant resolutions.
4. **Rendering/layout dominates:** catalogue and view per-frame work are small, while the player still sees a hitch; the remaining cost is likely downstream row/detail presentation or other addon interaction and needs a separate trace.

## Ownership and risk

This is ModuloMarket's own snapshot catalogue and view pipeline. No MODULO core changes, optional-addon dependencies, Auctionator integration or specialist-addon responsibilities are introduced. The instrumentation adds work only when explicitly enabled; the processing budgets remain 250 source rows per frame.

## Runtime procedure

1. On Forever 1.60.1 build 70938, `/reload`.
2. Before opening `/mm`, run `/mmtabperf reset`, then `/mmtabperf on`.
3. Open Market and wait for All Items to finish its initial load.
4. Run `/mmtabperf` and save the output.
5. Select Equipment once, wait for it to finish, and run `/mmtabperf` again.
6. Switch to Economics, Crafts, Materials and Turn-ins one at a time; record the report after each has settled.
7. Run `/mmtabperf off`.

The most useful fields are `Catalog stepMax`, `finalize`, `elapsed`, `View max`, and `Class lookup cache/instant`. A high `Catalog stepMax` points to aggregation frame cost; high `finalize` isolates the final copy; high `View max` with many Instant calls points to first filter cost; low values across these phases points away from the measured pipeline.

## Verification

- Focused tests: **8 passed** (`tests/test_modulomarket_0_12_18_instant_item_class_filter.py` and `tests/test_modulomarket_0_12_19_first_load_pipeline_diagnostics.py`).
- Full pytest suite: **193 passed, 33 failed**. Exact reconstructed 0.12.18 parent baseline: **189 passed, 33 failed**. Failure-ID comparison: **zero new failing test IDs**; four additional tests pass.
- Lua syntax: **14/14 addon Lua files parsed successfully** with `/usr/bin/texlua` and a `loadfile` validation script.
- Forever runtime for 0.12.19: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Acceptance / exit criteria

- [x] Catalogue aggregation and finalization measured separately.
- [x] View filtering measured separately from sorting.
- [x] Instant class lookup/cache behaviour measured.
- [x] Diagnostics opt-in; processing budgets unchanged.
- [ ] Focused/full offline verification complete.
- [ ] Forever first-load capture identifies the dominant cost centre.
- [ ] Implement the smallest measured optimization after the runtime data is reviewed.

**Status: SOURCE INSTRUMENTATION IMPLEMENTED; OFFLINE VERIFICATION IN PROGRESS; FOREVER RUNTIME NOT RUN.**
