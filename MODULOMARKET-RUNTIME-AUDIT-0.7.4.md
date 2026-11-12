# ModuloMarket Runtime Audit 0.7.4 — Enter-triggered tooltip search and queue watchdog

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.3.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

In 0.7.3, searching a tooltip effect such as `heal` could remain at “Loading descriptions…” with an empty result list. The player supplied a Forever 70888 screenshot showing this state. The runtime defect remains open.

## Source diagnosis and competing hypotheses

1. **Excessive work on each keystroke:** confirmed design issue. Before this slice, every text change scheduled a catalogue search, and each non-name match could request tooltip data.
2. **Item-data request lifecycle did not complete:** plausible and not yet runtime-proven. The prior source marked an ID requested before verifying the request API was available; its fallback called `GetItemInfo`, which does not provide a dependable explicit asynchronous request contract.
3. **Warmup watchdog starvation:** plausible lifecycle issue. The prior update loop used an `elseif` work queue, so another continuously active queue could prevent the warmup timeout from being serviced.

The screenshot does not establish which runtime hypothesis was responsible for the observed permanent loading state. This slice adds diagnostics to distinguish them.

## Player-visible changes

- Typing searches names, recipe names, professions, IDs and reagents only; it does not initiate tooltip-description requests.
- Pressing Enter submits the expanded tooltip/effect search.
- Immediate name/reagent matches are rendered while tooltip descriptions load; the final pass adds tooltip-only matches.
- Existing normalized tooltip cache is reused.
- Item-cache state is checked where `C_Item.IsItemDataCachedByID` is available.
- The addon no longer treats a `GetItemInfo` call as proof that an asynchronous request was started when `C_Item.RequestLoadItemDataByID` is absent. Such items fail closed at the warmup deadline.
- Warmup watchdog is serviced independently of the other update queues.
- `/mmsearchdebug` reports submitted searches, requests, completion events, cache hits, failures, timeouts, completion count, pending/outstanding items and the last request error.
- Existing `heal`/`spell damage` tooltip matching remains the expanded-search path.

## Ownership and scope

- ModuloMarket remains an optional child addon depending on MODULO. MODULO remains unchanged and does not depend on ModuloMarket.
- No ForeverDB data, importer, credentials, recipe source evidence, market snapshot, pricing, account/character scope or other tabs were changed.
- No manual player-maintained state was introduced.

## Verification

- Focused Python regression tests: **7 passed** (`tests/test_modulomarket_0_7_4_search_submit.py`).
- Lua syntax: all **9 addon Lua files parsed successfully** with `texlua` and `loadfile`.
- Manifest JSON: PASS. Core, TOC and manifest version agreement: **0.7.4**.
- Manifest inventory: **137 listed files**, including the manifest; `file_count=136` excludes the manifest itself.
- Parent MODULO 1.0.48 ZIP integrity: PASS; unchanged.
- GitHub update ZIP: 137 entries; CRC PASS; fresh extraction and byte-for-byte manifest inventory comparison PASS.
- Historical source tests pinned to 0.7.0/0.7.3 contain version-specific assertions and are superseded; they are not counted as current 0.7.4 passes.
- Forever runtime: NOT RUN. The player must test on Forever 1.60.1 build 70888.

## Player acceptance

1. Typing `heal` updates name/reagent matches without showing “Loading descriptions…” and without issuing tooltip requests.
2. Press Enter; the expanded search loads descriptions and finds matching tooltip effects.
3. Search `spell damage`; results settle and remain stable.
4. While expanded search is running, change the query; the old search must not overwrite the new query.
5. A missing/failed item-data request must not leave the UI in a permanent loading state.
6. If a search fails, run `/mmsearchdebug` and provide the output.
7. No Lua errors, freezes, taint or broken UI interactions.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN. Keep the runtime defect open until the player-visible acceptance passes.
