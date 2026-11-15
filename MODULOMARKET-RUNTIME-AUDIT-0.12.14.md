# Modulo Market 0.12.14 — Item-data event efficiency audit

**Date:** 2026-11-15  
**Source parent:** user-supplied `modulo-market.zip`, local `main` HEAD `d6b1f8a7e443586c28382ea9e619e9116035856e`  
**Parent addon version:** 0.12.13  
**Uploaded source ZIP SHA-256:** `ad0af83c984a1f708d1a1fed86bf47f0e92349eaa06ff544f7ac689e8851856c`

## Source provenance and local changes

The ZIP contains the full repository including `.git`. `HEAD` is `d6b1f8a7e443586c28382ea9e619e9116035856e` (`Update to Modulo-Market 0.12.13`) and branch `main` reports synchronized with `origin/main`. The uploaded working tree is not clean: three pre-existing modified files were present:
- `data/README.md`
- `tests/historical/test_modulomarket_0_11_0_themes.py`
- `tests/historical/test_modulomarket_0_11_1_themes.py`

Those three changes were preserved unchanged in the working copy. This handoff is a patch against that supplied local working tree, not a claim that the dirty changes are committed or part of the remote branch.

## Player problem / expected result

Freeloader sometimes attributes CPU spikes to Modulo Market when the player opens bags. Source inspection found that `MarketUI.lua` listened for both `GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT`; each notification invalidated caches, synchronously read vendor/class metadata, and immediately redrew the selected presentation. In Modern mode, the transparent legacy backend can remain shown while the Modern presentation itself is hidden, so testing only the backend frame's shown state would not establish that the player can see the window.

Two competing causes were considered:
1. Item-data event handling and repeated row rendering / metadata reads.
2. Background item-class warmup and filter-triggered rebuilds continuing while the Modern backend is shown but its visible presentation is closed.

The slice addresses both bounded code paths. It does not claim these are the only possible causes of every Freeloader spike.

## Implementation

- Cache invalidation remains immediate for item icon, quality, class, request/pending/failure and vendor-price state.
- If no actual presentation is visible, item notifications do not perform synchronous `ReadVendorInfo` / `GetItemClassID` calls and do not queue rendering. Normal item getters resolve metadata lazily when the player next opens Market.
- If a presentation is visible, item IDs are collected for a 120 ms coalescing window. If both legacy and modern item-data notifications arrive for one ID in that window, metadata is resolved once for that item.
- The active presentation is rendered once after the burst. The selected Classic item detail is refreshed only when its item ID is among the queued notifications.
- `StepItemClassWarmup` and its delayed item-type filter rebuild are gated on actual presentation visibility. This accounts for the transparent Modern backend frame that may remain shown while the Modern window is closed.
- No Replicate, snapshot persistence, pricing formula, profession data, minimap or settings behavior changed.

## Ownership / compatibility

This is Modulo Market-owned event and presentation scheduling. It uses existing Blizzard item-data events and the existing `Now()` clock; no new optional addon dependency or new Blizzard API is introduced. The 120 ms interval is a local batching window, not a claim about the client's event cadence.

## Verification

- Focused Python tests: **4 passed**.
- Lua harness extracted and executed the production event-handler block with mocked client APIs: **5 scenarios passed**:
  1. Hidden presentations invalidate caches without metadata reads or renders.
  2. A visible Classic burst coalesces duplicate event types by item ID and renders once.
  3. A selected Classic item refreshes details once.
  4. A visible Modern burst renders once.
  5. Hidden Modern presentation schedules no render.
- Full repository `pytest -q`: **178 passed, 31 failed**.
- Baseline `pytest -q` on the unmodified uploaded source: **172 passed, 33 failed**.
- Failure-ID comparison: **zero new failing test IDs**. Six additional passes come from updating the two historical item-event assertions and the current-version metadata assertions for the current source version.
- Lua syntax compile-only `loadfile` check across all 14 addon Lua files: **14/14 passed**.

The 33 remaining failures are pre-existing baseline failures in older milestone/version-specific tests; they were not introduced or silently reclassified as passing.

## Runtime evidence

**Forever runtime: NOT RUN. Retail/Mainline runtime: NOT RUN.** Offline tests establish that hidden-window metadata reads and repeated render calls are avoided in the mocked event flow. They do not establish actual Freeloader CPU reduction or client-side UI lifecycle behavior.

## Player acceptance / next diagnostic

On the same Forever client/build and with the same Freeloader profiling settings:
1. Reload with Modulo Market installed but never open Market; open/close bags several times and record Market CPU.
2. Open Market once, close it, then repeat the bag test.
3. Open Market visibly, open/close bags, and compare the visible-window cost.
4. Repeat with the Modern presentation selected and closed, because its transparent backend frame remains shown.

Compare the same Freeloader measurement window and report both CPU total and call count if available. If hidden-window spikes persist, inspect Freeloader's per-function breakdown before another code change.

## Exit

The source slice is complete and offline-tested. Keep the performance defect open until the player confirms that bag-opening spikes decrease in the target Forever client without stale icons, quality, vendor prices, item-class filters or selected-item details.
