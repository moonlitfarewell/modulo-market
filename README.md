# Modulo Market 0.11.9

**Current player milestone:** 0.11.9 retains the 0.11.8 search lexical-scope fix and replaces 0.11.7's render-triggered asynchronous item-rarity loading with passive cached lookup. Item quality is coloured only when `GetItemInfo()` already exposes it; unavailable quality remains neutral white. Item-data completion events may refresh the active presentation, but the addon no longer requests item data merely to colour a row and no longer redraws both UI presentations for one event. Modern dynamic columns, centering, Shift-click dispatch, inspector headings and the Artisan reward schedule are retained. This is a diagnostic regression-isolation release; it does not yet establish that the hard hang is fixed.

Artisan Waylaid Crate rewards use the supplied category schedule: raw-material Artisan crates (Herbs, Ore, Textiles, Curiosities) return 20 Merchant's Favor and 10 Silver; processed-material Artisan crates (Fabrics, Ingots, Parts) return 40 Merchant's Favor and 20 Silver. This is 50 copper per Favor. Reputation remains unfilled because the supplied schedule did not specify a reputation amount.

The three-snapshot Market History, learning-state edge markers, native hover tooltips, pricing, scanner and SavedVariables structures remain preserved. See `MODULOMARKET-RUNTIME-AUDIT-0.11.7.md`. Forever runtime acceptance is **NOT RUN**; Retail runtime is **NOT RUN**.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable and use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- Both windows remain movable beyond the visible client viewport with saved positions and reset controls.
- Writ buy/craft routes, 150-entry catalogue, unknown-reward handling, variable Coin Pouch treatment and fail-closed market-depth rules remain.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- No optional addon dependency was added.


## 0.11.8 — search nil-call crash fix

The 0.11.7 search filter called `GetItemName` from `MatchesSearch` before the later `local function GetItemName` declaration entered lexical scope. Lua therefore treated the earlier reference as a global lookup. A non-empty text query such as `spire` raised `attempt to call a nil value` during incremental filtering. `GetItemName` is now forward-declared before `MatchesSearch` and assigned later into that local. The saved profile's BugGrabber stack and locals directly match this call path. No SavedVariables schema or search boundary changed. Offline regression coverage asserts the local binding order; Forever runtime acceptance remains NOT RUN.

## 0.11.7 — centered windows, native links, Modern column fit and Artisan payouts

Both windows center on each explicit `/mm` open. Visible item rows request missing item quality asynchronously and rerender on item-data completion. Shift-click now calls Blizzard's `ChatFrameUtil.InsertLink` dispatcher first, allowing the client to choose active chat hyperlink insertion or native Auction House name search. Modern numeric columns measure their current headers and visible values and align right across All Items, Economics, Crafts, Materials, Turn-Ins and History. Search reads `GetItemInfo` without a separate cache-probe gate and shows filtering/description warm-up progress. The Modern inner inspector card is titled `Selected Item`. Artisan Favor/cash use the supplied raw/processed category schedule. See `docs/MODULOMARKET-0.11.7-UX-AND-SEARCH.md`.

## 0.11.6 — item status, quality, history and inspection

Restored learning-state row markers on Crafts and Turn-Ins, applied client item-quality colours to every tab, changed history to three latest snapshots, restored native hover tooltips, corrected Shift-click to use native chat link insertion or native Auction House Browse fill, improved snapshot name fallback, and aligned the Blizz-like inspector card/title with Modern. Artisan Waylaid Crate payouts remain explicitly UNKNOWN because current public sources do not confirm them. See `docs/MODULOMARKET-ITEM-STATUS-QUALITY-HISTORY-INSPECTOR-0.11.6.md`.

## 0.11.4 — movable windows and Craftsman's Writs

Introduced movable/persisted windows, settings scroll containment, visible checkboxes, normalized inspector values, Artisan UNKNOWN correction and the Writ catalogue. See `docs/MODULOMARKET-WINDOWS-AND-WRITS-0.11.4.md`.

## 0.11.3 — scan and Modern controls

Unified scan controls, custom Modern TGA icons, search field, profession dropdown default, three-day history and Browse Scan settings launcher. See `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md`.

## 0.11.1 — separate Modern window foundation

Introduced the independent Modern window while preserving the existing Blizz-like appearance. See `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md`.

## 0.11.0 — historical theme foundation

Introduced the first settings page and retained colour treatments now under the Blizz-like window. See `docs/MODULOMARKET-THEMES-0.11.0.md`.
\n\n## 0.11.9 — passive rarity lookup and active-view refresh\n\nRemoved render-triggered `C_Item.RequestLoadItemDataByID` calls for rarity colours. Quality is read opportunistically from the existing client item cache, with neutral white when unavailable. Item-data completion refreshes only the currently selected presentation. This targets the most suspicious new 0.11.7 event/render workload while preserving the requested visual feature wherever cached data exists. See `MODULOMARKET-RUNTIME-AUDIT-0.11.9.md`.\n