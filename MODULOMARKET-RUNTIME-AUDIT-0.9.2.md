# MODULOMARKET RUNTIME AUDIT 0.9.2

## Result
Outer-window chrome reduction. The template perimeter and explicit outer bevel are hidden/removed; all authored internal panel, tab, header and control borders remain. Source implementation and offline validation are complete. Forever runtime acceptance of 0.9.2 remains NOT RUN.

## Player problem and observable result
The player confirmed the 0.9.1 dropdown menus work correctly on the Forever client and requested an overall-window visual pass: remove the decorative borders around the outside of the main window while keeping all borders inside the content layout.

## Canonical baseline and evidence
- Baseline bundle: `ModuloMarket-GitHub-Update-0.9.1.zip`.
- Baseline ZIP CRC: PASS; 179 entries.
- Baseline SHA-256: `75ac5ec6a4a47efe8938f9f0bc764210f0d2f9b50f149d108f194d1c84ff2eef`.
- Player screenshot: 0.9.1 displayed on WoW Forever 1.60.1 build 70938; the dropdown is open in the screenshot and the user explicitly confirms dropdowns work properly. This is FOREVER OBSERVED for the shown 0.9.1 interface state.
- New request: remove outer-frame border treatments while preserving all internal borders.
- The available uploaded image at `/mnt/data/image.png` shows the overall window with the existing perimeter and internal borders. The separately referenced image variants were not independently available as separate files in the runtime, so the exact intended outer-edge treatment is interpreted as the main frame's template perimeter/inset and its explicit outer bevel, not internal content borders.

## Source diagnosis
The main frame is created with `BasicFrameTemplateWithInset`, which supplies decorative NineSlice/inset/title background elements. The addon also adds a custom `AddBevelBorder(frame, 5, -5, 1450, 840, "outer", "OVERLAY")`. These are separate from the inner panel borders and are the correct outer-chrome targets. The user explicitly asked to retain inner borders.

## Changes in 0.9.2
- Hide template `NineSlice`, `Inset`, `TitleBg` and `TopTileStreaks` elements when present.
- Retain the template's functional title text and close control.
- Remove the explicit full-window outer bevel.
- Preserve the title plaque and all internal panel, tab, header, filter, dropdown, table, inspector, relationship and history borders.
- No market calculations, scans, recipe/gathering data, SavedVariables, data catalogue, parent MODULO or specialist addon changes.
- Dropdown lifecycle behavior is unchanged from 0.9.1 and was confirmed working by the player on the target client.

## Ownership, dependencies and risk
- ModuloMarket owns the main-window chrome and inner panel layout.
- No new dependencies or APIs.
- Low behavioral risk; frame template remains in place to preserve functional close/title controls. Runtime risk: exact template-region names/visibility and resulting visual edge appearance must be checked in the target client.

## Validation
- Focused test `tests/test_modulomarket_0_9_2_outer_chrome.py`: 4 PASS.
- Full suite: 256 PASS / 61 historical failures.
- Exact comparison against the 0.9.1 parent archive: the same 61 failing test IDs; zero new failures and zero previously failing IDs fixed.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
- Fresh extraction: PASS.
- Manifest inventory: 182/182 files match the extracted tree.
- ZIP CRC: PASS (`ZipFile.testzip()` returned `None`).
- Full suite on fresh extraction: 256 PASS / 61 historical failures, same baseline failure IDs.
- Fresh-extraction Lua syntax: 9/9 PASS.
- Forever runtime acceptance of 0.9.2: NOT RUN. The 0.9.1 screenshot and user confirmation do not prove the 0.9.2 visual change.

## Player acceptance
Install 0.9.2 on Forever 1.60.1 build 70938 and verify:
1. The main window's outer perimeter and inset frame decoration are gone.
2. The title and functional top-right close control remain.
3. All borders inside the content area remain unchanged: navigation tabs, left filter/data panels, center table, right inspector cards, dropdowns and history chart.
4. Open/close and dropdown behavior remain correct.
If any unwanted internal border disappears or a template border remains, provide a screenshot and keep the visual scope open for correction.

