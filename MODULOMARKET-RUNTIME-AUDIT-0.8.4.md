# ModuloMarket Runtime Audit 0.8.4 — consolidated Dark Foundry visual redesign

**Parent child bundle:** `ModuloMarket-GitHub-Update-0.8.3.zip`  
**Parent child bundle bytes:** 1,748,143  
**Parent child bundle SHA-256:** `c45a7421f83f57be13609694ead1e93dcbd281cb260a4b737a986ac4d71149a0`  
**GitHub source:** `moonlitfarewell/modulo-market`, default branch `main`, version 0.8.3 at implementation start. GitHub file blob SHAs matched the supplied 0.8.3 source for `MarketUI.lua` (`b1f79ccbbae24dbfe87f0f4d0089542fd99cfcb5`), `Core.lua` (`dafde074d151ae3467bbcbc18e882cf5a837907c`), `MANIFEST.json` (`2124ffd405c6d60ad33292b3c95e5348076cacbb`), `README.md` (`35674071511ab8feb2a3713da2a6074fe7c03328`) and `ModuloMarket.toc` (`51f87780d0df043962cefaa1a079f327ffdd2cb2`).  
**Parent MODULO source:** `MODULO-Project-Source-1.0.48.zip`; Project file ID `file_000000001a2482128af00913b054f6f9`; 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; 506 archive members; ZIP CRC PASS. Parent unchanged.  
**Target client:** WoW Forever 1.60.1 build 70888.  
**Release status:** SOURCE IMPLEMENTED; FOCUSED REGRESSIONS 72 PASS; FRESH-EXTRACTION FOCUSED REGRESSIONS 72 PASS; FULL HISTORICAL SUITE 231 PASS / 61 FAIL; FAILURE-ID COMPARISON TO 0.8.3 BASELINE: NO NEW FAILURES; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 157/157; TOC/CORE/README/MANIFEST 0.8.4; 0.8.4 FOREVER RUNTIME NOT RUN.

## 1. Player problem and intended result

The user approved a single consolidated visual redesign covering the first five areas of the All Items interface, rather than five separate major releases. The approved proof of concept is visual guidance, not a pixel-perfect specification. The intended result is one coherent Warcraft/Dark Foundry visual language across:

1. Header and outer window frame.
2. Six-tab navigation.
3. Left filter panel and Data card.
4. Centre market table.
5. Right selected-item inspector.

The user explicitly ruled out unrelated market-data, recipe, gathering, selection, or market-calculation work. The release is therefore presentation-only.

## 2. Source of truth and evidence actually available

### Parent and child provenance

- The highest supplied parent MODULO source bundle was `MODULO-Project-Source-1.0.48.zip`. ZIP CRC passed; it contains 506 members and has SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.
- The child repository is separate from parent MODULO. The child 0.8.3 bundle has 154 manifest-listed files, ZIP CRC PASS, and SHA-256 `c45a7421f83f57be13609694ead1e93dcbd281cb260a4b737a986ac4d71149a0`.
- The child manifest's parent provenance fields agree with the supplied parent bundle: filename, Project file ID, source kind `project`, uploader `developer`, and SHA-256.
- GitHub `main` was fetched at implementation start. Version 0.8.3 was confirmed by the README, TOC, Core and manifest. Git blob hashes for the source files listed above match the local 0.8.3 source extraction. No 0.6.8 source was used.
- The parent `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-PROGRESS`, `PROJECT-DECISIONS`, `QA`, `SOURCE-REVIEW-LEDGER`, `MODULO-ARCHITECTURE`, `MODULO-PRODUCT-DIRECTION`, `FOREVER-COMPATIBILITY-CONTRACT` and `FOREVER-COMPATIBILITY-CHANGES` were consulted. The child README, manifest, 0.8.3 audit and relevant UI design/maintenance notes 0.5.6, 0.5.7, 0.5.9 and 0.6.2 were reviewed. The child repository does not contain a separate child `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA` or `SOURCE-REVIEW-LEDGER`; child history not supplied in the bundle was not reconstructed.

### Runtime evidence already supplied

