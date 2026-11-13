# ModuloMarket Runtime Audit 0.8.2 — All Items mockup alignment

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.8.1.zip`  
**Previous bundle size:** 1,729,268 bytes  
**Previous bundle SHA-256:** `8b783cfa9768ec3c28bef4d5158035fafce3e4812b2f772f798c8c849e197544`  
**Parent MODULO:** 1.0.48, unchanged  
**Target client:** WoW Forever 1.60.1 build 70888  
**Release status:** SOURCE IMPLEMENTED; FOCUSED TESTS 51 PASS; FRESH-EXTRACTION TESTS 51 PASS; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 214 PASS / 62 LEGACY OR SUPERSEDED FAIL; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 152/152; VERSION AGREEMENT PASS; FOREVER RUNTIME FOR 0.8.2 NOT RUN.

## 1. Player problem and observable result

The user supplied two screenshots: the current 0.8.1 client interface and the approved All Items mockup. The current interface has the first inspector-card pass, but the header still competes for space, the data provenance is separated from the filter workspace, the All Items panel lacks the mockup's quick options, and relationships are rendered as one long text block. The mockup also demonstrates a more compact Relationships section and a larger Market History area.

0.8.2 targets:
- simpler header with market snapshot summary, scan state/controls and opacity;
- a left-side Data card with auction data, recipe data, review-record count and Crafting Scope;
- four usable All Items quick filters with explicit, source-grounded semantics;
- distinct Crafting and Gathering relationship rows;
- compact Relationships and expanded Market History sections;
- preservation of the six tabs, market columns, existing scan/recipe/market data and SavedVariables.

## 2. Source of truth and evidence actually inspected

### Complete bundles and provenance

- 0.8.1 child bundle: ZIP CRC PASS, 150 entries, manifest version 0.8.1 and 150/150 manifest-listed files. SHA-256 matches the prior handoff.
- Parent MODULO 1.0.48 archive: 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; ZIP CRC PASS; size and hash match the child manifest's parent provenance.
- Parent project records inspected: PROJECT-START-HERE, README/evidence index, WORKFLOW, PROJECT-PROGRESS, PROJECT-DECISIONS, QA, SOURCE-REVIEW-LEDGER, MODULO-ARCHITECTURE and Forever compatibility contract. Parent ownership/dependency rule remains: ModuloMarket is a separate optional child; MODULO may be its dependency, but MODULO must not depend on ModuloMarket.
- User-supplied current screenshot visibly identifies ModuloMarket v0.8.1 on Forever 1.60.1 build 70888. It is runtime evidence for the visible 0.8.1 screen only, not 0.8.2 acceptance.
- User-supplied mockup is treated as a presentation target. Its sample recipe build/status/count values are not copied as runtime facts.
- Supplied `WTF.zip` was inspected. It contains MODULO SavedVariables and other addon data, but no `ModuloMarketDB` SavedVariables file. The current screenshot does not expose the selected item's numeric itemID. Therefore the mockup's specific Fishing relationship cannot be assigned to that item from the supplied evidence alone.

### Code evidence and counter-evidence

- `Replicate.lua` and `Scanner.lua` both serialize `snapshot.clientBuild` as `tostring(build)`, e.g. `70888`.
- `UpdateMetadata()` previously compared this with the full client identity `1.60.1.70888`. That caused the screenshot's false "Build mismatch" despite matching build numbers.
- `ProfessionData.GetGatheringInfo(itemID)` reads the existing item-ID catalogue built from `GatheringItems.lua`. The catalogue contains sourced Classic gathering IDs, including Fishing, but the screenshot alone does not reveal whether the selected 10 Pound Mud Snapper item is one of those IDs. No name-based or guessed mapping was added.
- `Replicate.GetState()` still does not expose a reliable percentage-complete value. No 0%/100% or fabricated progress percentage was added.
- `reviewWatchCount` counts recipe records flagged by the hotfix review watch, not an independently deduplicated count of market item IDs. The UI therefore labels it "Review records", not "Review items".

## 3. Player problem, implementation and ownership

### Header and Data card

- Auction and recipe status labels moved out of the crowded header into a dedicated Data card in the left filter panel.
- Review watch count is displayed as "Review records".
- Crafting Scope dropdown moved into the Data card; account/character scope behavior is unchanged.
- Window opacity remains in the header.
- Status line is capped to a single-line display; the full status text remains available from its tooltip.
- Auction build identity comparison now normalizes the trailing numeric build component. `70888` and `1.60.1.70888` compare equal. Display uses the full current client identity when they match.
- Scan state remains sourced from `Replicate.GetState()`. A progress percentage is intentionally omitted.

### All Items quick filters

Four checkboxes are available only on the All Items tab:
1. **Crafting materials only** — uses `ProfessionData.IsMaterial(itemID)`.
2. **Low supply only** — uses the same item-aware `GetLowSupplyThreshold(item)` as the existing Low Supply tab.
3. **High profit only** — uses the existing incremental recipe economics index and includes only items with a source-confirmed best craft route and positive calculated auction profit after the configured auction-house cut. It builds the index before filtering if needed.
4. **Show review items only** — includes only market item IDs whose profession data contains a recipe explicitly marked `freshnessStatus == "review"`.

The four options can be combined and their state is retained per tab in the existing in-memory tab filter state. They do not create a new SavedVariables schema.

### Selected Item inspector

- Crafting and Gathering are now separate first-class rows with distinct icons and labels.
- Crafting summary distinguishes known output recipes from other supported routes.
- Gathering names come only from the existing numeric item-ID mapping; supported professions are displayed as Classic. Unmapped items explicitly say "No mapped source".
- Existing recipe outputs, reagent uses, unlearned/future recipe details, gathering skill requirements and evidence notes remain in the scrollable content.
- Relationships card is shortened; Market History card is expanded. Existing saved full-market points, dates, quantities and graph calculations are retained.

### Ownership and dependencies

- Owner: ModuloMarket child addon.
- Parent MODULO 1.0.48 unchanged.
- No new dependencies, external-addon calls, APIs, database facts, recipe data, auction snapshot fields, market calculations or SavedVariables fields/schema.
- The current child addon TOC still depends on MODULO and optionally LibProfessionDB; MODULO has no dependency on ModuloMarket.

## 4. Risks and scope

- The new Data card and four checkboxes need visual validation at the player's UI scale and screen resolution.
- The compact relationship viewport may require scrollbar/height adjustment for items with many recipe relationships.
- The larger history area needs populated and empty history runtime checks.
- High Profit indexing can take time for a large recipe catalogue; it uses the existing incremental index queue rather than a synchronous full scan.
- Review-only results may be empty when no review-tagged recipe output is present in the current market snapshot; this is expected, not a failed filter.
- The selected screenshot item's exact itemID remains unavailable in the supplied WTF package. The implementation intentionally avoids inventing a Fishing mapping.
- No percentage scan bar was added because the current state API does not expose reliable progress.

## 5. Verification

### Focused current-slice regression suite

Command:
`python -m pytest -q tests/test_modulomarket_0_8_2_mockup_alignment.py tests/test_modulomarket_0_8_1_visual_foundation.py tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_ui_0_6_4_layout.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_ui_0_6_2_runtime_layout.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py`

Result: **51 passed**.

### Lua syntax

Command: `texluac -p` for every `AddOns/ModuloMarket/*.lua` file.  
Result: **9 files PASS**.

### Existing profession capture harness

Command: `texlua tests/profession_capture_0_7_8_harness.lua`  
Result: **PASS** (`ModuloMarket 0.7.8 profession capture harness PASS`).

### Full historical suite

Command: `python -m pytest -q`  
Result: **214 passed, 62 failed**. The 0.8.1 baseline was 203 passed / 65 failed. The 0.8.2 full suite has no new failing test IDs relative to that baseline; two superseded UI geometry assertions and one stale version assertion were refreshed, and the new 0.8.2 tests add coverage. Remaining failures are retained historical/version-pinned or superseded contracts. They are not reported as passes.

### Package validation

Final package validation: `ModuloMarket-GitHub-Update-0.8.2.zip`; exact manifest inventory 152/152; ZIP CRC PASS; fresh extraction PASS; focused tests rerun from fresh extraction — 51 PASS; Lua syntax rerun from fresh extraction — 9/9 PASS; profession capture harness PASS; TOC/Core/manifest all 0.8.2; bundle SHA-256 is recorded in the release handoff.

## 6. Forever runtime acceptance — NOT RUN for 0.8.2

Target: WoW Forever 1.60.1 build 70888.

1. Install 0.8.2 over 0.8.1 and open All Items at the same resolution/UI scale as the supplied screenshot.
2. Confirm the header no longer overlaps and Auction Data displays the full current client identity as Current rather than a false mismatch.
3. Confirm Recipe Data, Current/Baseline status and Review records count match the actual provider data.
4. Confirm Crafting Scope works from the left Data card for both Account and Character modes.
5. Confirm the four All Items options appear only on All Items, can be combined, update the result count, and preserve their state when switching tabs and returning.
6. Verify Crafting Materials only against the Materials tab; Low Supply only against the Low Supply tab; High Profit only against positive source-confirmed craft routes; Review only against records explicitly marked for review.
7. Confirm search, profession dropdown, item-role dropdown, sorting, all six tabs, row selection and tooltips still work with quick filters enabled and disabled.
8. Select an item with known mapped gathering evidence and confirm its profession appears in Gathering. Select an unmapped item and confirm it says "No mapped source"; do not expect name-based inference.
9. Select an item with known recipe outputs, reagent uses, unlearned recipes and multiple gathering relationships; confirm the Crafting and Gathering rows and scroll area remain usable.
10. Confirm Market History empty and populated states, all saved points, dates, quantities and graph labels fit in the expanded card.
11. Confirm scan state is truthful and no fabricated percentage is displayed.
12. Check for Lua errors, overlapping controls, clipped text, broken scrollbars and tooltip layering.

**Exit status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE TESTS 51 PASS; FRESH-EXTRACTION TESTS 51 PASS; LUA SYNTAX 9/9 PASS; FRESH-EXTRACTION LUA SYNTAX 9/9 PASS; PROFESSION CAPTURE HARNESS PASS; FULL HISTORICAL SUITE 214 PASS / 62 LEGACY OR SUPERSEDED FAIL; ZIP CRC PASS; FRESH EXTRACTION PASS; MANIFEST 152/152; TOC/CORE/MANIFEST VERSION 0.8.2; FOREVER RUNTIME 0.8.2 NOT RUN. Player-visible acceptance remains OPEN until the user tests the new bundle on build 70888.
