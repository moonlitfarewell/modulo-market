# Modulo Market 0.11.5

**Current player milestone:** This slice tightens the market navigation and Turn-Ins experience. Market History is strictly limited to the rolling last 72 hours (up to four completed snapshots inside that window). Both tab rails now use compact fixed geometry. Waylaid Crate rows carry an explicit `crate` type, fixing the empty type-filter result. The Category / Profession dropdown now presents only crate categories or Writ professions according to Turn-In Type. The Turn-Ins columns are now Turn-In Item, Cost, Gross, Rep / Favor and Net / Reward; reward values display `Fav` and `Rep`, with the Writ inspector using `Reputation` and no visible reported marker. The Modern title is centred without the M mark, and the redundant toolbar Close button is removed while the standard title-bar X remains.

Shift-clicking an item row's icon or name in either presentation fills and focuses the native Classic Auction House Browse search field when the Auction House is open. It does not submit the search or intercept chat item-link insertion. A new white circular refresh TGA replaces the previous icon.

Writ reputation data remains community-sourced in the underlying records and audit provenance; this UI slice removes the visible asterisk / "reported" label at the user's request, but does not upgrade the evidence to FOREVER OBSERVED or FOREVER VERIFIED. Five Writ recipe outputs remain incomplete; variable Coin Pouch returns remain excluded from calculations.

Forever runtime acceptance for 0.11.5 is **NOT RUN**. Retail runtime is **NOT RUN**. See `MODULOMARKET-RUNTIME-AUDIT-0.11.5.md` and `docs/MODULOMARKET-TURNINS-AND-AH-SEARCH-0.11.5.md`.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable and use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- Both windows remain movable beyond the visible client viewport with saved positions and reset controls.
- Writ buy/craft routes, 150-entry catalogue, unknown-reward handling, variable Coin Pouch treatment and fail-closed market-depth rules remain.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- No optional addon dependency was added.

## 0.11.4 — movable windows and Craftsman's Writs

Introduced movable/persisted windows, settings scroll containment, visible checkboxes, normalized inspector values, Artisan UNKNOWN correction and the Writ catalogue. See `docs/MODULOMARKET-WINDOWS-AND-WRITS-0.11.4.md`.

## 0.11.3 — scan and Modern controls

Unified scan controls, custom Modern TGA icons, search field, profession dropdown default, three-day history and Browse Scan settings launcher. See `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md`.

## 0.11.1 — separate Modern window foundation

Introduced the independent Modern window while preserving the existing Blizz-like appearance. See `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md`.

## 0.11.0 — historical theme foundation

Introduced the first settings page and retained colour treatments now under the Blizz-like window. See `docs/MODULOMARKET-THEMES-0.11.0.md`.
