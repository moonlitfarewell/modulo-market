# Modulo Market Runtime Audit 0.4.0 — profession filters, future craft provenance and window usability

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.4.0  
**Parent:** MODULO 1.0.48 (unchanged)  
**Baseline child:** ModuloMarket 0.3.1  
**Release class:** separate optional child addon capability slice  
**Runtime status:** source implementation PASS; 79 Python tests PASS; Lua syntax and harnesses PASS; Forever 0.4.0 runtime NOT RUN.

## 1. Player problem and observable result

The player reported:
- Market opens behind Auctionator and other addon windows.
- Market can only be opened with `/mm`.
- Escape does not close the Market window.
- The navigation buttons look like ordinary buttons rather than tabs.
- Numeric columns are too narrow and coin values wrap.
- The item list appears to stop at around 20 rows on every tab.
- The player wants profession filters and item classifications for gathering, learned crafts and future crafts.

Target result:
- Market is raised to TOOLTIP strata when shown.
- A launcher button appears on the Blizzard Auction House frame.
- Escape closes the Market.
- Tabs have a distinct tab strip and active-state underline.
- Window and item columns are wider; price/supply font strings do not word-wrap.
- The visible virtual row pool increases from 18 to 23; complete result arrays remain scrollable.
- Profession dropdown filters known recipes and market items by profession relationship.
- Known recipe outputs receive `[C]` markers.
- Source-backed unlearned recipe outputs receive `[F]` markers.
- Borrowed and unknown source data are kept visibly distinct.
- Gatherable items are marked only from explicit herb/ore/fish item-ID lists, when the character has the corresponding captured gathering profession and meets that item's minimum skill threshold.

## 2. Source of truth and evidence actually available

### Canonical parent
- `MODULO-Project-Source-1.0.48.zip`
- 41,236,015 bytes
- SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`
- 506 members; ZIP CRC PASS.
- Read: PROJECT-START-HERE, README, WORKFLOW, PROJECT-PROGRESS, PROJECT-DECISIONS, QA, SOURCE-REVIEW-LEDGER, MODULO-ARCHITECTURE and FOREVER-COMPATIBILITY-CONTRACT.
- Parent source remains unchanged.

### Child baseline
- `ModuloMarket-0.3.1.zip`
- 140,268 bytes
- SHA-256 `ba5f6a4acc649b3db6e87130a9ccd3d3e4ebdcfeb0a536b68494f82e3cc10cd8`
- 45 entries; ZIP CRC PASS.
- TOC, Core version and manifest agree at 0.3.1.
- 0.3.1 source showed `visibleCount = 18`, a reusable virtual row pool; `StepView` appends every matching row to `build.rows`; `FinishView` sets scroll-child height to `#viewRows * rowHeight`. No `MAX_ITEMS`, `MAX_ROWS`, or `rows[1..20]` truncation exists.
- The latest screenshot shows 5,221 items, consistent with the full catalogue being indexed. The apparent 20 limit is a visible-row/scroll usability problem, not a source-level result cap.
- Recipe capture still processes 20 recipe IDs per frame and continues until `#recipeIDs`; that is a bounded batch, not a terminal cap.

### Supplied installed addons
- `AddOns.zip` — 143,179,120 bytes, 5,375 entries, CRC PASS.
- Contains ProfessionMaster and WhatsTraining, but no GatherLite and no LibProfessionDB folder.
- No new Market dependency is added on ProfessionMaster, WhatsTraining, Auctionator or GatherLite.