The user supplied an actual in-game screenshot with the footer `ModuloMarket v0.8.3 · Client 1.60.1 build 70888`. It shows the All Items window, its six tabs, left filter controls, table and inspector rendered on Forever. This is **FOREVER OBSERVED** evidence that the 0.8.3 All Items screen opened and rendered in that environment. It does not prove all controls, all tabs, every filter/API path, or the 0.8.4 redesign. The original 0.8.3 audit's `NOT RUN` statement is preserved as the status at its package handoff; the subsequent screenshot is recorded here as new evidence.

## 3. Current implementation evidence and exact changes

`AddOns/ModuloMarket/MarketUI.lua` is the presentation owner. Relevant existing paths reviewed include `CreateDropdown`, `AddButton`, `AddLabel`, `UI.RefreshActions`, `UI.RenderRows`, `SetTab`, and `CreateUI`, plus `Replicate.GetState()` as the source of truthful scan-state labels. The source file was inspected around these construction, update and render paths; this was not an exhaustive line-by-line audit of all 3,800+ lines.

### Shared presentation primitives

- Added `AddBevelBorder()` with reusable outer, plaque, panel, card, tab, control and button palettes. It creates bounded edge textures with dark shadow, bronze/gold highlight and inset shade.
- Added `ApplyMarketButtonSkin()` for the existing button templates, preserving click scripts and popup behavior while adding dark fills, warm highlights, bevel edges and readable label color.
- Added `AddInsetSurface()` for dark recessed panel surfaces.

### Header and outer frame

- Widened the existing centered title plaque to 340 × 36 and added a dark inset, double bevel and restrained corner accents.
- Added a header rail and framed market metadata/scan-state pills.
- Improved the opacity control alignment and label size.
- Added a layered outer frame edge inside the existing 1460 × 850 frame.
- Kept scan text tied to `Replicate.GetState()` / `UI.RefreshActions()`. No percentage or progress measurement was fabricated because the existing exposed state does not provide one.

### Navigation

- Added bronze/gold edge treatments and state-aware active-tab styling to the existing six tabs.
- Preserved all six tab keys, click callbacks, tooltips and tab-specific state. My Crafts was not reintroduced.

### Left filter panel

- Applied the shared dark/gold button skin to the existing market buttons and custom dropdowns; tinted dropdown arrows gold.
- Strengthened filter label hierarchy, Options divider and Data card inset surface.
- Preserved Search, Profession, Item role, Item Types, quick options and Crafting Scope positions and behavior.

### Centre table

- Added a table column-heading band with bronze/gold top/bottom rules.
- Increased alternating row-surface contrast and added a gold wash/accent/top/bottom rule for the selected row.
- Increased row item icons from 18 to 20 logical pixels.
- Preserved six tab-specific column models, sorting, market calculations, 24px row height, 25-row virtual pool and scrolling.

### Right inspector

- Added inset surfaces, stronger header plates and layered bevel edges to the existing three inspector cards.
- Added a framed dark/gold mount around the existing 48px selected-item icon.
- Preserved existing market values, recipe/gathering context, relationship scroll frame, history text/points/graph and tooltip behavior.

## 4. Ownership, dependencies and non-goals

- Owner: separate optional child addon ModuloMarket; presentation is owned by `MarketUI.lua`.
- Parent MODULO 1.0.48 is unchanged. ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No Auctionator, ProfessionMaster, Polestar or other specialist dependency was added.
- No MarketEngine, RecipeEngine, Scanner, Replicate, ProfessionData, ForeverDB dataset, SavedVariables schema, recipe/acquisition data, market calculation or scan behavior was intentionally changed.
- No new game API, event, protected action, secure attribute or external texture asset was introduced. New drawing uses existing frame/texture/font/button methods already used by the addon.

## 5. Risks, counter-evidence and Forever gaps

- Source tests cannot prove actual draw order of parent-frame texture layers versus template textures and child frames on Forever.
- The custom border overlays must not obscure the close button, draggable title region, dropdown controls, text, scrollbars or tooltips.
- The selected-row overlay must not obscure item text/icons or interfere with click/hover targets.
- Increased font sizing and header spacing may clip at UI scales/resolutions other than the supplied setup.
- The 0.8.3 screenshot is positive prior-client evidence, but is not evidence for 0.8.4 rendering. 0.8.4 remains **FOREVER runtime NOT RUN**.
- The code uses guarded `GetNormalTexture`, `GetPushedTexture`, `GetHighlightTexture`, `GetDisabledTexture`, `GetFontString`, `GetFont` and `SetFont` access for styling. Exact Forever draw/skin behavior remains unobserved for this new presentation code.

