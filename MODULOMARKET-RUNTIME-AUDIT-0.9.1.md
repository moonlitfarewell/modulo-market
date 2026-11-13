# MODULOMARKET RUNTIME AUDIT 0.9.1

## Result
Combined interface refinement and dropdown lifecycle correction. Source implementation and offline validation are complete. Forever runtime acceptance of 0.9.1 remains NOT RUN.

## Player problem and observable result
The player requested a coordinated visual pass and reported that dropdown menus remain open after the main ModuloMarket window is closed. The expected result is a more legible table and history graph, plus guaranteed dismissal of all independent dropdown popups whenever the main window hides, a dropdown control hides, or the user switches tabs.

## Canonical baseline and available evidence
- Parent bundle: `ModuloMarket-GitHub-Update-0.9.0.zip`; ZIP CRC PASS; 176 entries.
- Parent bundle SHA-256: `6c69a3e631c07d3104b9290e79ec5041ad5d91677cd1e2931fe1d8ea5365ccc3`.
- Parent addon version: 0.9.0; TOC and Core agree.
- User screenshot: ModuloMarket 0.9.0 rendered in WoW Forever 1.60.1 build 70938. It visibly confirms the six-tab frame, table, inspector, history graph and dark/gold dropdown palette. This is FOREVER OBSERVED for those visible 0.9.0 surfaces only.
- User report: dropdown menus remain open when the main window closes. This is a player-reported runtime defect; the exact close pathway was not separately screen-recorded.
- Source diagnosis: each dropdown popup is parented to `UIParent`, independent of the main window. The 0.9.0 main frame had no `OnHide` handler to close these popups. Therefore hiding the main frame does not guarantee popup dismissal. The popup's independent ownership is the root cause supported by source.
- Child project governance documents such as PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS and SOURCE-REVIEW-LEDGER are not present in the 0.9.0 child bundle. Their missing history has not been reconstructed.

## Competing hypotheses and diagnostic
1. **Independent popup lifecycle (favored):** popup frames are parented to `UIParent` and have no main-frame close notification. Source inspection confirms this.
2. **Only a dropdown's visual anchor remains stale:** popup might be hidden but visually orphaned due to strata/anchor. This is less consistent with the report; inspection confirms the popup remains independently shown and no explicit close path exists.
The distinguishing diagnostic is to inspect `popup:IsShown()` before and after the main frame's `OnHide`; source lifecycle tests assert the close callback is invoked for every registered popup. Actual target-client behavior remains to be verified after installation.

## Changes in 0.9.1
### Dropdown lifecycle
- Register every dropdown created by `CreateDropdown` in `UI.dropdowns`.
- Add `UI.CloseDropdownMenus()` to close all registered popups and hide stale GameTooltip content.
- Give each dropdown a `CloseMenu` method and close it when its control receives `OnHide`.
- Call the close-all routine from main-frame `OnHide` and `OnShow`, and before tab state changes.
- Popup options, selection callbacks, disabled choices, tooltip behavior and filter values are preserved.

### Coordinated visual refinements
- Add a dark inset table header rail and subtle bronze column guides.
- Increase selected-row wash contrast and accent width; adjust alternating row surfaces to reduce brown noise.
- Add a subtle baseline to the four-point market-history graph.
- Scale graph bar heights and percentage-label placement against the actual graph height rather than fixed offsets.
- Preserve existing table row height, virtual-row count, sorting, values and history points.

## Ownership, dependencies and scope
- ModuloMarket owns the changed UI and popup lifecycle.
- No parent MODULO code, optional addon, new API, dependency, SavedVariables, data catalogue, recipe/gathering mapping, market formula or scan acquisition behavior changed.
- Six tabs remain; My Crafts remains absent.
- No Forever runtime API assumptions were added.

## Validation
- Focused lifecycle/visual tests: 12 PASS.
- Full suite: 252 PASS / 61 historical failures.
- Direct comparison against the exact 0.9.0 parent archive: same 61 failing test IDs; zero new failing IDs.
- Lua syntax: 9/9 PASS.
- Fresh extraction, manifest inventory, ZIP CRC and fresh-extraction test results are recorded after packaging.
- Forever runtime acceptance of 0.9.1: NOT RUN. The 0.9.0 screenshot is FOREVER OBSERVED for 0.9.0 only.

## Acceptance and exit criteria
Install 0.9.1 on Forever 1.60.1 build 70938 and verify:
1. Open each dropdown, then close the main window using the Close button and Escape; no popup remains visible.
2. Open a dropdown, switch tabs or hide its control; its popup closes.
3. Reopen the main window; no orphan popup appears and dropdowns can be opened normally.
4. Select enabled and disabled options; existing values and callbacks remain correct.
5. Verify table headings/selection and history bars/labels render without overlap or clipping.
Until these checks pass in the target client, the close fix and visual refinements are source-implemented and offline-tested, not FOREVER VERIFIED.

- Focused tests: `tests/test_modulomarket_0_9_1_interface_lifecycle.py` plus the 0.9.0 visual regression suite — 12 PASS.
- Full suite: `python -m pytest -q` — 252 PASS / 61 historical failures. Direct comparison with the exact 0.9.0 parent archive confirms the same 61 failing test IDs and zero new failures.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
- The full suite includes the compatibility and profession-capture regression tests; those are offline harness results, not live Forever runtime acceptance.
- Fresh extraction: PASS. Manifest inventory: 179/179 files match the extracted tree. ZIP CRC: PASS (`ZipFile.testzip()` returned `None`). Full suite on fresh extraction: 252 PASS / 61 historical failures; identical 61 failing test IDs to the 0.9.0 parent. Fresh-extraction Lua syntax: 9/9 PASS.
