# ModuloMarket UI Visual and Lifecycle Refinement 0.9.1

## Player problem and observable result
The 0.9.0 screenshot confirms the Dark Foundry UI is rendering on Forever 1.60.1 build 70938, but the player requested a broader coordinated refinement and reported that dropdown menus remain open after the main window closes. 0.9.1 combines the popup lifecycle fix with table and history-chart polish.

## Evidence and diagnosis
- Screenshot evidence: 0.9.0 on Forever 1.60.1 build 70938; table and inspector are visible, and the dropdown palette is dark/gold.
- Player runtime report: dropdown menus persist after the main window closes.
- Source evidence: dropdown popup frames are parented to `UIParent`, not the main frame; the parent window had no `OnHide` cleanup. Popup lifecycle is therefore independent.
- The child repository does not include its own complete project governance history; missing records are not reconstructed.

## Implementation
1. Track all custom dropdowns in `UI.dropdowns`.
2. Add a shared close-all routine and invoke it on main-window hide/show and before tab changes.
3. Close a dropdown's popup when its anchor control hides.
4. Add a dark table-header rail and restrained column guides.
5. Strengthen selected-row contrast and reduce alternating row colour noise.
6. Add a chart baseline and scale bar/label placement to the actual history graph height.

## Scope boundaries
- Preserve six tabs, filters, table sorting and row density, all dropdown choices and callbacks, saved price history, and current item selection behavior.
- No changes to market calculations, auction scanning, recipe/gathering data, acquisition-source evidence, SavedVariables or parent MODULO.
- My Crafts remains absent.

## Validation and player acceptance
- Focused tests: 12 PASS.
- Full suite: 252 PASS / 61 historical failures; identical 61 failing IDs to 0.9.0, zero new failures.
- Lua syntax: 9/9 PASS.
- Target-client runtime acceptance for 0.9.1: NOT RUN. 0.9.0 screenshot is FOREVER OBSERVED for 0.9.0 only.
- Install 0.9.1 and test dropdown dismissal through Close, Escape, tab switches and reopen; verify selection callbacks and visual layout.
