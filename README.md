# Modulo Market 0.11.4

**Current player milestone:** Both Blizz-like and Modern windows can be dragged beyond the visible game viewport, with saved positions and a settings-page reset action. Inspector metric values now use the accepted Turn-In Economics body font size; the settings page is scroll-contained; Modern and Blizz-like checkboxes receive visible checked marks. The Turn-Ins tab now contains all 30 Waylaid Crates and 150 distinct Craftsman's Writs, with a type filter, tier/profession filters, Writ purchase prices, buy/craft alternatives, community-reported tier reputation (marked with an asterisk) and variable coin-pouch notes. Artisan crate reputation remains UNKNOWN rather than being shown as a false zero.

Writ recipe materials are resolved against the bundled ForeverDB 1.60.1.70938 recipe catalogue and existing learned-recipe snapshots. 145 of the 150 Writ outputs currently match a recipe record with reagent groups; five remain explicitly incomplete. Variable coin-pouch observations are not treated as guaranteed cash and are not deducted from Cost / Rep. Expert reward reports conflict, so reputation values are marked as reported and should be checked against the in-game quest text.

Forever runtime acceptance for 0.11.4 is **NOT RUN**. Retail runtime is **NOT RUN**. See `MODULOMARKET-RUNTIME-AUDIT-0.11.4.md` and `docs/MODULOMARKET-WINDOWS-AND-WRITS-0.11.4.md`.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable.
- Both windows continue to use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- Existing market tabs, filters, sorting, history and crate material alternatives remain.
- No optional addon dependency was added.

## 0.11.3 — scan and Modern controls

Unified scan controls, custom Modern TGA icons, search field, profession dropdown default, three-day history and Browse Scan settings launcher. See `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md` and its runtime audit.

## 0.11.1 — separate Modern window foundation

Introduced the independent Modern window while preserving the existing Blizz-like appearance. See `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md`.

## 0.11.0 — historical theme foundation

Introduced the first settings page and retained colour treatments now under the Blizz-like window. See `docs/MODULOMARKET-THEMES-0.11.0.md`.
