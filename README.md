# Modulo Market 0.11.6

**Current player milestone:** 0.11.6 restores learning-state row markers across every tab in both presentations, applies client item-quality colours to item names, and changes Market History to the latest three completed Full Market snapshots. Native item tooltips are restored on hover. Shift-click now inserts the real WoW item hyperlink into an active chat edit box, or fills the native Auction House Browse field when chat is not active. Snapshot search falls back to client-cached item names when the saved row name is absent. Both inspectors use the **Inspected Item** title and Blizz-like gains its own bordered item card; Turn-In column reads **REP / FAV**.

Artisan Waylaid Crate Favor and cash remain **UNKNOWN**: the current public Forever sources still do not publish these rewards. No Expert-tier or inferred payout is substituted. Search remains a search of the saved snapshot, not an implicit live AH query. The user's screenshot includes a Full Market client footer showing 0.11.4; that screenshot is useful defect evidence but is not acceptance evidence for 0.11.6.

Forever runtime acceptance for 0.11.6 is **NOT RUN**. Retail runtime is **NOT RUN**. See `MODULOMARKET-RUNTIME-AUDIT-0.11.6.md` and `docs/MODULOMARKET-ITEM-STATUS-QUALITY-HISTORY-INSPECTOR-0.11.6.md`.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable and use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- Both windows remain movable beyond the visible client viewport with saved positions and reset controls.
- Writ buy/craft routes, 150-entry catalogue, unknown-reward handling, variable Coin Pouch treatment and fail-closed market-depth rules remain.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- No optional addon dependency was added.


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
