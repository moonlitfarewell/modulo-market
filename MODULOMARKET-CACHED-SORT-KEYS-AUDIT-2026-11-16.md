# Modulo Market 0.12.20 — cached incremental sort keys audit

**Date:** 2026-11-16
**Change type:** targeted sort-efficiency optimisation
**Parent source:** user-supplied full `modulo-market.zip`
**Repository:** `moonlitfarewell/modulo-market`, branch `main`
**Parent commit:** `f19f99dd4f6ceae613c1c666789ea040bb892ade`
**Parent addon/manifest version:** 0.12.19
**Parent ZIP SHA-256:** `a7d97890baa4a9dd6b329cfb4ce9aba43d8bde711a00ffa20e774efb61b7e93e`

## Player problem and runtime evidence

The player's Forever 1.60.1 build 70938 `/mmtabperf` capture showed:
- All Items: 6,632 rows, 47,695 comparisons, 1.774 seconds sort elapsed.
- Equipment: 4,176 rows, 78,958 cumulative comparisons over the captured sorts; last sort 1.005 seconds.
- History: 6,632 rows, 231,122 cumulative comparisons across all sorts; last sort 1.504 seconds.
- Catalogue aggregation took 1.329 seconds across 146 frames, with 0.65 ms maximum measured step.
- View filtering took 4.8 ms for All Items and 38.9 ms for Equipment; max frame times 0.25 ms and 1.48 ms respectively.
- Instant class lookup resolved 6,537/6,537 calls with no fallback, missing or queued requests.

This identifies sort work, rather than catalogue aggregation or filtering, as the strongest remaining measured bottleneck.

## Source diagnosis

`ComesBefore()` repeatedly:
- calls `GetItemName()` and `NormalizeSearchText()` for name sorts;
- calls those same functions again for tie-breaks on numeric sorts;
- extracts and converts the selected numeric primary value on every comparator invocation.

The incremental merge sort can invoke the comparator tens or hundreds of thousands of times for a few thousand rows. The same row's name and numeric sort value are invariant throughout a single sort operation, so recomputing them is redundant.

## Implementation

- Replace per-comparison extraction with `BuildSortKey(row, key, ascending)`.
- Cache each row's selected primary value, normalized name tie-break key, and item/recipe ID once per sort.
- Prepare keys incrementally, with the same 500-row-per-update work budget.
- Compare only cached scalar values during merge sorting.
- Retain the existing 500-comparison-per-update budget.
- Preserve primary-value rules, ascending/descending behavior, missing-value sentinels, normalized-name tie-break and itemID/recipeID final tie-break.
- Keep the existing incremental stable merge-sort algorithm.
- No catalogue, filter, item-class, price, recipe, snapshot, SavedVariables or settings behaviour is changed.

## Hypotheses and risk

1. **Repeated sort-key extraction is a major part of sort cost:** strongly supported by source inspection and high comparator counts. This patch removes repeated extraction.
2. **UI presentation or other per-row work also contributes:** remains possible; this patch does not optimize row creation/layout or other addon work.

Key preparation adds one incremental pass over the result set. It is bounded to 500 rows per update, avoiding a synchronous 6,000-row preparation spike. Memory use increases by one compact key record per row for the duration of the sort.

## Ownership and compatibility

This is ModuloMarket's own sorting implementation. No MODULO core change, optional addon dependency, Auctionator dependency, or specialist-addon responsibility is introduced. No Forever-only API is added; existing `GetItemName()` compatibility path is retained but called once per row per sort rather than per comparison.

## Verification

- Focused tests: **5 passed**.
- Full pytest suite: **198 passed, 37 failed**. Fresh extraction of the exact 0.12.19 parent ZIP: **193 passed, 37 failed**. Failure-ID comparison: **zero new failing test IDs**; five active release-version assertions were updated to 0.12.20.
- Lua syntax: **14/14 addon Lua files parsed successfully** using `/usr/bin/texlua` and a generated `loadfile` check script.
- Forever 1.60.1 build 70938 runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Runtime acceptance

1. Install 0.12.20 on Forever build 70938.
2. Reset and enable `/mmtabperf`.
3. Open All Items, then visit Equipment, Economics and History.
4. Capture sort elapsed, comparison counts and Freeloader spikes.
5. Compare with the 0.12.19 measurements on the same snapshot.
6. Confirm visible order is unchanged for name, price, profit, quantity and tab-specific sort modes.

**Status: SOURCE IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN.**