### External recipe database research
- CurseForge LibProfessionDB 1.9.1 file ID 9095167, updated 2026-10-08, supports Forever 1.60.1.
- Its public documentation describes a Forever-specific tree with 2,511 recipes across 10 professions, `GetProfessions`, `Iterate`, `GetRecipe`, `GetCraftedItemID`, `GetRequiredSkill`, `GetRecipeSources`, `IsHiddenRecipe`, `IsAutoTaughtRecipe` and borrowed-value flags.
- Forever source data is incomplete and partly borrowed from Vanilla. Its own documentation says missing recipe sources are unknown, not proof of unobtainability; borrowed source/skill values must be flagged.
- LibProfessionDB was not present in the supplied AddOns.zip and could not be bundled from the available local sources. Integration is therefore optional and the player must install LibProfessionDB 1.9.1 separately to populate future-craft results.
- Web references: CurseForge LibProfessionDB project/file page and its 1.9.1 notes (https://www.curseforge.com/wow/addons/libprofessiondb/files/9095167).

### Gathering data research
- The supplied `AddOns.zip` contains ProfessionMaster 7.2.10. Its `models/skills/forever.lua` has an explicit "herbs, ores and fish (auto-learned based on skill level)" section with profession IDs, item IDs and skill thresholds; its `models/mining-node-contents.lua` maps secondary mining drops to their source ore nodes.
- A deterministic extraction of those Forever sections yields 66 primary herb/ore/fish outputs. The Vanilla mining secondary-drop table adds 21 item outputs; deduplication produces 87 unique item IDs.
- Each entry records the minimum skill requirement: the first (orange) threshold in the Forever skill record. Secondary mining drops inherit the lowest skill requirement of any documented source node. This is the minimum profession skill needed for the mapped source, not a guarantee of node availability at the player's current location.
- Gatherable items are enabled only when the character's captured profession summary includes Herbalism (182), Mining (186) or Fishing (356), and current skill is at least the item's threshold. Skinning remains excluded because no complete creature-to-item output/skill map was present in the supplied evidence.
- Market vendors this compact item-ID map and does not load ProfessionMaster or its SavedVariables. No GatherLite dependency is added.

## 3. Competing explanations and diagnosis of the apparent 20-row limit

1. **A hard result cap.** Source inspection contradicts this: all filtered rows are appended; no 20-row truncation exists; the scroll child is sized to the full result count.
2. **The virtualized display pool looks like a hard cap and scroll affordance is unclear.** Source and screenshot support this: only 18 reusable row buttons are created in 0.3.1 while the result count reports thousands. 0.4.0 raises this pool to 23, expands the pane, and keeps the full scroll child.

The player must confirm the list scrolls past row 23 in Forever. If it does not, that becomes a runtime defect and must be diagnosed with scroll offset/range and child-height instrumentation.

## 4. Ownership and scope

- ModuloMarket owns market-item display, profession filtering, market-to-recipe relationships, learned/future craft annotations and its own UI.
- ProfessionMaster owns profession management; Market does not use its SavedVariables or private API.
- GatherLite owns gathering. Market does not depend on it or reverse-engineer its SavedVariables. Market's own static map is limited to sourced Herbalism/Mining/Fishing item IDs with skill thresholds; Skinning is not claimed.
- LibProfessionDB is an optional external library data provider. Market does not make it a hard dependency.
- MODULO remains unchanged; MODULO does not depend on Market.

## 5. Implementation

### ProfessionData.lua
- Builds item-to-profession relationships from character-known recipes: recipe output item IDs and reagent choice IDs.
- Optionally reads LibProfessionDB through `LibStub("LibProfessionDB-1.0", true)`.
- Requires `IsReady()` and `GetGameVersion() == "Forever"` before reading its future recipe catalogue.
- Iterates profession IDs and recipes through `GetProfessions()` and `Iterate(professionID)`.
- Excludes recipes already learned by the character and those marked `IsHiddenRecipe`.
- A not-yet-learned recipe is classified as a future craft only when `GetRecipeSources` returns source data or `IsAutoTaughtRecipe` is true.
- Recipes without source data are kept in `unknownFutureCrafts`, not falsely labelled obtainable.
- `IsBorrowed(recipeID, "sources")` and `IsBorrowed(recipeID, "requiredSkill")` are preserved as uncertainty markers. Borrowed skill values are not displayed as authoritative requirements.
- Adds output and reagent relationships to the profession filter index.
- If LibProfessionDB is absent, Market remains functional and reports the exact missing provider.

### UI filters and coloring
- Profession dropdown options come from captured character professions and any available future recipe database.
- All items profession filter includes known output/reagent and supported future output/reagent relationships.
- My crafts and Profitable filter by the selected profession ID.
- Known craft outputs display `[C]`; source-backed unlearned outputs display `[F]`.
- Item-role dropdown includes All, Known crafts, Future crafts and Gatherable resources. Future crafts is disabled with an install hint when LibProfessionDB is absent; Gatherable is disabled until a supported gathering profession and skill threshold are captured.
- Gatherable items receive `[G]` markers only when the character has the corresponding captured gathering profession. The map includes explicit Herbalism/Mining/Fishing IDs; unmapped Skinning/Forever variants are not marked.

### Window
- `SetFrameStrata("TOOLTIP")`, `SetToplevel(true)` and `Raise()` when shown.
- Registers `ModuloMarketMainFrame` in `UISpecialFrames`.
- Adds a launcher button to `AuctionHouseFrame` (or legacy `AuctionFrame`) on `AUCTION_HOUSE_SHOW` and `PLAYER_LOGIN`.
- Uses a dedicated tab strip and gold selected-tab underline.
- Window expands to 1220×760.
- Scroll/list pane expands to 735×510; detail pane begins at x=790.
- Numeric price/supply columns are widened and set to no word-wrap.
- Virtual row pool increases to 23 rows. This is still a virtualized viewport, not a cap on `viewRows`.

## 6. Risks and limitations

- TOOLTIP strata intentionally places Market above normal addon frames and most tooltip-level UI; it may overlap other tooltip-strata popups. This matches the player's requested priority and requires visual acceptance.
- Auction House frame names and show event need Forever runtime confirmation.
- `UISpecialFrames` Escape behavior needs Forever runtime confirmation.
- Profession dropdown behavior uses the same `UIDropDownMenuTemplate` and helper API already present in the supplied MODULO Settings source, but the Market integration remains untested on Forever.
- LibProfessionDB is optional and absent from the provided installation. Without it, future-craft classification cannot populate. It must be installed separately.
- Future recipe acquisition source coverage is incomplete; source-borrowed and unknown records are explicitly marked.
- Gathering classification is deliberately partial: 87 sourced herb/ore/fish item IDs have minimum skill thresholds. Skinning remains NOT CLASSIFIED because an authoritative creature-to-item/skill mapping is not in the supplied evidence.
- No changes were made to the existing Auction House scanner, Replicate flow, saved snapshot, price history or recipe capture batch logic.

## 7. Tests and runtime evidence

Offline validation:
- `python -m pytest -q -p no:cacheprovider tests` — **79 passed**.
- `texluac -p` across Core, Scanner, Replicate, RecipeEngine, GatheringItems, ProfessionData, MarketUI and Diagnostics — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua ...` — **PASS**.
- `texlua tests/recipe_engine_0_3_0_harness.lua AddOns/ModuloMarket/RecipeEngine.lua` — **PASS**.
- `texlua tests/market_ui_0_2_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**, full catalogue simulation over 181 frames; front strata, ESC registration, AH launcher click, wider window, 23-row pool, tab visuals, profession filtering and visible range/scroll-to-end (`1-23 / 4002` through `3980-4002 / 4002`) asserted.
- `texlua tests/profession_data_0_4_0_harness.lua` — **PASS**, known/future/unknown/borrowed recipe source handling and Herbalism/Mining/Fishing gather filters.
- These are offline source/harness results, not Forever runtime acceptance.
Forever 0.4.0 UI, AH launcher, Escape, scroll-to-end, LibProfessionDB loading/data and visual column fit: NOT RUN.

## 8. Acceptance and exit

Player acceptance:
1. Open Auction House; click Modulo Market. Confirm Market appears without `/mm`.
2. Confirm it overlays Auctionator and other normal addon windows.
3. Press Escape; confirm Market closes.
4. Reopen Market; confirm the tab strip and selected gold underline.
5. Scroll All items beyond the 23rd row and to the bottom. Confirm result count matches the full catalogue.
6. Confirm prices do not wrap; inspect the right detail pane at normal UI scale.
7. Select a profession; confirm All items only shows related known/future output or reagent items, and My crafts only shows that profession's recipes.
8. Install LibProfessionDB 1.9.1, `/reload`, open Market and select Future crafts. Confirm known outputs are not duplicated, hidden recipes are excluded, source-backed unlearned recipes appear, borrowed sources are marked, and unknown-source counts remain explicit.
9. Open Herbalism, Mining and Fishing profession windows once; confirm Gatherable becomes available and the corresponding `[G]` items appear. Confirm unrelated gathering professions do not leak into each filter.
10. Confirm items below the current skill threshold are not marked gatherable, and Skinning remains unclassified.

**SOURCE IMPLEMENTED:** frontmost window policy, Auction House launcher, ESC registration, visual tabs, wider no-wrap columns, 23-row virtual pool, profession filters, learned/future craft tags, optional LibProfessionDB adapter, and explicit Herbalism/Mining/Fishing item-ID gathering map.

**FOREVER OBSERVED:** only the supplied 0.3.0/0.3.1 screenshots and recipe-capture messages. They establish a 5,221-item screenshot count, 49 known crafts in the earlier session and current layering/column/tab usability problems.

**NOT RUN / UNKNOWN:** all 0.4.0 Forever runtime acceptance; actual frame strata ordering; Auction House launcher lifecycle; Escape; complete scroll behavior; LibProfessionDB availability/load/data on the player's install; and unmapped Skinning gathering item outputs.
