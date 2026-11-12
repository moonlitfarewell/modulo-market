# ModuloMarket Runtime Audit 0.7.1 — search responsiveness

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.0.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE CHECKS PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

Tooltip-description search (for example, `healing`) felt very laggy on the full catalogue. The Crafts panel could remain on a `Filtering N/2175…` progress message while the search was processing.

## Evidence and diagnosis

The 0.7.0 source was inspected in `MarketUI.lua`:

1. The search EditBox `OnTextChanged` handler called `UI.StartViewBuild()` immediately. Each typed character therefore discarded the in-progress view and started another full catalogue pass.
2. Both `ITEM_DATA_LOAD_RESULT` and `GET_ITEM_INFO_RECEIVED` could cause an immediate `UI.StartViewBuild()` for each requested item. A burst of item-data completions could repeatedly restart the same catalogue search.
3. Tooltip text was cached as raw text and normalized again on every cache hit.
4. Tooltip extraction was already bounded to 60 inspections per filtering frame and item-data requests to 20 per frame. These bounds were retained.

The first two mechanisms are directly established by source inspection and explain redundant work. Their exact contribution to the user's observed frame-time lag is not measurable without a live client profiler; no client trace was supplied.

## Competing hypotheses and distinguishing evidence

- **H1 — repeated rebuilds:** each keystroke and item-load event restarts the catalogue pass. Source confirms both immediate restart paths; the new scheduler removes them.
- **H2 — per-item tooltip extraction is intrinsically too expensive:** `SetItemByID` and tooltip font-string reads may still be costly on Forever. The source confirms bounded extraction remains in the filtering path, but only in-client profiling can establish its remaining cost.

The offline regression tests verify the debounce and event-coalescing paths. A live before/after timing or frame trace is still required to distinguish the residual impact of H2.

## Changes in 0.7.1

- Debounce text edits by 0.25 seconds; cancel stale filter/sort work while the player is typing.
- Coalesce successful item-data completion notifications into a single refresh after a 0.30-second quiet window.
- Do not let a tooltip-load refresh interrupt an active typing debounce.
- Store normalized tooltip text in the cache, avoiding repeated normalization on cache hits.
- Preserve item-name, recipe-name, profession, ID, reagent and tooltip-description/effect matching.
- Preserve asynchronous item-data requests and the existing bounded work limits (20 requests and 60 tooltip inspections per filtering frame).
- No recipe catalogue, acquisition-source, market snapshot, pricing, profession-scope or ForeverDB content changes.

## Ownership and scope

ModuloMarket remains a separate optional addon depending on MODULO. MODULO does not depend on ModuloMarket. Parent MODULO 1.0.48 is unchanged. No external addon runtime dependency or API credential was added.

## Verification performed

- Focused current-feature/regression tests: **23 passed**.
- Lua syntax: all **9 addon Lua files parsed successfully** with `loadfile` through `texlua --luaonly`.
- Manifest JSON parse: PASS.
- Full historical pytest suite: **172 passed, 50 failed**. The failures are retained as historical suite failures; they include stale assertions for superseded tab names, old layout contracts and old pinned versions. They are not counted as passes or silently removed. The focused 0.7.1 tests and directly relevant 0.7.0/0.6.9/0.6.8 regression suites pass.
- Package ZIP CRC, fresh extraction, manifest inventory, version agreement and SHA-256 are recorded in the handoff after packaging.

## NOT RUN / UNKNOWN

- Forever client runtime performance: **NOT RUN**.
- Actual reduction in typing latency/frame time on Forever build 70888: **UNKNOWN** until the player retests.
- Forever tooltip extraction and item-data event cadence: still dependent on target-client behavior.
- Search recall for representative `healing` and `spell damage` queries: source path preserved, but live acceptance is still required.
- Retail runtime: NOT RUN.

## Player acceptance checklist

1. In Crafts, type `healing` and confirm the interface remains responsive and results appear after the short typing pause.
2. Search `spell damage` and confirm tooltip-effect matches are returned even when the item name does not contain those words.
3. Type a multi-character query while item data is loading; the filter must not restart once per character or once per item-load event.
4. Clear the search and switch tabs/filters; no stale results or delayed old query may replace the current view.
5. No Lua errors, freezes, taint or broken interactions.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE CHECKS PASS; HISTORICAL SUITE 172 PASS / 50 FAIL; FOREVER RUNTIME NOT RUN. Keep the performance defect open until player-visible acceptance passes on the target client.

## Package handoff verification

- GitHub update archive: `ModuloMarket-GitHub-Update-0.7.1.zip`
- Archive root: `modulo-market/` (preserves the user's existing repository `.git` directory when extracted over it).
- ZIP CRC: PASS (`ZipFile.testzip()` returned no bad member).
- Archive inventory: 142 ZIP entries, 133 files; manifest lists 133 files and exactly matches the extracted file inventory.
- Fresh extraction: PASS; recursive comparison against the packaged source tree reported no differences.
- Addon/TOC/manifest version agreement: 0.7.1 / 0.7.1 / 0.7.1.
- Archive size: 1,862,998 bytes.
- SHA-256: `31a4ed44d914e2b004b294e95bac000c683a6073a4c661759a428bcc7b822b2d`.
- Parent source archive `MODULO-Project-Source-1.0.48.zip`: CRC PASS, 506 entries, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; unchanged.
- Previous child archive `ModuloMarket-GitHub-Update-0.7.0.zip`: CRC PASS, 139 entries, 1,675,734 bytes, SHA-256 `02c4afece897088896dde5fb35dc3779c5ed43779ea593496e0dd7466eeef4b5`.

**Package command:** `zip -qr /mnt/data/ModuloMarket-GitHub-Update-0.7.1.zip modulo-market` from `/mnt/data/mm070_triage`. Fresh extraction was performed with `unzip -q` and compared using `diff -qr`.
