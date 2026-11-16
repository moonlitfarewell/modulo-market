# Modulo Market 1.0.3 — Incremental Sort Nil-Guard Audit

**Date:** 2026-11-16  
**Parent source:** user-supplied `modulo-market.zip`  
**Parent ZIP SHA-256:** `ef16c73b73112c75021e14475eced47f5dedb6fafe56d628a9940e28055bd327`  
**Git provenance:** `moonlitfarewell/modulo-market`, branch `main`, commit `75767794eacbb3bb59a8205a0847c35a7aadb34c` (`Update to Modulo-Market 1.0.2`), matching the supplied `origin/main` tracking ref at inspection.  
**Pre-existing local changes preserved:** `data/README.md`, `tests/historical/test_modulomarket_0_11_0_themes.py`, `tests/historical/test_modulomarket_0_11_1_themes.py`.

## Player problem and result

The 1.0.1 runtime traceback showed a sort comparator indexing a nil right-hand row (`b`) while sorting the name `mage eye blunderbuss`. In 1.0.2, the comparator was refactored to use cached sort-key records, but the equivalent unchecked assumption remained: both comparator arguments must be present. The player subsequently observed a successful full sort on 1.0.2, which is positive counter-evidence but does not prove the old edge case impossible.

1.0.3 hardens the sort boundary: it compacts sparse/invalid view rows into a dense ordered list before computing the merge-sort count, and makes the cached-key comparator safe if either key is unexpectedly absent.

## Evidence and competing hypotheses

1. **Sparse or invalid view rows reach the incremental merge sort.** Supported by the original runtime locals (`a` was a valid item record and `b=nil`) and by the current sorter's unchecked access to `state.source[state.j]` / `state.keys[...]`. The new boundary compaction directly addresses this class of input.
2. **The merge-sort state machine can produce an absent right-hand key despite a dense input.** Not established by current source inspection; the merge pass writes dense target ranges. The nil-safe comparator is defense in depth and prevents a UI Lua error if this occurs.
3. **A stale/cancelled view generation or concurrent refresh mutates the source during sorting.** Plausible lifecycle contributor, but no runtime trace proves it. This patch does not change cancellation or generation ownership.

The current source cannot establish which runtime path produced the original 1.0.1 nil row. The exact old traceback line no longer maps one-to-one to 1.0.2 because the comparator was refactored.

## Implementation

- Added `CompactSortRows()`, preserving numeric index order while dropping holes and non-table entries.
- Compact the completed view rows before the sorter calculates its count and prepares cached keys.
- Make `SortKeysComeBefore()` handle missing keys deterministically without indexing nil: a present key sorts before a missing key; two missing keys remain stable.
- Preserve all existing primary sort values, ascending/descending semantics, normalized-name and ID tie-breaks, incremental preparation and merge budgets.
- No price, scan, snapshot, SavedVariables, filtering, recipe, settings or specialist-addon behaviour changed.
- Bumped aligned release metadata to 1.0.3.

## Ownership and risk

This is ModuloMarket's own view sorting pipeline. No MODULO core changes, optional addon dependency, Auctionator dependency or private specialist API is introduced.

The compaction pass allocates a temporary indexed list and a dense row list at view completion. This is bounded to the current view result size. Invalid non-table entries are excluded from the visible result set; such entries are not valid market rows.

## Verification

- Focused regression and cached-sort tests: **8 passed**.
- Lua syntax: **14/14 addon Lua files parsed successfully** with `/usr/bin/texlua`.
- Full Python suite: **217 passed, 28 failed**. Clean `git archive HEAD` parent baseline: **220 passed, 22 failed**. Existing failure set is retained; six additional test IDs currently fail due to release-manifest inventory/hash and legacy version-string assertions that still need reconciliation before handoff. No claim of a clean full suite is made.
- Forever 1.60.1 build 70938 runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Runtime acceptance

Install 1.0.3 on Forever build 70938 and reproduce the same sorting workload (including repeated All Items refreshes and sorting around the former `mage eye blunderbuss` case). Confirm:
1. No Lua error occurs.
2. The list completes sorting and remains populated.
3. Name, price, quantity and profit ordering remains correct.
4. Search/filter refreshes do not introduce missing rows or repeated sort restarts.

The historical nil-comparator defect remains **runtime-unverified** until this player-visible test passes.

## Status

**SOURCE FIX IMPLEMENTED; FOCUSED TESTS PASS; LUA SYNTAX PASS; FULL SUITE HAS BASELINE/INVENTORY FAILURES; FOREVER RUNTIME NOT RUN.**
