# ModuloMarket Runtime Audit 0.7.7 — debounced tooltip search and Sell-only Auction House launcher

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.7.6.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS PASS; CHANGED-FILE LUA SYNTAX PASS; PACKAGE INTEGRITY PASS; FOREVER RUNTIME NOT RUN.

## Player problems and evidence

1. The player wants tooltip/effect search to update without pressing Enter. The supplied 0.7.6 sequence showed `/mm` opening normally, typing `spirit` without Enter showing only Egg Nog, and submitting with Enter showing additional matches including Wicked Smoothie. The existing 0.7.6 contract deliberately enabled tooltip/effect matching only on Enter, so this is expected from that implementation rather than proof the tooltip API is broken.
2. The ModuloMarket launcher overlaps Auctionator and Blizzard controls on multiple Auction House views. The supplied screenshots show the launcher on Buy, Sell, Auctions, Shopping, Selling, Cancelling and Auctionator surfaces. The requested scope is only Blizzard's native Sell tab.

## Player problem, observable result, and implementation

### Search

- Start the expanded search automatically 0.35 seconds after the last user keystroke.
- Keep Enter as an immediate-submit shortcut.
- Keep the existing normalized tooltip cache and async item-data readiness gate.
- Bound work more conservatively: at most 30 tooltip inspections per frame, 10 item-data requests per frame and 10 warmup item visits per frame.
- Increment a search generation on edits/submission. A view or warmup belonging to an older generation exits without publishing stale results.
- Keep the one-pass catalogue filter, pending-item warmup and one final pass; item-data events do not trigger per-item whole-catalogue restarts.

### Auction House launcher

- Attach only to the classic Blizzard `AuctionFrame`.
- Show only when Blizzard's native selected tab is tab 2 (Sell) and that native tab is visible.
- Hook native tab clicks and re-evaluate visibility after the tab selection settles.
- Hide on all other tabs and when the Auction House frame hides. Unknown/unreadable selection fails closed (button hidden).
- Do not attach to `AuctionHouseFrame` or Auctionator-owned surfaces.

## Competing hypotheses and diagnostics

### Search responsiveness

1. **Repeated work caused by text-change or item-data event restarts.** The current source already debounces text edits, bounds catalogue filtering, coalesces tooltip item loads and avoids per-item full-search restarts. The new generation token and stricter per-frame caps further constrain stale/repeated work.
2. **One large bounded batch still causes perceptible frame-time spikes on the target client.** Offline tests cannot measure actual client frame time or API cost. Distinguish these with in-game `/mmsearchdebug`, observing request/event counts and result settling while typing; compare UI responsiveness and whether a query completes without repeated `Waiting`/`Filtering` cycles. If typing causes lag/freezes, the agreed fallback is explicit Enter submission, not increasing batch sizes.

### Auction House tab detection

1. **Blizzard native tab selection is available through `PanelTemplates_GetSelectedTab(AuctionFrame)` or `AuctionFrame.selectedTab`.** The Sell tab is index 2; visibility is additionally checked.
2. **Auctionator or this client build changes the tab state/visibility in a way that makes the native selection ambiguous.** The implementation fails closed, so the button may be absent rather than overlap other tabs. Distinguish by testing native Sell, Buy, Auctions and each Auctionator view on build 70888. If Sell fails to display, inspect the live selected-tab value and tab visibility before changing detection.

## Ownership, dependencies, scope

- ModuloMarket remains a separate optional child addon depending on MODULO.
- MODULO 1.0.48 is unchanged and does not depend on ModuloMarket.
- No Auctionator source or dependency is changed; Auctionator is only a UI coexistence target.
- No SavedVariables schema, ForeverDB data, auction snapshot, recipe data, pricing formula or API credential behavior is changed.

## Offline acceptance

Recorded offline verification:

- Focused regression tests: `python -m pytest -q tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py` — **6 passed**.
- Changed Lua syntax: `texlua /tmp/mm_syntax.lua` using `loadfile()` for `Core.lua` and `MarketUI.lua` — **PASS**.
- Manifest inventory: **143 files**, exact agreement with working tree.
- ZIP: **143 entries**, all under `modulo-market/`; `ZipFile.testzip()` — **PASS**.
- Archive SHA-256 and size are recorded in the handoff.
- Historical version-pinned tests for 0.7.4–0.7.6 were not treated as current acceptance; their hard-coded expected versions naturally fail after version advancement. The 0.7.6 focused test also passes its three behavior assertions; its version assertion is historical.

Offline/static tests cannot prove client responsiveness, correct live Auctionator tab identification, absence of UI overlap or tooltip matching on Forever.

## Forever runtime acceptance — NOT RUN

1. Open `/mm`, choose Crafts / Cooking, type `spirit`, do not press Enter. After approximately 0.35 seconds, the tooltip search should progress automatically and Wicked Smoothie should appear because its tooltip grants Spirit. Results must settle; no repeated whole-search cycling, UI freeze or Lua error.
2. Type `healing` and `spell damage` without Enter. Tooltip-only matches should appear after warmup.
3. Type a query and quickly replace it. Old results/work must not overwrite the new query.
4. Press Enter while a query is waiting. Search should start immediately and must not duplicate the prior scan.
5. Use `/mmsearchdebug` to capture searches, requests, events, cache hits, pending/outstanding counts, completion and timeout status.
6. Open the Auction House. The ModuloMarket launcher must appear on Blizzard's native Sell tab only.
7. Visit Buy, Auctions, Auctionator Shopping, Selling, Cancelling and Auctionator Info. The launcher must be hidden on each.
8. Return to native Sell. The launcher must reappear once, in the intended header position, without overlap.
9. Confirm no Auctionator/Blizzard control is displaced, no Lua errors occur and all tabs remain usable.

**Fallback rule:** If automatic debounced search causes unacceptable lag, freeze, repeated work or unstable results on the target client, switch the search trigger back to Enter-only while retaining the cache, bounded warmup and generation safeguards.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE VERIFICATION PENDING; FOREVER RUNTIME NOT RUN. Both player-visible behaviors remain open until tested in the Forever client.
