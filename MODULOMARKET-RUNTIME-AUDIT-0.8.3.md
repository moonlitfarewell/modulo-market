# ModuloMarket Runtime Audit 0.8.3 — All Items visual refinement

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.8.2.zip`  
**Previous bundle size:** 1,737,868 bytes  
**Previous bundle SHA-256:** `768815271fd2fe8cd7a628893ccb33f8f2cefb7aeada73bba7c4526db3d50119`  
**GitHub baseline:** `moonlitfarewell/modulo-market` `main`, commit `8ac8cc863b69d722fe3dfbdfdf9a657e6b93b5b7` (`Update to Modulo-Market 0.8.2`, 2026-11-13T02:14:57Z)  
**Parent MODULO:** 1.0.48, unchanged  
**Target client:** WoW Forever 1.60.1 build 70888  
**Release status:** SOURCE IMPLEMENTED; FOCUSED TESTS 65 PASS; FRESH-EXTRACTION TESTS 65 PASS; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 224 PASS / 61 LEGACY OR SUPERSEDED FAIL; NO NEW FAILING TEST IDS; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 154/154; TOC/CORE/MANIFEST VERSION 0.8.3; FOREVER RUNTIME NOT RUN.

## 1. Player problem and observable result

The user supplied the current ModuloMarket 0.8.2 Forever screenshot and the approved All Items mockup. The current screenshot shows the 0.8.2 header, left filter panel, market table, Data card and three-part selected-item inspector. It is usable, but several visual gaps remain:

- the title has no dedicated plaque and the overall header still lacks a strong visual anchor;
- the filter panel exposes a single semantic Item role selector, while the mockup distinguishes Item role from Item Types;
- the options and Data card need a clearer vertical hierarchy;
- table, filter and inspector text is visibly smaller than the mockup;
- the selected item icon and market values need stronger prominence.

The 0.8.3 player-visible target is a more legible All Items screen that restores a separate Item Types filter, retains the existing Item role filter, refines the title and typography, and keeps the existing six-tab product and market functionality unchanged.

## 2. Source-of-truth selection and evidence available

### Project inventory and canonical bundles

- The current Project conversation file inventory was enumerated. The highest supplied parent MODULO source bundle is `MODULO-Project-Source-1.0.48.zip`; no later parent source bundle was present in the inventory.
- Parent archive: 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; ZIP CRC PASS.
- The highest supplied ModuloMarket child bundle is `ModuloMarket-GitHub-Update-0.8.2.zip`; it contains 152 files and manifest version 0.8.2. ZIP CRC PASS.
- Child archive: 1,737,868 bytes; SHA-256 `768815271fd2fe8cd7a628893ccb33f8f2cefb7aeada73bba7c4526db3d50119`.
- GitHub `main` currently identifies commit `8ac8cc863b69d722fe3dfbdfdf9a657e6b93b5b7`, message `Update to Modulo-Market 0.8.2`. Git blob hashes from the supplied 0.8.2 bundle match GitHub `main` for:
  - `AddOns/ModuloMarket/MarketUI.lua`: `c0c7abf301075b92e505c179046e432d10fb9cff`
  - `AddOns/ModuloMarket/Core.lua`: `13c3961a0d6970af044efb8555c9de40728b7b9e`
  - `MANIFEST.json`: `713a371e9d011372e5f086cfcefd3e29d5bd3890`
  - `README.md`: `42bb23fc930ff2a562608fbdc99c0cfcf5c0ed68`
- The 0.8.2 archive manifest has 152/152 files present, no unlisted files, and version 0.8.2.
- Child-level separate `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA`, `SOURCE-REVIEW-LEDGER` and architecture/Forever-contract documents were not present in the child bundle. The parent MODULO 1.0.48 start-here, workflow, progress, decisions, QA, source-review ledger, architecture and Forever compatibility contract were consulted. The child README, manifest and 0.8.2 audit were read. Missing child chat history was not reconstructed.

### Relevant implementation evidence

- `MarketUI.lua` owns the main window, tab/filter state, virtualized item rows, selected-item inspector, history renderer and market view building.
- The existing `GetRoleOptions()` list represents profession-related roles/statuses: known craft outputs, learnable craft outputs, unavailable craft outputs, gathering resources and crafting reagents. It is not the same concept as game item class.
- Existing `ReadVendorInfo()` already reads the `classID` return from `GetItemInfo` and `classID` / `itemClassID` from `C_Item.GetItemInfo`.
- Existing `GetLowSupplyThreshold()` already treats class IDs 0 and 7 as material/gatherable classes, and class IDs 2 and 4 as equipment classes. 0.8.3 reuses those known IDs for the initial broad type groups rather than guessing from item names.
- Existing `vendorInfoEvents` already listens for `GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT`. The new class metadata path reuses these existing item-data events.
- Existing item search and view construction are incremental. The new class warmup queue issues at most ten item metadata requests per frame.
- Existing market row height is 24px and the virtualized row count is 25. Both remain unchanged.

## 3. Player problem, expected result and scope

### 0.8.3 changes

1. **Distinct Item role and Item Types controls**
   - Item role remains the existing profession/gathering/material relationship filter.
   - A separate Item Types dropdown is shown on All Items only.
   - Options: All item types; Consumables (class 0); Equipment (Weapon class 2 or Armor class 4); Trade Goods (class 7); Other item classes (all other reported class IDs).
   - The filter reads class IDs from `C_Item.GetItemInfo` or the existing legacy `GetItemInfo` tuple. It does not infer type from item names.
   - Missing/unavailable class metadata is not guessed. When a specific type is selected, items without class metadata are excluded. All item types preserves the unfiltered view.
   - Class metadata is requested through a queue capped at ten attempts per frame. Existing item-data events populate the cache and schedule a debounced rebuild. Failed requests are marked unclassified to avoid repeated requests.
   - The control is intentionally restricted to All Items so it does not overlap Economics/Crafts specialist filter controls on other tabs.

2. **Left filter and Data card hierarchy**
   - Item Types is placed below Item role.
   - All Items quick options move below the new selector and use compact, consistent row spacing.
   - The Data card moves lower and becomes shorter, leaving clear separation between the last quick filter and the Data header.
   - Crafting Scope remains inside the Data card.

3. **Header and title**
   - Adds a restrained dark/gold title plaque and centers the existing Modulo Market title on it.
   - No additional scan percentage or invented data state is added.

4. **Table and typography**
   - Increases key filter, table header and market row font sizes by one point where the font object exposes its current size.
   - Increases inspector text hierarchy without changing row height, virtualized row count, table columns or market calculations.

5. **Selected Item inspector**
   - Enlarges the item icon from 42px to 48px and gives the item name more prominence.
   - Market Information row labels and values use larger font objects.
   - Relationships keeps its existing scroll frame and source-derived content.
   - Market History keeps its existing saved points and expanded graph; graph geometry remains inside the existing history card.

### Preserved behavior and explicit non-goals

- The six existing tabs remain: All Items, Economics, Crafts, Materials, Low Supply and History.
- No My Crafts tab is reintroduced.
- Existing market columns, search, sorting, selection, tooltips, auction scan, snapshot provenance, recipe data, economics calculations, quick-filter semantics and SavedVariables schema are unchanged.
- No MarketEngine, RecipeEngine, ProfessionData, ForeverDB dataset or parent MODULO code was changed.
- No new addon dependency or SavedVariables field was added. `itemTypeFilter` is per-tab runtime UI state, not persisted data.

## 4. Ownership, dependencies and Forever boundaries

- Owner: optional child addon ModuloMarket.
- Parent MODULO 1.0.48 remains unchanged.
- ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- Item class reads reuse existing item-info APIs and events already used by the addon. The new code adds a bounded request queue but no new external dependency.
- Font-size refinement uses the existing FontString `GetFont` / `SetFont` methods with guarded calls; failure to adjust a font does not abort UI creation.
- Source/static tests do not establish the actual Forever API return shape, event timing, title layering, font rendering or layout at the player's UI scale.
- Forever runtime acceptance for 0.8.3 is **NOT RUN**. The supplied screenshot is evidence for 0.8.2 only.

## 5. Risks and counter-evidence

- The client may not return class metadata for every item. Such items remain unclassified and are excluded only when a specific type filter is selected.
- The exact `C_Item.GetItemInfo` result fields and legacy `GetItemInfo` classID return need verification on Forever 1.60.1 build 70888. The code uses guarded API calls and fails closed.
- Item-data events may be delayed, absent or report failure. The new warmup queue is capped at ten attempts per frame and does not repeatedly retry completed failures.
- Larger fonts and the title plaque may clip or layer incorrectly at other UI scales/resolutions.
- The All Items type selector is deliberately hidden on other tabs; those tabs retain their existing specialist filter layouts.
- The broad `Other item classes` option is not a detailed per-class taxonomy; it groups every reported class ID other than 0, 2, 4 and 7.
- No evidence currently establishes the visual appearance or interaction success of the 0.8.3 build inside the Forever client.

## 6. Verification

### Focused regression suite

Command:
`python -m pytest -q tests/test_modulomarket_0_8_3_visual_refinement.py tests/test_modulomarket_0_8_2_mockup_alignment.py tests/test_modulomarket_0_8_1_visual_foundation.py tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_ui_0_6_4_layout.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_ui_0_6_2_runtime_layout.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py tests/test_modulomarket_acquisition_compact_0_6_6.py`

Result: **65 passed**.

### Full historical suite

Command: `python -m pytest -q`  
Result: **224 passed, 61 failed**.

The exact 0.8.2 baseline was rerun from a fresh extraction: **214 passed, 62 failed**. Failure-ID comparison shows **no new failing test IDs** in 0.8.3. One pre-existing historical geometry assertion now passes after its expected history-graph size was refreshed. The remaining failures are retained legacy/version-pinned or superseded contracts; they are not described as passes.

### Lua syntax

Command: `texluac -p` for every `AddOns/ModuloMarket/*.lua` file.  
Result: **9/9 PASS**.

### Existing profession capture harness

Command: `texlua tests/profession_capture_0_7_8_harness.lua`  
Result: **PASS** (`ModuloMarket 0.7.8 profession capture harness PASS`).

### Package validation

Final bundle validation: `ModuloMarket-GitHub-Update-0.8.3.zip`; exact manifest inventory 154/154; ZIP CRC PASS; fresh extraction PASS; focused regressions rerun from fresh extraction — 65 PASS; Lua syntax rerun from fresh extraction — 9/9 PASS; profession capture harness PASS; TOC/Core/manifest all 0.8.3. Bundle SHA-256 is recorded in the release handoff.

## 7. Forever runtime acceptance — NOT RUN

Target: WoW Forever 1.60.1 build 70888.

1. Install 0.8.3 over 0.8.2 and open All Items at the same screen resolution/UI scale as the supplied screenshot.
2. Confirm the title plaque is centered, visible and does not obscure the native frame border or title.
3. Confirm Search, Profession, Item role, Item Types, Options and Data are vertically separated with no overlap.
4. Open Item role and confirm it still offers the existing profession/gathering/material relationship roles.
5. Open Item Types and test All item types, Consumables, Equipment, Trade Goods and Other item classes.
6. Confirm each selected type uses client item-class metadata; items with missing class metadata are not misclassified. Confirm All item types restores all rows.
7. Confirm item metadata loading is responsive, issues no more than ten requests per frame, and updates results after `GET_ITEM_INFO_RECEIVED` / `ITEM_DATA_LOAD_RESULT`.
8. Combine Item Types with profession and quick filters; confirm the resulting rows satisfy every active filter.
9. Switch to Economics, Crafts, Materials, Low Supply and History. Confirm Item Types is hidden and specialist filter layouts do not overlap the Data card.
10. Confirm all six tabs, existing market columns, sort, search, selection, tooltips, crafting scope and opacity still work.
11. Inspect long item names, market value rows, Relationships scrolling and four-point Market History text/graph for clipping.
12. Check for Lua errors, missing controls, incorrect item classification, repeated item-data requests, overlapping panels and tooltip layering.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED TESTS 65 PASS; LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; FULL SUITE 224 PASS / 61 LEGACY OR SUPERSEDED FAIL; NO NEW FAILING TEST IDS; PACKAGE VALIDATION PENDING; FOREVER RUNTIME NOT RUN. Player-visible acceptance remains OPEN until 0.8.3 is tested on build 70888.
