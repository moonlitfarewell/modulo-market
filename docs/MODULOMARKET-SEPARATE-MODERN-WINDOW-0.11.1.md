# Modulo Market — separate Modern window 0.11.1

## Player problem and observable result

0.11.0 incorrectly treated Modern as an accent-colour skin on the established Blizzard-style window. The player clarified that the Blizz-like window and its colour treatments must remain, while Modern must be a separate interface with different window chrome, controls, borders, navigation and layout. Both presentations must show the same market data and preserve the same functionality.

0.11.1 introduces two independent presentation windows:

- **Blizz-like:** the existing `ModuloMarketMainFrame` and established six-tab WoW-style layout. It retains four visual treatments: Classic gold, Dark grey, Class colour and Custom colour.
- **Modern:** a new `ModuloMarketModernFrame` with its own title treatment, top toolbar, opacity slider, tab navigation, filter panel, virtualized market table, selected-item inspector cards and market-history graph. It has independent Dark, Class and Custom accent choices.

The product remains named Modulo Market. `/mm`, the minimap launcher and the settings-page Open button open the selected presentation.

## Canonical provenance and available evidence

- Sole source baseline: user-provided `ModuloMarket-GitHub-Update-0.11.0.zip`.
- Baseline SHA-256: `eb27937484ce78da22fdc3033a3bc9d88fa552abaa047a656e0e07551c9ed36c`.
- Baseline bytes: 2,428,486.
- Baseline ZIP CRC: PASS (`testzip() == None`).
- Baseline archive entries: 225 including the root directory; 224 files.
- Baseline `MANIFEST.json` file inventory: 224 entries, matching extracted file inventory.
- Baseline `Core.lua`, TOC, `TurnInData.lua`, README and JSON manifest agree on 0.11.0.
- Baseline `MANIFEST.json` parent source hash is retained unchanged as provenance.
- `AddOns.zip` was available and its ZIP CRC passed (5,375 entries). Targeted references inspected: `EllesmereUIOptions/EllesmereUI_Widgets_Color.lua`, `Polestar/Theme/Widgets.lua` and `Modulo/Settings.lua`. Their settings and picker patterns informed the implementation; no dependency or copied addon runtime code was added.
- The 0.11.0 standalone audit and theme design document were read. The separate Modern window is an explicit correction to that implementation, not a reinterpretation of its prior runtime acceptance.
- No complete project chat history or external GitHub write confirmation is present in this working evidence; neither is reconstructed or claimed.

## Player problem, evidence and counter-evidence

**Problem:** players could not choose a truly modern layout; changing the previous 0.11.0 Modern setting only recoloured the old BasicFrameTemplateWithInset window.

**Evidence:** source inspection showed `MarketUI.lua` creates one `ModuloMarketMainFrame` with all tabs, filters, table rows, inspector and history. `Theme.lua` only recoloured registered surfaces on that same window. The user's screenshots showed the old WoW-style window remained structurally unchanged when the previous palette choices were selected.

**Counter-evidence/limits:** source and mocked tests cannot prove the exact Forever client will display every frame/widget, colour picker, scroll interaction or layout correctly. The new Modern window has not yet been installed and exercised on the target client.

## Architecture and ownership

- Owner: standalone ModuloMarket addon.
- `MarketUI.lua` remains the shared market data/state engine and the Blizz-like presentation.
- New `ModernUI.lua` creates the separate Modern presentation. It reads the existing `MarketUI` view rows and selected-item model and routes tab, search, filter, sort, selection, scan and browse actions back through shared `MarketUI` APIs.
- In Modern mode, the legacy UI frame is kept transparent and mouse-inert while its existing incremental catalogue, filtering, item-data warmup and refresh lifecycle continues to run. The Modern window owns the visible controls and presentation.
- `Theme.lua` now distinguishes the selected window (`marketAppearance`) from each window's palette. It migrates 0.11.0's colour-skinned `theme=modern` to the corresponding Blizz-like style, preserving the prior appearance. New installations default to Blizz-like Classic gold.
- No required/optional dependency was added. EllesmereUI, Polestar and other addons remain reference-only.
- Parent MODULO source is not changed.

## Observable implementation

### Blizz-like

