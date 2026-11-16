# Modulo Market 0.12.15 — tab-build diagnostics audit

**Date:** 2026-11-15
**Change type:** diagnostics-only instrumentation; no performance optimisation claimed
**Parent source:** uploaded `modulo-market.zip`, repository `moonlitfarewell/modulo-market`, branch `main`
**Parent commit:** `d6b1f8a7e443586c28382ea9e619e9116035856e`
**Parent uploaded ZIP SHA-256:** `ad0af83c984a1f708d1a1fed86bf47f0e92349eaa06ff544f7ac689e8851856c`
**Parent TOC/Core version:** 0.12.13
**Working-tree pre-existing changes preserved:** `data/README.md`, `tests/historical/test_modulomarket_0_11_0_themes.py`, `tests/historical/test_modulomarket_0_11_1_themes.py`

## Player problem and expected result

The player's Forever 1.60.1 build 70938 profiler sample was taken while running ModuloMarket 0.12.13. It showed 1,414 spikes above 5 ms, with no clear bag-open spike. The player reported that spikes often occurred as tabs repopulated after switching tabs.

This slice adds opt-in, per-tab view-build counters and timing so the next runtime test can distinguish expensive tab source construction, large row-processing workloads, repeated builds and cancelled/replaced builds. It does **not** claim to fix the spikes or prove that tab population is their only cause.

## Source findings

- `SetTab()` always calls `UI.StartViewBuild()` at the end, including same-tab selection.
- `UI.StartViewBuild()` obtains a tab-specific source (`GetAllCraftSources`, `GetMaterialCatalog`, `TurnInEngine.BuildRows`, or the market catalogue), resets the visible result set, then starts incremental filtering.
- `StepView()` processes the source incrementally, with a nominal maximum of 250 source positions per frame and an additional tooltip-search scan budget.
- Sorting is a separate incremental phase through `StepRankSort()`.
- This means source construction, filtering, sorting and row rendering are distinct possible contributors. The diagnostics added here measure source construction and the filtering/build lifecycle; they do not provide a profiler-grade breakdown of every sort or render call.

## Change scope

- Added opt-in `/mmtabperf` diagnostics.
- `/mmtabperf on` enables counters; collection is disabled by default.
- `/mmtabperf` reports selection counts, same-tab selections, cancelled builds and per-tab request/build/completion counts, source rows, processed rows, result rows, source construction seconds, and elapsed build seconds.
- `/mmtabperf reset` clears counters.
- `/mmtabperf off` disables collection.
- No continuous chat logging is added.
- No SavedVariables schema or saved player preference is changed.
- No market, recipe, snapshot, price, sorting, filtering, scan, or specialist-addon behavior is intentionally changed.
- Bumped TOC/Core/TurnInData/manifest version metadata to 0.12.15. Version 0.12.14 was a separate unmerged experiment and is not silently included in this source slice.

## Competing hypotheses to distinguish

1. **Repeated or unnecessarily broad view builds:** tab switching or same-tab selections repeatedly reconstruct large source lists and rerun filtering.
2. **Tab-specific expensive work:** one source builder or one tab's filtering path (notably crafts/turn-ins/materials) is disproportionately costly even when builds are expected.
3. **Downstream sort/render work:** view filtering may be relatively cheap while sorting or visible row presentation causes the observed frame spikes. This instrumentation does not fully measure those phases; use the runtime sample to identify which tabs correlate before expanding scope.

## Ownership and dependencies

This is ModuloMarket's own tab selection and view-building pipeline. No MODULO core change, optional addon, Auctionator integration, or specialist-addon dependency is introduced.

## Verification

- Focused source-level tests: **4 passed**.
- Focused source-level tests: **4 passed**.
- Full pytest suite on the changed tree: **176 passed, 33 failed**.
- Parent baseline from a fresh extraction of the exact uploaded ZIP: **172 passed, 33 failed**.
- Failure-ID comparison: **zero new failing test IDs**. The four active tests that derive expected version from `MANIFEST.json` now pass with the synchronized 0.12.15 manifest; the one active 0.12.13 settings-label assertion was updated to the current version. The current full suite has the same 33 failing test IDs as the uploaded parent baseline.
- The historical settings harness failure (`tests/settings_0_12_12_harness.lua` against `Theme.lua`) is present on the untouched parent baseline.
- Lua syntax validation: **14/14 addon Lua files parsed successfully** using `/usr/bin/texlua` with a generated `loadfile` check script.
- Forever 1.60.1 build 70938 runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Runtime procedure

1. Install the 0.12.15 slice on the target Forever 1.60.1 build 70938 client.
2. Open Market and run `/mmtabperf reset`, then `/mmtabperf on`.
3. Reproduce the reported workflow: search, switch repeatedly among the same tabs, open/close `/mm`, and change filters.
4. Run `/mmtabperf` and capture the complete output alongside the Freeloader profiler sample.
5. Repeat once with the same workflow but fewer tab changes to establish a comparison.
6. Run `/mmtabperf off`.

Interpretation:
- High `sameTab` count with matching `cancelled`/`requests` suggests redundant selections/build requests.
- High `sourceRows` and `processedRows` on one tab points to its source/filter workload.
- Low row counts but high profiler spikes suggests work outside the measured source/filter lifecycle (e.g. sort, render, UI layout, other addon interactions).
- Compare `source` and `elapsed` seconds across tabs; these use the client's `GetTime()` clock and are diagnostic aggregates, not per-frame CPU samples.

## Acceptance and exit criteria

- [x] Diagnostics are opt-in and disabled by default.
- [x] Report/reset/on/off command paths are covered by focused source tests.
- [x] Per-tab source row, processed row, result row and elapsed-time counters are implemented.
- [x] Pre-existing dirty source files were preserved.
- [x] Lua syntax validation (14/14 addon Lua files).
- [ ] Forever runtime command/UI acceptance on build 70938.
- [ ] Correlate diagnostics output with the player's profiler spikes.
- [ ] Decide the smallest measured optimisation after the runtime evidence is reviewed.

**Status: SOURCE IMPLEMENTED; OFFLINE TEST BASELINE RECONCILIATION IN PROGRESS; FOREVER RUNTIME NOT RUN.**
