# ModuloMarket UI Visual Refinement 0.8.9 — dropdown skin correction

## Player problem and observable result
The user's 0.8.8 screenshot on WoW Forever 1.60.1 build 70938 shows Profession, Item Role, Item Types and Crafting Scope dropdowns rendered bright red, inconsistent with the Dark Foundry black/bronze/gold control language. The desired observable result is that all dropdown controls render with the intended dark inset surface and bronze/gold bevel.

## Evidence and diagnosis
- Screenshot evidence: four dropdown controls show red surfaces while surrounding panels and custom borders render normally.
- Source evidence: `CreateDropdown` constructs `UIPanelButtonTemplate` controls and calls `ApplyMarketButtonSkin(..., "control")`. The custom control fill is dark, but inherited template normal/pushed/highlight textures were left visible at non-zero alpha.
- Root cause: inherited template artwork bleeds through the custom control skin. The custom control fill palette itself is dark.
- Counter-evidence: no screenshot or source evidence indicates the dropdown popup or callback path is broken. Those behaviors are not changed.

## Implementation
- For `control` style only, set inherited normal/pushed/highlight template texture alpha to zero and disabled texture alpha to zero.
- Retain the dark custom fill, bevel border, custom hover highlight, dropdown arrow, popup rendering, selected text, disabled options, and callback behavior.
- Other button styles retain their previous texture treatment.

## Scope and ownership
- ModuloMarket UI only. Parent MODULO and specialist addon ownership are unchanged.
- No recipe/gathering data, market calculations, scanner/replication behavior, SavedVariables, API calls, dependencies, six-tab structure or My Crafts state changed.
- No new assets or security surface.

## Validation
- Focused regression: `tests/test_modulomarket_0_8_9_dropdown_skin.py` — 3 PASS.
- Full suite: `python -m pytest -q` — 240 PASS / 61 historical failures. This matches the 0.8.8 suite counts (237 PASS / 61 failures) after adding three passing tests; ten stale current-release version assertions were advanced from 0.8.8 to 0.8.9. The 61 failures remain the pre-existing historical failures.
- Lua syntax: `texluac -p` — 9/9 PASS.
- Fresh extraction, manifest inventory and ZIP CRC: recorded after packaging.
- Forever runtime acceptance: NOT RUN. The screenshot is FOREVER OBSERVED for 0.8.8 only, not 0.8.9.

## Acceptance and exit criteria
Install 0.8.9 on Forever 1.60.1 build 70938. Confirm all four dropdowns are dark/bronze/gold in normal, hover, open, disabled and selected states; confirm popup selection and callbacks still work; check for Lua errors. Until then, the visual correction is source-implemented and offline-tested, not runtime-verified.
