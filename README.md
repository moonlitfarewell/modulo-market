# Modulo Market 0.11.1

**Current player milestone:** Added a genuinely separate Modern Modulo Market window. The established WoW-style window remains the **Blizz-like** presentation and retains its Classic gold, Dark grey, Class colour and Custom colour treatments. **Modern** is a second window with its own chrome, toolbar, navigation, filter controls, market table, inspector cards and history chart. Both windows use the same market data catalogue and underlying market state, selected-item state, filters, calculations, scanner actions and saved market data. The settings page selects Blizz-like or Modern and exposes the relevant palette controls; `/mm` opens the selected presentation.

The 0.11.0 `theme=modern` setting is migrated to the equivalent Blizz-like colour treatment (Dark, Class or Custom) so the previous appearance is preserved when upgrading. New installations default to Blizz-like Classic gold. Modern offers a neutral grey Dark palette, current WoW Class colour and an independently persisted Custom RGB accent. These are presentation-only changes. No market data, price calculations, auction scanning, recipe data, turn-in data, history storage or addon dependencies changed.

Forever and Retail runtime acceptance for the separate Modern window is **NOT RUN**. See `MODULOMARKET-RUNTIME-AUDIT-0.11.1.md` and `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md`.

## Existing capabilities

See the historical milestone notes and audits below for the preserved market, economics, professions, materials, turn-in and history capabilities.

## 0.11.0 — historical theme foundation

0.11.0 introduced the first settings page and the colour treatments that are now retained under the Blizz-like window. The 0.11.1 architecture separates those treatments from the new Modern window. See `docs/MODULOMARKET-THEMES-0.11.0.md` and `MODULOMARKET-RUNTIME-AUDIT-0.11.0.md`.
