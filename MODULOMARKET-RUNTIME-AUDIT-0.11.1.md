# Modulo Market 0.11.1 — separate Modern window capability audit

## Result

**SEPARATE MODERN WINDOW SOURCE IMPLEMENTED · OFFLINE TESTS PASS · RETAIL RUNTIME NOT RUN · FOREVER RUNTIME NOT RUN**

0.11.1 corrects the 0.11.0 interpretation. The previous 0.11.0 Modern colour treatment is retained as a Blizz-like style, and a genuinely separate Modern window is added. The new window reads the existing MarketUI data/state engine rather than creating a second market engine.

## Canonical baseline and provenance

- Sole baseline: user-provided `ModuloMarket-GitHub-Update-0.11.0.zip`.
- Baseline SHA-256: `eb27937484ce78da22fdc3033a3bc9d88fa552abaa047a656e0e07551c9ed36c`.
- Baseline bytes: 2,428,486.
- Baseline ZIP CRC: PASS; archive entries 225 including root folder; 224 files.
- Baseline `MANIFEST.json` file inventory exactly matched the 224 extracted files.
- Baseline addon code, TOC, TurnInData, README and manifest version: 0.11.0.
- Parent MODULO provenance remains 1.0.48 and is retained in the child manifest.
- `AddOns.zip` CRC: PASS; 5,375 entries. Targeted references inspected: EllesmereUI colour widgets, Polestar colour-picker callbacks and MODULO settings-category registration. No runtime dependency or copied addon package was introduced.

## Player problem and observable result

The player clarified that the old Blizz-like window must remain intact, while Modern must be a separate window with a different design, controls, borders, chrome and layout. Both presentations must use the same data and functionality.

0.11.1 now provides:

- **Blizz-like:** the existing WoW-style `ModuloMarketMainFrame`, preserving its layout and Classic gold, Dark grey, Class colour and Custom colour treatments.
- **Modern:** a new `ModuloMarketModernFrame` with independent frame chrome, title bar, toolbar, tab navigation, filter controls, virtualized market table, inspector cards and history chart.
- `/mm`, minimap launcher and settings-page Open button route to the selected presentation.
- Modern palettes: Dark (neutral grey), current WoW Class colour and Custom RGB.

## Source evidence and design decisions

`MarketUI.lua` remains the source of market state, catalogue construction, filtering, item selection, calculations and scanner actions. `ModernUI.lua` creates a separate presentation and consumes shared view rows/selection via explicit `MarketUI` accessors. The old UI frame remains transparent and mouse-inert while Modern is open so its existing incremental build and item-data lifecycle can continue.

`Theme.lua` separates window choice from palette choice. It migrates 0.11.0 `theme=modern` to the matching Blizz-like style, including copying a prior custom accent into the new Blizz-like custom field. This preserves the old appearance instead of unexpectedly opening the new Modern interface after upgrade. New installs default to Blizz-like Classic gold.

The user-supplied screenshots and mockup establish the desired separate-window direction. AddOns.zip patterns informed the settings and colour picker controls but are not dependencies.

## Scope and ownership

- Owner: standalone ModuloMarket addon.
- Added `AddOns/ModuloMarket/ModernUI.lua`; updated `MarketUI.lua`, `Theme.lua`, TOC, Core version, TurnInData version, README, manifest and tests.
- No parent MODULO files changed.
- Required dependency remains `Modulo`; optional dependency remains `LibProfessionDB`.
- Pricing, auction snapshot, scanner, recipe catalogue, profession data, materials, Turn-In calculations, history SavedVariables and market calculations were not intentionally changed.

## Risks and competing hypotheses

1. **Hidden backend lifecycle:** the transparent legacy frame may not continue `OnUpdate`, item-data warmup or incremental builds as expected on the exact Forever client. Diagnostic: use Modern and compare row counts, search results, tabs and status to Blizz-like; wait for catalogue build and perform a new full scan.
2. **Input/frame layering:** hidden legacy child controls or `UISpecialFrames` may interfere with Modern input/Escape handling. Diagnostic: exercise search, dropdowns, checkboxes, sorting, scroll wheel, row selection, dragging, close/Escape and presentation switching; confirm no invisible control captures input.
3. **Inspector parity:** specialized recipe/Turn-In details may not all fit or mirror perfectly in the Modern cards. Diagnostic: compare the same recipe, material, market item and Waylaid crate in both windows, including Required Bundles and history.
4. **Theme repaint coverage:** some Modern textures/font strings may retain stale palette values. Diagnostic: change Dark → Class → Custom while Modern is open and inspect outer border, toolbar, tabs, filters, selected rows, inspector and graph.

## Verification

- Focused regression set: **40 passed**.
- Theme migration/palette Lua harness: **18 checks passed**.
- Separate Modern UI mock-frame harness: **12 checks passed**. This checks construction, tab routing, shared row selection, sorting, search, scan/browse actions and close behavior; it is not a WoW runtime test.
- Existing Turn-In Lua harness: **9 checks passed**.
- Lua syntax: **13/13 addon Lua files passed** with `texluac -p`.
- Full source suite: **309 passed / 87 failed / 396 total**.
- 0.11.0 source baseline: **306 passed / 87 failed / 393 total**. Exact failing test IDs: **87 unchanged; zero new failing IDs; three additional tests pass**.
- Archive validation, exact manifest inventory, version agreement and fresh extraction are recorded in the release handoff.

## Runtime evidence and acceptance

- Forever 1.60.1 runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.
- Settings category and colour picker client behavior: **NOT RUN**.
- Actual Modern window rendering, layout, mouse/scroll interaction, hidden-frame lifecycle and inspector parity: **NOT RUN**.
- No `FOREVER OBSERVED` or `FOREVER VERIFIED` claim is made.
- GitHub remote write/push: **NOT RUN**; this package is delivered locally.

## Acceptance checklist for installation

1. Existing 0.11.0 users retain their previous Blizz-like colour treatment after migration; new users default to Blizz-like Classic gold.
2. Settings page shows Blizz-like and Modern window choices and the relevant style/palette controls.
3. `/mm` opens the selected presentation; changing the selection while a window is open switches presentation without clearing market state.
4. Blizz-like retains its original layout and all existing functions.
5. Modern is visibly a separate window, not a recoloured legacy frame.
6. All six tabs, filters, sorting, search, scroll-wheel scrolling, row selection, scanner and browse actions work against shared market state.
7. Inspector details for market items, recipes, materials, Turn-Ins and history are present and readable.
8. Blizz-like and Modern custom RGB values persist independently across reload; picker cancel restores prior colour.
9. No Lua errors, protected-action errors, missing controls or invisible input blockers.
10. Repeat on Forever client and record screenshots/runtime evidence before closing acceptance.
