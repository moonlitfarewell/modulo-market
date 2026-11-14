# Modulo Market 0.11.3

**Current player milestone:** Unified full-market scan controls across Blizz-like and Modern into a single stateful action (Scan Market → Confirm Scan → active/cooldown), moved Browse Scan diagnostics into addon settings, added custom Modern TGA icons and a skinned search field, fixed the profession dropdown default and history chart overlap, and limited displayed price history to the last three days. The 0.11.2 visual fixes remain preserved. Modern toolbar and dropdown affordances use client textures rather than unsupported Unicode glyphs; checkbox outlines and checked states are clearer in Modern and non-classic Blizz-like palettes; Modern rows restore the existing green/ yellow/red profession craft-status markers; the overflowing Materials/History filter hint is removed; and Turn-In Required Bundles now has a structured, independently scrollable breakdown with crate cost, alternatives, BEST VALUE, ingredient quantities, unit/line costs and subtotals. The existing Blizz-like window and all Modern window functions remain. Both presentations continue to use the same market data, calculations, scanning pipeline and SavedVariables.

Forever runtime acceptance for these corrections is **NOT RUN**. See `MODULOMARKET-RUNTIME-AUDIT-0.11.3.md` and `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md`.


## Existing capabilities

See the historical milestone notes and audits below for the preserved market, economics, professions, materials, turn-in and history capabilities.

## 0.11.1 — separate Modern window foundation

0.11.1 retained the established WoW-style interface as Blizz-like and introduced an independent Modern window with its own chrome, toolbar, navigation, filters, table, inspector and history presentation. Both windows consume the same market state and scanner actions. The 0.11.0 legacy Modern colour treatment migrated into the Blizz-like styles. See `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md` and `MODULOMARKET-RUNTIME-AUDIT-0.11.1.md`.

## 0.11.0 — historical theme foundation

0.11.0 introduced the first settings page and the colour treatments that are now retained under the Blizz-like window. The 0.11.1 architecture separates those treatments from the new Modern window. See `docs/MODULOMARKET-THEMES-0.11.0.md` and `MODULOMARKET-RUNTIME-AUDIT-0.11.0.md`.