## 6. Verification results

### Focused visual/regression suite

Command:
`python -m pytest -q tests/test_modulomarket_0_8_4_visual_redesign.py tests/test_modulomarket_0_8_3_visual_refinement.py tests/test_modulomarket_0_8_2_mockup_alignment.py tests/test_modulomarket_0_8_1_visual_foundation.py tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_ui_0_6_4_layout.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_ui_0_6_2_runtime_layout.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py tests/test_modulomarket_acquisition_compact_0_6_6.py`

Result: **72 passed**.

### Full historical suite

Command: `python -m pytest -q`  
0.8.3 baseline from a fresh extraction: **224 passed, 61 failed**.  
0.8.4 source: **231 passed, 61 failed**.  
Failure-ID comparison: **0 new failing test IDs; 0 baseline failures disappeared**. The seven additional tests are the seven new 0.8.4 visual regression tests, all passing. The same 61 legacy/version-pinned or superseded failures remain; they are not reported as passes.

### Lua and existing harness

- `texluac -p AddOns/ModuloMarket/*.lua` — **9/9 PASS**.
- `texlua tests/profession_capture_0_7_8_harness.lua` — **PASS** (`ModuloMarket 0.7.8 profession capture harness PASS`).

### Package validation

Final archive validation: `ModuloMarket-GitHub-Update-0.8.4.zip`; exact manifest inventory 157/157; ZIP CRC PASS; fresh extraction PASS; focused regressions rerun from fresh extraction — 72 PASS; Lua syntax rerun from fresh extraction — 9/9 PASS; profession capture harness PASS; full historical suite rerun from fresh extraction — 231 PASS / 61 FAIL; all 61 failure IDs match the 0.8.3 baseline; TOC/Core/README/manifest all 0.8.4. Exact bundle SHA-256 is reported in the release handoff.

## 7. Forever runtime acceptance — NOT RUN

Target: WoW Forever 1.60.1 build 70888.

1. Install 0.8.4 over 0.8.3 and open All Items at the same resolution/UI scale as the supplied screenshot.
2. Confirm the 340 × 36 title plaque, corner accents and outer bevel render cleanly; close button and title remain unobstructed.
3. Confirm market metadata, scan state, action buttons, status line and opacity slider/value do not overlap. Confirm scan labels reflect only real Replicate state.
4. Switch all six tabs; confirm active/inactive tab bevels are clear and every tab remains clickable. No My Crafts tab appears.
5. Open Profession, Item role, Item Types and Crafting Scope dropdowns. Confirm fills, gold arrows, popup edges, hover tooltips and selection remain functional.
6. Toggle All Items quick filters and verify checkboxes/labels remain legible; verify Data card and Crafting Scope are fully inside the left panel.
7. Inspect all table headings, long item names, item icons, alternating rows, selected-row gold accents, sorting and scrolling. Confirm no clipping or click/hover regression.
8. Inspect selected-item header/icon mount, all three inspector cards, long Relationships content, scrolling, history text and graph.
9. Test whole-window opacity at low/high settings, dragging, Escape/close, hover tooltips and dropdown popup strata.
10. Check all six tabs for layout overlap, Lua errors, taint warnings, missing controls, clipping and responsiveness.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED TESTS 72 PASS; FRESH-EXTRACTION FOCUSED TESTS 72 PASS; FULL SUITE 231 PASS / 61 UNCHANGED LEGACY FAILURES; NO NEW FAILING TEST IDS VS 0.8.3; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION HARNESS PASS; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 157/157; TOC/CORE/README/MANIFEST VERSION 0.8.4; FOREVER RUNTIME NOT RUN. Player-visible acceptance of the 0.8.4 redesign remains OPEN until the user tests it on build 70888. Player-visible acceptance of the 0.8.4 redesign remains OPEN until the user tests it on build 70888.
