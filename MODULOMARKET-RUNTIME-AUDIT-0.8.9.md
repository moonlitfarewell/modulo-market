# MODULOMARKET RUNTIME AUDIT 0.8.9

## Scope and player-visible result
Fix the red filter dropdown controls observed in the user's 0.8.8 Forever screenshot. The dropdowns must render as dark inset controls with bronze/gold edges, consistent with the rest of Dark Foundry.

## Evidence and diagnosis
- User-provided screenshot: ModuloMarket 0.8.8 on Forever 1.60.1 build 70938 shows Profession, Item Role, Item Types and Crafting Scope dropdowns with bright red backgrounds. The rest of the three-panel interface renders.
- Source inspection: `CreateDropdown` creates `UIPanelButtonTemplate` buttons and applies the custom `control` skin. `ApplyMarketButtonSkin` sets a dark custom fill, but leaves inherited normal/pushed/highlight template textures visible at non-zero alpha. The Forever client's inherited template artwork is red. This is the root cause supported by both source and screenshot.
- Competing possibility: the custom fill palette itself is red. Rejected by source: `control` fill is `(0.025, 0.022, 0.017, 0.98)`; the red fill branch applies to other styles. Suppressing only inherited template textures is the smallest fix.
- No runtime instrumentation was needed because the visual defect is attributable to a specific template-layering mismatch; runtime acceptance is still required after installation.

## Implementation
- For `control` style only, inherited normal, pushed and highlight template textures are set to alpha 0; disabled template texture alpha is also 0.
- Keep the dark custom fill, gold bevel, custom highlight, dropdown arrow, popup, option selection, disabled-option handling and callbacks.
- No other button styles changed.

## Ownership and boundaries
- ModuloMarket owns its presentation; no parent MODULO code or optional addon dependency changed.
- No changes to market calculations, recipe/gathering data, scan behavior, SavedVariables, six-tab structure, or source attribution.
- No new APIs, dependencies, data sources, or network behavior.

## Validation
 
- Focused dropdown regressions: 3 PASS.
- Full suite: `python -m pytest -q` — 240 PASS / 61 historical failures. Compared with 0.8.8, three additional tests pass and the historical failure count is unchanged. Ten stale current-release version assertions were advanced to 0.8.9.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
- Forever client runtime: NOT RUN. Screenshot evidence applies to 0.8.8 only.
- Fresh extraction: PASS. Manifest inventory: 173/173 files match the extracted tree. ZIP CRC: PASS (`ZipFile.testzip()` returned `None`). Fresh-extraction full suite: 240 PASS / 61 historical failures.
