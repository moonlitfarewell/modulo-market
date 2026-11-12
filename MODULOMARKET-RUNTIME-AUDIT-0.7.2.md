# ModuloMarket Runtime Audit 0.7.2 — search restart correction

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.1.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE CHECKS PASS; HISTORICAL SUITE HAS LEGACY FAILURES; FOREVER RUNTIME NOT RUN.

## Player problem and observable failure

After installing 0.7.1, searching `heal` in Crafts repeatedly cycled through `Waiting…`, `Filtering 1500/2175…`, and `0-0/0`. The results did not settle.

## Evidence and root-cause diagnosis

The supplied screenshot establishes the player-visible failure on client build 70888.

Inspection of 0.7.1 `MarketUI.lua` found this restart path:
- `ITEM_DATA_LOAD_RESULT` / `GET_ITEM_INFO_RECEIVED` schedule `tooltipRefreshDueAt`.
- The main `OnUpdate` handler consumed that timer and called `UI.StartViewBuild()` when the debounce was clear.
- It did not check whether `UI.viewBuild` or `UI.rankSort` was already active.
- A stream of tooltip item-load events could therefore clear and restart the active search repeatedly.

Two hypotheses were considered:
1. **Tooltip event refresh interrupts active filtering/sorting.** Directly confirmed by the source path above and matches the cycling progress screenshot.
2. **Another refresh source (recipe/filter changes) restarts the view.** Possible in principle, but not required to explain this failure; this is not ruled out as a separate future cause.

The distinguishing diagnostic is whether `StartViewBuild()` is invoked while `viewBuild` or `rankSort` is active without a user query/filter change. The 0.7.1 tooltip-refresh branch permitted this.

## Player problem / observable 0.7.2 result

The active search should reach a stable result count. Tooltip item-data arrivals must not discard the current filter or sort pass. Newly loaded tooltip data should be incorporated in a deferred follow-up pass.

## Ownership and scope

- ModuloMarket remains a separate optional addon depending on MODULO.
- MODULO 1.0.48 is unchanged and has no dependency on ModuloMarket.
- No ForeverDB content, importer, credentials, recipe acquisition records, pricing or account/character crafting-scope behavior is changed.
- The agreed presentation decision is included: `UNKNOWN` and `NOT LEARNABLE` both render red, while remaining distinct internal statuses.

## Implementation

- Keep `tooltipRefreshDueAt` pending while view filtering, rank sorting, catalogue construction or economics indexing is active.
- Consume the pending refresh only when the active work is idle and no typing debounce is pending.
- Start one follow-up build only when a non-empty search remains.
- Preserve the 0.25-second typing debounce, 0.30-second event coalescing, normalized tooltip cache and bounded tooltip request/inspection work.

## Verification performed

- Focused search regression tests: **7 passed**.
- Lua syntax: all **9 addon Lua files parsed successfully** with `texlua --luaonly` and `loadfile`.
- Manifest JSON parse: PASS.
- Version agreement: Core, TOC and manifest all **0.7.2**.
- Manifest inventory: PASS, 134 listed files including the manifest; package contains 134 files.
- Full historical pytest suite: **171 passed, 53 failed**. Failures are retained and not hidden; the failing set includes stale pinned-version assertions and superseded UI/layout/acquisition expectations from earlier slices. These are not counted as passes.
- ZIP CRC: PASS (`ZipFile.testzip()` returned no bad member).
- Fresh extraction: PASS; exact recursive file comparison matched the packaged source tree (excluding generated Python caches).
- GitHub update archive: `ModuloMarket-GitHub-Update-0.7.2.zip`.
- Archive size: **1,684,163 bytes**.
- SHA-256: `edfe98b369b8dc84a1d865b24f8fb5350a894baa4148edc92bbf30bf5e9d2863`.

## NOT RUN / UNKNOWN

- Forever 1.60.1 build 70888 runtime retest: NOT RUN.
- Actual in-client search responsiveness and tooltip-effect recall: UNKNOWN until player retests.
- No claim of Forever runtime verification is made.

## Player acceptance

1. In Crafts, search `heal`; the status must not cycle back to `Waiting…` or restart its progress while the query remains unchanged.
2. The search must reach a stable result count and return relevant tooltip-description matches where present.
3. Search `spell damage`; tooltip-only effect matching must remain available.
4. Clear the query, switch tabs and change profession filters; no stale query may overwrite the new view.
5. Unknown recipe status is red, like Not Learnable, while filter behavior remains distinct.
6. No Lua errors, freezes, taint or broken interactions.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE CHECKS PASS; HISTORICAL SUITE 171 PASS / 53 FAIL; FOREVER RUNTIME NOT RUN. Keep runtime defect open until player-visible acceptance passes.
