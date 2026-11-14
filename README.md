# Modulo Market 0.11.7

**Current player milestone:** 0.11.7 centres both windows whenever `/mm` opens them, restores asynchronous WoW item-rarity colours on visible rows, and uses Blizzard's `ChatFrameUtil.InsertLink` dispatcher for native item hyperlink/chat and Auction House search behaviour. Modern numeric columns are measured from visible row values and headers, right-aligned, and leave the remaining width to the left-aligned Item/Recipe column. Search now reads the legacy client item cache even when the separate C_Item cache probe says data is not cached, and Modern exposes filtering/tooltip-warmup progress instead of appearing stuck at `0 / 0`. The inspector's outer heading is **Inspected Item** and its inner item card is **Selected Item**.

Artisan Waylaid Crate rewards use the supplied category schedule: raw-material Artisan crates (Herbs, Ore, Textiles, Curiosities) return 20 Merchant's Favor and 10 Silver; processed-material Artisan crates (Fabrics, Ingots, Parts) return 40 Merchant's Favor and 20 Silver. This is 50 copper per Favor. Reputation remains unfilled because the supplied schedule did not specify a reputation amount.

The three-snapshot Market History, learning-state edge markers, native hover tooltips, pricing, scanner and SavedVariables structures remain preserved. See `MODULOMARKET-RUNTIME-AUDIT-0.11.7.md`. Forever runtime acceptance is **NOT RUN**; Retail runtime is **NOT RUN**.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable and use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- Both windows remain movable beyond the visible client viewport with saved positions and reset controls.
- Writ buy/craft routes, 150-entry catalogue, unknown-reward handling, variable Coin Pouch treatment and fail-closed market-depth rules remain.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- No optional addon dependency was added.


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