- Existing `ModuloMarketMainFrame`, dimensions, Blizzard native chrome, six tabs, filters, table, inspector, Turn-In breakdown and history remain in place.
- Blizz-like style selector offers Classic gold, Dark grey, Class colour and Custom colour.
- The 0.11.0 theme registry still applies these treatments to the legacy window's registered surfaces.

### Modern

- Independent `ModuloMarketModernFrame`, custom outer frame/borders, title bar, accent rule and flat action buttons.
- Independent toolbar for market metadata, scan state, Update Full Market, Browse Scan, Close and window opacity.
- Independent six-tab navigation.
- Left-side search, profession, item-role and item-type selectors, crafting scope, data-build status and tab-specific quick filters.
- Separate scroll-frame and virtual row pool reading the shared `UI.viewRows`; row clicks select the same shared item model.
- Inspector cards mirror the shared MarketUI inspector state for item identity, market economics, relationship/bundle details and saved market history.
- Dark (neutral grey), Class and Custom palettes recolour Modern-owned textures and text. Custom RGB is stored separately from Blizz-like custom RGB.
- The legacy window remains callable through explicit `ShowBlizzlike`/`ToggleBlizzlike` APIs; `/mm` routes to the selected presentation.

## Dependencies, compatibility, security and scope

- Interface target remains 16001.
- Required dependency remains `Modulo`; optional dependency remains `LibProfessionDB`.
- No new protected action, automated scan, market request or network path is introduced.
- Existing auction snapshot, pricing calculations, recipe/economics/turn-in models, filters and market-history SavedVariables are not intentionally changed.
- Existing 0.11.0 SavedVariables are retained. The migration only adds presentation fields and maps the prior 0.11.0 palette to the Blizz-like style; no destructive reset is performed.
- Modern backend frame is transparent and mouse-inert while the separate Modern window is visible so the existing incremental catalogue and item-data event processing continue. This dual-frame lifecycle requires runtime validation.

## Competing risks and distinguishing diagnostics

1. **Shared data engine lifecycle:** the transparent legacy frame may not continue processing `OnUpdate` or item-data callbacks correctly on the target client. Diagnostic: open Modern on Forever, wait for catalogue preparation, change tabs/search, and compare counts/status against Blizz-like; verify scan completion and new snapshot refresh.
2. **Frame/input layering:** the transparent backend's child controls or registered `UISpecialFrames` entry may interfere with Modern input or Escape handling. Diagnostic: test all Modern controls, dropdowns, scroll wheel, row selection, drag, close/Escape, then switch to Blizz-like; check that no invisible control captures input.
3. **Presentation parity:** Modern inspector fields may fail to mirror some specialized recipe or Turn-In detail. Diagnostic: compare the same selected item/crate in both windows across all six tabs, especially recipe acquisition, material bundle breakdown and history.
4. **Palette repaint coverage:** some textures or font strings may retain their previous accent. Diagnostic: change Dark → Class → Custom while Modern is open and inspect frame chrome, tabs, filter controls, selected row, inspector and chart.

## Validation plan and acceptance criteria

- Existing Blizz-like default and all four Blizz-like styles render without loss of existing tabs/features.
- Modern opens as a separate frame with distinct title/window chrome, buttons, borders and layout; it is not merely the legacy window recoloured.
- All six tabs display shared catalogue rows and selecting a row updates the same selected-item model.
- Search, profession, role, item type, applicable tab filters, sorting, scrolling, selection, scanner and browse scanner controls work through shared MarketUI state.
- Inspector mirrors market, recipe, Turn-In and history data.
- Modern Dark/Class/Custom accent choices repaint Modern-owned surfaces and persist across reload; Blizz-like custom colour persists separately.
- Changing presentation while either window is open switches the visible window without resetting market state.
- `/mm`, minimap launcher and settings-page Open button route to the selected presentation.
- No new dependency; market calculations and scanner behavior remain unchanged.
- No new failing test IDs relative to the exact 0.11.0 source baseline.
- Forever and Retail runtime acceptance remain NOT RUN until tested on the corresponding clients.

## Explicit NOT RUN / UNKNOWN

- Forever 1.60.1 runtime: NOT RUN.
- Retail runtime: NOT RUN.
- Exact target-client input layering and hidden-frame `OnUpdate` behavior: UNKNOWN pending runtime test.
- Modern visual parity and complete inspector content across all tabs: UNKNOWN pending runtime test.
- GitHub remote write/push: NOT RUN; no remote update is claimed.
