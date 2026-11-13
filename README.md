# Modulo Market 0.9.1

**Current player milestone:** Combined UI refinement and dropdown lifecycle correction. Dropdown popups are tracked independently and explicitly dismissed when the main window hides/shows, a dropdown anchor hides, or tabs change. The table receives a stronger header rail, restrained column guides and clearer selected-row treatment. Market-history bars and labels scale to the actual graph height and include a baseline. Six tabs remain; My Crafts remains absent. No market calculations, scanning, recipe/gathering data, SavedVariables or parent MODULO code changed. 0.9.1 Forever runtime acceptance is NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.9.1.md` and `docs/MODULOMARKET-UI-VISUAL-REDESIGN-0.9.1.md`.

## Current 0.9.1 milestone — coordinated UI and lifecycle pass

- Dropdown popup frames are parented to `UIParent`; the previous main frame lacked an `OnHide` cleanup. Every dropdown is now registered and closed from the main-frame lifecycle, dropdown-anchor hide, and tab changes.
- Table: dark inset header rail, subtle bronze column guides, clearer selected row and less visually noisy alternating surfaces.
- Market History: baseline added; bar height and percentage-label position derive from the graph's actual height.
- Preserve dropdown option values, disabled choices, callbacks, six tabs, table row height/virtualization, sorting, history points, market formulas, scan behavior and all data.
- 0.9.0 screenshot is FOREVER OBSERVED for the visible 0.9.0 surfaces on client build 70938. 0.9.1 runtime acceptance remains NOT RUN.
- Offline tests and package evidence are recorded in `MODULOMARKET-RUNTIME-AUDIT-0.9.1.md`.

## Historical 0.9.0 milestone — combined Dark Foundry pass

**Current player milestone:** Combined Dark Foundry visual refinement based on the player's 0.8.9 Forever screenshot. The header's ForeverDB summary is concise while full detail remains available through the status tooltip; dropdown menus suppress stale control tooltips and use tighter option rows; the Relationships inspector gains viewport height; Market History is rebalanced with a smaller graph and retained history text. Six tabs and all existing data, filters, market calculations, scan behavior and SavedVariables remain unchanged. Forever runtime acceptance for 0.9.0 is NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.9.0.md` and `docs/MODULOMARKET-UI-VISUAL-REDESIGN-0.9.0.md`.

## Current 0.9.0 milestone — combined visual refinement

- Header/status: shortened the ForeverDB provenance summary to fit the status rail; the complete provider detail remains available in the existing status tooltip.
- Dropdowns: hide the dropdown help tooltip as soon as the menu opens and when it closes; option rows are slightly more compact. Selected option, disabled state, popup, and callbacks are unchanged.
- Inspector: Relationships viewport grows from 106px to 124px. Market History card is reduced from 224px to 206px, with a shorter graph area; history text and four-point graph remain.
- Preserve the six-tab structure, My Crafts absence, filters, market data, recipes, gathering, calculations, scanning, SavedVariables, dependencies and ForeverDB attribution.
- The 0.8.9 screenshot is FOREVER OBSERVED evidence for 0.8.9 only. It confirms dropdown colours and shows the long status summary and tooltip/menu overlap; it does not prove 0.9.0 behavior.
- Offline verification: focused visual regressions 6 PASS; full suite 246 PASS / 61 historical failures with identical failing IDs to 0.8.9; Lua syntax 9/9 PASS. Forever runtime NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.9.0.md`.

## Historical 0.8.8 milestone — Dark Foundry visual finish
**Current player milestone:** Dark Foundry visual finish pass for the All Items workspace. 0.8.8 strengthens the shared three-panel surface treatment, fitted panel-header rails, selected/inactive tab contrast, table header band and selected-row emphasis while preserving the 0.8.7 geometry and all market behavior. Six tabs remain; My Crafts remains absent. No recipes, gathering mappings, market calculations, scan behavior, SavedVariables or parent MODULO source changed. Forever runtime acceptance of this visual pass is NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.8.md`.

## Current 0.8.8 milestone — Dark Foundry visual finish

- Added subtle inset top sheen and lower shadow treatment to the three main panels without changing their dimensions or positions.
- Refined panel header rails with brighter upper metal edges, darker lower bevel rules and small end caps.
- Increased active-tab face contrast and gold label emphasis; darkened inactive faces and softened their label color for clearer state hierarchy.
- Strengthened the central table heading band and selected-row wash while preserving existing row positions, density, sorting, values and virtual-row behavior.
- Kept the existing six tabs, My Crafts absence, filter semantics, three-column geometry, inspector layout, status/provenance truthfulness and all existing controls.
- No new textures/assets, APIs, dependencies, SavedVariables, data, market formulas, scan acquisition or specialist-addon changes.
- Offline verification and runtime limitations are recorded in `MODULOMARKET-RUNTIME-AUDIT-0.8.8.md`.



## Historical 0.8.6 milestone — validated ForeverDB 70938 catalogue refresh

- Captured and verified 34 raw ForeverDB API responses for client build 1.60.1.70938; all 12 professions and reported recipe totals reconcile.
- Normalized and validated 2,493 recipe records: 2,310 item outputs, 183 non-item/unknown outputs, 143 speculative records retained in canonical data and excluded from runtime as before.
- Semantic comparison with 70888: zero recipe additions, removals or changed records across all 12 professions; trainer and profession records are unchanged. Provider metadata advances items 23,634→23,679, quests 6,647→6,655, vendors 969→974 and articles 219→221.
- Regenerated runtime Lua with the embedded repository compiler. Runtime payload preserves full acquisition-source rows, `learnAtSkill`, `trainerCostCopper` and `trainerCostEvidence`; its profession payload is byte-identical to the 70888-generated payload. Only build/capture provenance metadata changes.
- No UI, market calculations, scan behavior, SavedVariables schema, or parent MODULO changes. Existing exact-build auction snapshot gate remains unchanged.
- Offline verification: canonical validation PASS; embedded compiler PASS; focused 0.8.6 data regression PASS; full historical suite 236 PASS / 61 unchanged baseline failures; Lua syntax 9/9 PASS; compatibility and profession-capture harnesses PASS; fresh-extraction and archive checks recorded in the 0.8.6 audit. Forever runtime NOT RUN.

## Historical 0.8.5 milestone — Forever 70938 compatibility diagnostics

- Added `/mmcompat`, a read-only compatibility report. It records client version/build/date/interface, saved Full Market snapshot source/schema/build/timestamp/counts/completion, exact snapshot compatibility, bundled ForeverDB build/status and availability of the Auction House Replicate/Browse, C_Item and C_TooltipInfo functions.
- The report inspects `MM.db.lastMarketSnapshot`, not the separate Browse Scan snapshot. It sends no Auction House requests, does not scan, and does not mutate saved state.
- The All Items status now explains how to replace a missing/mismatched Full Market snapshot: open the Auction House, choose Update Full Market, confirm, and wait for completion.
- The exact snapshot-build gate is unchanged. No mismatch bypass, build allow-list, synthetic compatibility or automatic scan was added. The previous complete snapshot remains until a complete replacement is committed.
- The bundled ForeverDB catalogue remains provenance-labelled build 1.60.1.70888; no unverified 70938 catalogue was fabricated. No recipe/item data, market calculations, acquisition logic, SavedVariables schema, parent MODULO source or UI redesign changed.
- User screenshot evidence shows the 0.8.4 All Items interface rendering on Forever 1.60.1 build 70938. It does not prove `/mmcompat` or full-scan behavior.
- Offline verification: focused regressions 76 PASS; full historical suite 235 PASS / 61 unchanged failures compared with the clean 0.8.4 baseline (zero new failing test IDs); Lua syntax 9/9 PASS; compatibility harness PASS; profession capture harness PASS. Fresh-extraction focused tests 76 PASS; full suite 235 PASS / 61 unchanged baseline failures; Lua syntax 9/9 PASS; both harnesses PASS; ZIP CRC PASS; fresh extraction PASS; manifest 161/161; versions aligned 0.8.5. Forever runtime `/mmcompat`, 70938 Full Market rescan and profitability recovery remain NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.5.md`. Forever `/mmcompat`, 70938 Full Market rescan and craft-profitability recovery are NOT RUN.

**Current player milestone:** Consolidated Dark Foundry visual redesign across the header/window frame, six-tab navigation, left filters, centre market table and selected-item inspector. The redesign adds layered bronze/gold bevels, inset surfaces, clearer active-tab treatment, a table heading band and selected-row accents while preserving the existing six tabs, control behavior, market calculations, recipe data and SavedVariables schema. Forever runtime acceptance for 0.8.4 is NOT RUN.

## Current 0.8.4 milestone — consolidated Dark Foundry visual redesign

- Replaced the minimal title rectangle with a wider, layered dark/gold title plaque and a structured header rail. Existing market metadata, truthful scan states, action buttons, status text and whole-window opacity behavior remain the sources of truth; no fabricated progress percentage was added.
- Added a layered outer window edge, stronger inset panel bevels, warmer panel heading plates and a dedicated inset Data card surface. The existing three-column geometry and panel positions remain unchanged.
- Restyled the six existing navigation tabs with state-aware bronze/gold bevel edges and clearer selected-state contrast. No tab was added or removed; My Crafts remains absent.
- Applied a shared dark/gold button skin to market action buttons and the existing custom dropdown controls while preserving the dropdown's local popup/click implementation. Profession, Item role, Item Types, Options and Data semantics remain unchanged.
- Added a distinct centre-table column-heading band, more legible alternating row surfaces, and a gold selected-row wash/accent. The 24px row height and 25-row virtual pool remain unchanged.
- Reframed the selected-item inspector cards and added a dark/gold mount around the existing selected-item icon. Existing inspector data, scrolling and history rendering remain unchanged.
- Preserved market calculations, snapshot provenance, recipe data, SavedVariables, scan behavior, filters, tab state, sorting, tooltips and all market data sources. Parent MODULO 1.0.48 is unchanged.
- Offline verification: focused regressions 72 PASS; Lua syntax 9/9 PASS; profession capture harness PASS. Full historical suite: 231 PASS / 61 unchanged legacy or superseded failures; comparison with the 0.8.3 baseline found no new failing test IDs. ZIP CRC PASS; manifest 157/157; fresh extraction and fresh-extraction focused checks PASS; TOC/Core/manifest/README all 0.8.4. Forever runtime NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.4.md`.

## Subsequent 0.8.3 Forever visual observation

After the 0.8.3 package was built, the user supplied an in-game screenshot showing the All Items screen running on Forever 1.60.1 build 70888. This confirms that the 0.8.3 All Items window rendered in that environment. It does not establish acceptance of every control, tab, filter/API path, or the 0.8.4 redesign. The original 0.8.3 audit's NOT RUN status records the state at its package handoff and is retained as historical provenance.

## Previous 0.8.3 milestone — All Items visual refinement

- Restored a distinct **Item Types** dropdown beneath **Item role** on All Items. Item role continues to filter profession/gathering/material relationships; Item Types filters the client's item class.
- Added grounded item-class groups: All item types, Consumables (class 0), Equipment (Weapons class 2 and Armor class 4), Trade Goods (class 7), and Other item classes. These class IDs are consistent with the existing class-aware Low Supply threshold logic.
- Reads item class IDs from the existing `C_Item.GetItemInfo` result or the legacy `GetItemInfo` classID return. It does not infer type from item names. Items without loaded/available class metadata are omitted only when a specific type is selected; All item types retains the full market view.
- Item-class metadata requests are queued and capped at ten attempts per frame. Existing `GET_ITEM_INFO_RECEIVED` / `ITEM_DATA_LOAD_RESULT` events update the cache and schedule a single debounced All Items rebuild. Failed or unavailable metadata is marked unclassified rather than repeatedly requested.
- The Item Types control is intentionally shown only on All Items. Other tabs retain their own specialist filters without overlapping controls.
- Moved the All Items quick options below the new type selector and moved the Data card down to preserve spacing and keep Crafting Scope inside the card.
- Added a dark/gold title plaque and aligned the main title. Increased key table, filter and inspector text sizes by a restrained amount without changing the 24px market row height or 25-row virtualized table.
- Enlarged the selected-item icon to 48px, improved inspector row typography, and retained the existing scrollable Relationships section and expanded Market History graph.
- Preserved the six existing tabs, market columns, search, sort, row selection, tooltips, scan behavior, quick-filter semantics, auction/recipe provenance, calculations and SavedVariables.
- No new addon dependency or parent MODULO change. Parent MODULO 1.0.48 remains unchanged.

Offline verification: focused regressions 65 PASS; fresh-extraction regressions 65 PASS; Lua syntax 9/9 PASS; fresh-extraction Lua syntax 9/9 PASS; profession capture harness PASS. Full historical suite: 224 PASS / 61 legacy or superseded failures; compared with 0.8.2, one historical geometry assertion now passes and no new failing test IDs were introduced. ZIP CRC PASS; manifest 154/154; fresh extraction PASS; versions aligned 0.8.3. Forever runtime NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.3.md`.

## Previous 0.8.2 milestone — All Items mockup alignment

- Reworked the top header to reduce competing data labels; retained market snapshot summary, scan state, scan controls and window opacity.
- Moved Auction Data, Recipe Data, review-record count and Crafting Scope into a dedicated Data card in the left filter panel.
- Corrected auction build identity comparison by comparing the trailing numeric build component, so `70888` and `1.60.1.70888` identify the same client build.
- Added four All Items quick filters with actual source-grounded behavior: crafting materials only, low supply only (same item-aware threshold as Low Supply tab), high profit only (positive calculated best-craft auction profit), and explicit review items only (recipe records marked `freshnessStatus == "review"`).
- Quick filter state is retained per tab. High Profit builds the existing recipe economics index before filtering.
- Split selected-item Relationships into explicit Crafting and Gathering rows. Gathering profession labels use existing item-ID mappings only; unmapped items say "No mapped source".
- Shortened the Relationships card and expanded Market History, retaining the existing saved-history points and graph.
- Preserved all six tabs, market columns, search, sorting, tooltips, opacity, auction scan behavior, recipe/provider data, calculations, and SavedVariables schema.
- No new addon dependency; parent MODULO 1.0.48 remains unchanged.

Offline verification: focused regressions 51 PASS; Lua syntax 9/9 PASS; profession capture harness PASS. Full historical suite: 214 PASS / 62 legacy or superseded failures. Forever runtime NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.2.md`.

## Previous 0.8.1 milestone — All Items visual foundation


- Reorganised the existing Selected Item inspector into three bordered sections: Market Information, Relationships and Market History.
- Kept the existing market identity, sale price, listed quantity, at-price quantity, best-craft-profit, relationship, acquisition/context and saved-history sources.
- Made the relationship detail area scrollable so long recipe/gathering evidence is not forced into a fixed-height text block.
- Added header labels for auction snapshot build and age, recipe dataset build/status and review count, sourced from existing snapshot/provider metadata.
- Added a scan-state label based only on existing Replicate state. No percentage progress is shown because the current Replicate state contract exposes no progress percentage.
- Retained the existing six tabs. No My Crafts tab was reintroduced.
- Retained the existing All Items table columns, search, filters, selection, sort, item tooltips, history data and opacity behavior.
- Parent MODULO 1.0.48, market/recipe data, price calculations and SavedVariables schema are unchanged.

Offline verification: focused regressions 34 PASS; Lua syntax 9/9 PASS; profession capture harness PASS. Full historical suite: 203 PASS / 65 legacy or superseded failures. Forever runtime NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.8.1.md`.

## Previous 0.8.0 milestone — Root Tea status integrity


- Removed six downstream fail-open defaults that promoted missing recipe status to `known`.
- Added one status normalizer allowing only `known`, `learnable`, `unlearnable` and `unknown`.
- Best-craft context says “Recipe known by this character” only for explicit `known` evidence.
- Preserved the four-case Root Tea account/character acceptance matrix.
- Snapshot schema 2 and automatic profession capture remain unchanged.

See `MODULOMARKET-RUNTIME-AUDIT-0.8.0.md`.

## Previous 0.7.9 milestone — snapshot schema and scope isolation

**Current player milestone:** Character and account recipe recognition are isolated. Future recipe candidates are copied before scope-derived status is assigned, and only an actual learned snapshot record can assert `KNOWN`. Each profession snapshot carries a schema version, generation and addon-build provenance. Snapshots from older schemas are retained but are not treated as positive learned evidence until that character's profession is automatically recaptured. Forever runtime acceptance is NOT RUN.

## Current 0.7.9 milestone — snapshot schema and scope isolation

- Account and Character Crafting cannot share cached `KNOWN` markers through the future-recipe catalogue.
- Future candidate status is derived from current profession evidence; UI status is never written back into ProfessionData's shared candidate objects.
- A future candidate is only `KNOWN` when `learned == true` in an actual learned-recipe record.
- Each completed profession capture records `snapshotSchemaVersion`, `snapshotGeneration` and `snapshotBuild`.
- Recipe records from older schemas remain stored for recovery/history but are excluded from `GetAllRecipes` until recaptured.
- Incomplete recaptures preserve an older snapshot only when it already uses the current schema; stale-schema records are not merged into the new snapshot.
- UI-only addon releases do not bump the snapshot schema or force a recapture.

See `MODULOMARKET-RUNTIME-AUDIT-0.7.9.md`.

## Current 0.7.8 milestone — reliable character profession snapshots

- Reopening a profession forces a fresh recipe capture even when the recipe-ID signature matches a previously saved capture.
- Recipe records whose `GetRecipeInfo` result is temporarily unavailable are retried over bounded update passes (up to four observations).
- If recipe metadata remains unavailable, the previous complete snapshot is preserved and the failure is exposed in diagnostics; a partial pass is never committed as complete.
- Current profession skill and maximum skill from `C_TradeSkillUI` are saved as higher-priority evidence than the legacy `GetProfessions` skill tuple.
- Per-character profession evidence is merged rather than replaced, preserving other professions and characters' snapshots.
- Successful capture prints a concise confirmation with profession, recipe count and skill.

See `MODULOMARKET-RUNTIME-AUDIT-0.7.8.md`.


## Current 0.7.7 milestone — responsive automatic search and Sell-only launcher

- Search starts after 0.35 seconds of typing inactivity; Enter submits immediately.
- Search work is generation-scoped so older view/warmup passes cannot overwrite a newer query.
- Tooltip inspections are capped at 30 per frame, item-data requests at 10 per frame, and warmup visits at 10 items per frame. Cached tooltip text is reused.
- Launcher attaches only to the classic Blizzard AuctionFrame and is shown only while its native Sell tab (tab 2) is selected; it hides on all other tabs and fails closed when selection cannot be established.
- If Forever runtime testing shows unacceptable lag, revert the typing path to explicit Enter submission without changing tooltip matching.

See `MODULOMARKET-RUNTIME-AUDIT-0.7.7.md`.

## Current 0.7.6 milestone — first-open filter visibility and complete tooltip loading

- Normal typing no longer initiates tooltip loading. Press Enter to submit the expanded tooltip/effect search.
- Shows immediate name/reagent matches while descriptions load; the final pass adds tooltip-only matches.
- Reuses normalized tooltip cache and checks client item-cache state where supported.
- Avoids treating `GetItemInfo` as a reliable asynchronous request fallback when the explicit item-data request API is unavailable.
- Services the tooltip warmup watchdog independently from other update queues.
- `/mmsearchdebug` reports the request lifecycle so a client retest can distinguish missing API, missing events, cache hits and timeout behavior.
- Forever runtime acceptance remains NOT RUN; the 0.7.3 permanent-loading report remains open until the player retests.

See `MODULOMARKET-RUNTIME-AUDIT-0.7.6.md`.

# Modulo Market 0.7.3
**Current player milestone:** My Crafts and All Crafts are consolidated into Crafts. Recipe status is character-aware: known by you (green), learnable through a profession you have (gold), not learnable because the native profession list confirms you lack the profession (red), or Unknown when ownership cannot be established (also red; internal status remains distinct). Materials shares the same status filters and includes the core leather/hide Skinning tiers. Economics is now a distinct market-analysis view with cheapest price, craft cost, saved price movement, total units, best craft profit and relationship filters. Drop/loot and vendor-origin filters remain disabled because the available provider records describe recipe acquisition, not a complete item-origin catalogue. Forever runtime acceptance is NOT RUN.



## Current 0.7.3 milestone — single-pass tooltip search warmup

- Tooltip search now records unresolved item IDs during one catalogue pass, requests missing item data in bounded batches, waits for those requests, then performs one final search pass against the populated normalized cache. Individual item-data events no longer trigger full catalogue rebuilds.
- Missing item-data responses time out after 15 seconds and fail closed for that search rather than cycling indefinitely.
- Unknown and Not Learnable recipe names are red in both the Crafts list and selected-recipe inspector; their internal status and filter semantics remain distinct.
- Forever runtime acceptance remains NOT RUN pending the player's retest on build 70888.

See `docs/MODULOMARKET-SEARCH-PERFORMANCE-0.7.1.md` and `MODULOMARKET-RUNTIME-AUDIT-0.7.3.md` for diagnosis and acceptance.

## Current 0.7.2 milestone — deferred tooltip refresh

- Tooltip item-data refreshes were deferred while a view build or sort was active. Runtime retest showed that repeated follow-up full searches still occurred, so this implementation is superseded by 0.7.3's pending-item warmup queue.
- Unknown and Not Learnable recipe labels both use red in the inspector; 0.7.3 also fixes the Crafts row renderer.
- Forever runtime acceptance remains NOT RUN.

## Current 0.7.0 milestone — tooltip search, account/character crafting scope and Economics layout

- Search now extends beyond names and IDs to loaded item tooltip descriptions/effects. Tooltip text is cached per item, with bounded per-frame inspections and asynchronous item-data requests; item-data completion restarts the active search. Missing tooltip data is not treated as an authoritative no-match until loaded.
- Added a persistent Account Crafting / Character Crafting selector in the unused top-right header space. Account mode unions learned recipes and positive profession evidence across characters saved in `professionRecipesByCharacter`; absent evidence for any other character remains Unknown, never Not learnable. Character mode uses only the logged-in character's captured recipes and native profession list.
- Current character native profession snapshots are saved when the API list is readable. Existing character recipe records remain keyed by realm and character; no recipe data is migrated or relabelled.
- Economics right-hand columns now size from their visible header/value widths and are anchored from the right edge; Item receives the remaining centre-panel width.
- No API requests, ForeverDB dataset, market snapshot, price formula, or parent MODULO dependency changed.
- Offline source/harness tests and Lua syntax checks only. Forever runtime acceptance is NOT RUN; tooltip API support, asynchronous search refresh, character switching, account union, and responsive column sizing require in-game validation.

See `docs/MODULOMARKET-PROFESSION-STATUS-AND-ECONOMICS-0.6.9.md` for scope and acceptance.
See `docs/MODULOMARKET-ROW-STATUS-PRESENTATION-0.6.8.md` for scope and acceptance.


**Current player milestone:** 0.6.5 preserves and exposes the individual ForeverDB acquisition-source records in the runtime catalogue and selected-recipe inspector. Trainer/vendor NPCs, locations, coordinates, vendor costs, limited-stock metadata, recipe items, drops and quests retain their field-level evidence. Known character recipes are enriched without duplication. Forever runtime acceptance is NOT RUN.


## Current 0.6.5 milestone — acquisition-source detail preservation

- The 1.60.1.70888 canonical dataset already contains 10,369 individual acquisition-source records across 2,493 recipes: 4,137 `FOREVER_OBSERVED`, 2,292 `CLASSIC_BORROWED`, 3,907 `UNKNOWN` and 33 `FOREVER_CLIENT`.
- The runtime compiler now preserves source type/name, faction, NPC identity/title, zone/map/coordinates, vendor copper or currency costs, stack/limited-stock/reputation metadata, recipe-item identity/visibility, drop identity/chance, quest identity and source/evidence text.
- Known character recipes can retrieve their matching ForeverDB acquisition details by profession and recipe ID without adding duplicate craft rows. Unlearned candidates retain their individual source rows.
- The inspector shows up to three prioritized source records; hovering the recipe displays the full source list. Unknown recipe-to-NPC links remain unknown even if the NPC itself was observed. Classic-borrowed records remain visibly unconfirmed.
- No new API requests, keys, dependencies or parent MODULO changes. The canonical 70888 dataset is unchanged; only its runtime compilation and presentation are expanded.
- Runtime catalogue Lua grew from approximately 1.54 MB to 5.04 MB. Load-time and memory impact require Forever client observation.
- Offline tests and harnesses do not establish Forever runtime behavior. Forever runtime acceptance is **NOT RUN**. See `docs/FOREVERDB-ACQUISITION-SOURCES-0.6.5.md`.

## Current 0.6.2 milestone — async renderer safety and layout correction

- Guards the virtualized row renderer until the first row and scroll child exist; bounds iteration to the actual row pool and checks every row button. This addresses the reported ProfessionMaster item-data callback stack at `MarketUI.lua:1077` without changing the asynchronous event or ProfessionMaster.
- Rebalances the three-column workspace: centre 834px, right inspector 300px, 812px scroll viewport/rows, and 166px craft Materials (cost) column. Market and Materials columns are repositioned to align with the expanded table.
- Places Filters, centre tab title, Selected Item/Recipe and result count within their panel header strips. Inspector text is constrained to 268px and wraps within its border.
- Displays captured skill-up colours in the selected recipe/item inspector with evidence separation. Coarse Grinding Stone shows Forever-client Orange/Yellow 50, Green 70, Grey 90; Classic orange 75 remains separately borrowed and unconfirmed. These are skill-up thresholds, not trainer learning requirements.
- Offline regression suite: 172 passed; nine addon Lua files parse. Forever runtime remains NOT RUN until the user validates ProfessionMaster initialization, all tabs, layout and Coarse Grinding Stone details.




**Retained product capabilities:** six distinct market views; automatic item, recipe and material economics; known/future recipe-state de-duplication; asynchronous vendor-value loading through both supported client item-data events; clearly explained item-role filters; role-aware gathering/material classification; price-change history; adjustable background opacity; draggable minimap launcher; frontmost, ESC-closeable window.

Modulo Market is a separate optional child addon under MODULO.

## Project repository and ForeverDB attribution

Source repository: https://github.com/moonlitfarewell/modulo-market

Current ModuloMarket 0.6.5 uses a reviewed ForeverDB recipe dataset from client build `1.60.1.70888`; the prior `1.60.1.70862` canonical file is retained for historical comparison. The in-game Market window visibly credits [ForeverDB.net](https://foreverdb.net). ForeverDB API keys are build-time importer credentials only and are not committed or distributed inside the addon. The raw capture and normalized canonical dataset are retained under `data/` for provenance and reproducible builds.

 It depends on `Modulo`; MODULO does not depend on Market. Auctionator and ProfessionMaster remain independent addons and are not runtime dependencies.




## Current 0.6.1 milestone — ForeverDB 1.60.1.70888 data refresh

- Replaced the active compact runtime catalogue with a freshly normalized ForeverDB dataset for client build `1.60.1.70888`; retained the previous `1.60.1.70862` canonical file unchanged for provenance.
- The new capture contains the same 12 professions and 2,493 recipe IDs; no recipe IDs were added or removed. A field-level comparison found 200 changed records: 185 acquisition-source records, 28 provider-metadata records and one skill record (overlapping categories).
- Blacksmithing Coarse Grinding Stone (recipe 3326) now uses captured green 70 / grey 90 thresholds. Its orange threshold remains Classic-borrowed and is not promoted. Its old hotfix review flag is retired for the now-refreshed skill-up field.
- Three unchanged hotfix-linked records remain flagged for review: Journeyman Campfire, Minor Arcane Elixir and Iron Grenade.
- Exact current-client recipe data does not relax the independent exact-build auction snapshot gate. Old market prices remain withheld until a 1.60.1.70888 snapshot is available.
- Forever runtime acceptance is NOT RUN. See `docs/FOREVERDB-DATA-REVIEW-2026-11-12.md`.

## Current 0.6.0 milestone — Dark Foundry workspace completion

- My Crafts and All Crafts now show dedicated craft filters: craftable only, profitable only, explicit review-only and hide non-profitable. Their definitions are evidence-aware: craftable requires a known recipe, a resolved output and complete reagent cost; profitable requires a positive calculated profit; review-only requires an explicit `freshnessStatus=review`; hide non-profitable hides calculated zero/negative profit while retaining incomplete-profit rows.
- The All Crafts/ My Crafts centre table now uses an ingredient-led Materials (cost) column with real reagent icons and quantities plus the calculated material cost. Hovering the column shows every reagent, quantity, line cost and total material cost.
- The right inspector is automatically populated with the first result when a tab has no prior selection. Returning to a tab restores its previous selected item/recipe when it remains in the filtered result set; otherwise it selects the first matching row.
- Craft inspection now explicitly shows at-price quantity, total listed units, acquisition classification and material cost alongside the existing sale, reagent, profit and warning information.
- Craft-specific table columns are laid out independently from item-market columns; switching between craft and non-craft tabs restores the correct positions.
- Existing tab data, non-craft table columns, Materials Listings removal, tooltips, opacity, recipe baseline provenance and exact-current-build auction gate remain unchanged.
- Forever runtime acceptance is NOT RUN until the user checks all seven tabs, tab-specific filter behavior, row selection restoration, materials hover detail and the full selected-recipe panel in-game.

## Current 0.5.9 milestone — Dark Foundry visual polish

- Real client item icons appear in virtualized market and recipe rows when item data resolves; unresolved icons use a temporary question-mark fallback and are retried on item-data completion.
- Recipe reagent details show the actual reagent item icon beside the reagent identity and quantity.
- The selected-entry panel has a larger item icon, clearer title hierarchy, and contextual Known/Future/Borrowed/Unknown plus Baseline/Review badges derived from the underlying record.
- Alternating low-contrast row surfaces, more legible row/header typography and bronze panel header plates improve scanning without changing the three-column layout.
- All seven tabs, existing tab-specific information, filters, global market controls, tooltip layering, whole-window opacity, baseline-plus-delta recipe data and exact-current-build auction snapshot gate remain intact.
- Forever runtime acceptance for the visual changes is NOT RUN until the user confirms icon resolution, panel appearance, and tab parity in-game.

## Current 0.5.9 milestone — Market remains below native tooltips

- Corrected the open/raise lifecycle: the Market is explicitly kept at DIALOG strata, while native and addon tooltips remain at TOOLTIP. The 0.5.7 `UI.Raise()` path had inadvertently promoted the Market to TOOLTIP after creation.
- Added regression coverage for the complete raise path and corrected legacy harness expectations.
- Forever runtime acceptance remains NOT RUN until tooltip-over-window behavior is confirmed in-game.

## 0.5.7 milestone — hover inspection, true window opacity and tab-specific columns

- The Market frame uses DIALOG strata while GameTooltip and dropdown menus use TOOLTIP strata, so hover help is not trapped behind the Market window.
- Hovering recipe/item rows opens item or recipe spell tooltips when the client exposes the relevant tooltip API; the selected-entry name and recipe metadata also have dedicated hover targets.
- Search, profession and recipe-source/item-role controls expose explanatory hover text; future/borrowed/unknown option definitions remain available on their dropdown entries.
- The opacity slider now applies alpha to the entire Market window (panels, controls, text and frame contents), not only template background textures. Tooltips remain independent overlays.
- Materials no longer spends a table column on Listings; Best Craft Profit moves into that column. Other tabs retain their own listing information.
- Subtle bronze panel outlines reinforce the Dark Foundry three-column workspace without changing any tab's underlying data model.

## Current 0.5.6 milestone — Dark Foundry workspace and profession capture cache

- Market window reorganized into a persistent three-column workspace: global market toolbar, seven full-width tabs, contextual left filters, full-width tab data in the centre, and selected-entry inspection on the right.
- Existing tab views, market actions, recipe provenance and exact-current-build auction snapshot gating are retained.
- All Crafts now has distinct Sale / Unit, Materials, At Price, Total and Profit / Craft columns. At Price shows quantity available at the lowest ask; Total shows total listed quantity.
- Search, profession and item-role filters are retained independently per tab.
- Known-profession capture stores a signature of the profession recipe-ID list. Repeated trade-skill events with an unchanged list no longer start a full schematic capture or repeat the capture chat message. A changed list triggers capture so newly learned recipes remain detectable.
- Capture events are coalesced over a short delay; the persisted signature is character- and profession-scoped in the existing profession SavedVariables store.

## Current 0.5.5 milestone — baseline-plus-delta ForeverDB compatibility

- Login chat announces the installed ModuloMarket version and current client build.
- `/mmversion` prints the addon version, client build and ForeverDB dataset load state.
- The Market footer displays the addon version and detected client build.
- The bundled ForeverDB 1.60.1.70862 dataset loads as a clearly labelled baseline on client build 1.60.1.70888; the original source build is never relabelled.
- Four recipe records associated with reported November hotfixes are individually flagged for review; unrelated records remain usable baseline data. These flags are advisory and do not assert that the whole recipe is wrong.
- Auction snapshot pricing remains gated to the exact current client build, so old auction prices are never reused on a newer build.

## 0.5.3 milestone — ForeverDB recipe data integration

The 11 November 2026 ForeverDB capture is complete and verified: 34 API responses, 12 professions and 2,493 recipe records for build `1.60.1.70862`. The canonical normalized JSON is retained in `data/`; the user-supplied raw capture remains a separate input and is not committed to the public repository. `AddOns/ModuloMarket/ForeverDBData.lua` is generated from the canonical file by the developer importer.

Historical 0.5.3 behavior required an exact dataset/client build match. Since 0.5.5, the imported catalogue loads as a provenance-preserving baseline when the client build is identifiable; a build difference no longer invalidates every recipe. Individually identified hotfix-linked records are flagged for review. Craft economics still requires the saved Browse/Replicate market snapshot's `clientVersion.clientBuild` to match the current client build, so old auction prices are never joined to a newer client. The optional LibProfessionDB adapter is used only when no bundled ForeverDB dataset exists.

### Data and evidence rules

- Recipe structure, item outputs, `makes.count`, reagent item IDs/counts and client skill thresholds are labelled `FOREVER_CLIENT`.
- Trainer/vendor rows with `seenInForever=true` are `FOREVER_OBSERVED`; rows with `seenInForever=false` are `CLASSIC_BORROWED`.
- Inferred trainer teaching edges, drops and quests without per-row observation evidence, and recipe-item acquisition paths without an obtainable source are retained as `UNKNOWN`.
- Automatic learning is retained as a client acquisition signal.
- Orange skill-up thresholds sourced from Classic remain `CLASSIC_BORROWED`; they are never treated as trainer learning requirements.
- The capture exposes one `makes.count` per item output, not separate random min/max ranges. The adapter records that count as a fixed captured count and does not invent a yield range.
- The captured reagent arrays have one item/count per row and expose no optional or alternative flags. The adapter does not invent alternatives.
- Speculative records remain in canonical source data but are excluded from the runtime craft catalogue. Enchantments and records without item outputs are not treated as item crafts.
- Known character recipes are de-duplicated against the imported catalogue by profession/recipe ID and profession/output/name.

The compact runtime file contains only the fields currently consumed by the recipe/material/economics layer. Full trainer, vendor, quest, drop and provenance detail remains in the canonical JSON. The current UI does not yet expose every trainer/vendor location or purchase-cost record.

### Runtime and acceptance

The importer, canonical adapter, compact compiler, baseline-plus-delta loader and source-index integration have offline regression coverage. These are source/offline checks only. Forever runtime verification of the data loader, baseline warning, UI attribution and recipe economics remains **NOT RUN** until the user tests it in Forever.

## Open Market

- `/mm` opens or closes the Market.
- A **Modulo Market** launcher button appears on the Auction House frame when its UI is available.
- A draggable minimap coin button opens Market with a left-click.
- The Market window is registered with `UISpecialFrames`, so Escape closes it.
- The window uses DIALOG strata and is raised when opened, placing it above normal addon panels while keeping native TOOLTIP strata available to hover tooltips.
- `/mmscan` opens the retained Browse-summary scanner and JSON export tools.
- `/mmdebug` opens read-only API/profession diagnostics.
- `/mmversion` prints the installed ModuloMarket version, current client build and ForeverDB dataset load state.

## 0.3.0 player experience

Market now replaces the manual cost-entry workflow with automatic recipe economics.

### All items

The main market catalogue remains one row per item ID, grouped from the saved Browse or full-market snapshot.

Selecting an item shows:
- current lowest unit ask and total listed supply;
- recipes that create the item;
- recipes that consume the item;
- estimated craft profit where all required prices and quantities are known.

This makes a material search useful: select Ore or Cloth and see which captured recipes consume it; select Bars or Bolts and see which captured recipes produce it.

### My crafts

Market automatically watches the character's profession window. When a profession list is opened or updated, it captures the known recipes and their client-provided reagent/output schematics in bounded batches of 20 recipes per frame.

Captured recipes are stored under the current character key (`realm:character`) in `ModuloMarketDB.professionRecipesByCharacter`. Opening each profession once seeds that character's known-recipe catalogue. Later profession-window updates refresh the captured profession. No cost, reagent, cooldown or profit values are manually entered.

The craft list shows:
- crafted item and profession;
- market sale price per output unit;
- reagent cost per craft;
- estimated profit per craft after the configured Auction House cut.

### Profitable

This tab contains only captured crafts whose output has a market price, every required reagent has a known market price/quantity, output quantity is known, and estimated profit is positive. It is ranked by profit per craft.

Loss-making crafts remain visible in **My crafts**, so the player can see what is not worth making.

### Automatic cost calculation

For each recipe:
1. Read the recipe's required reagent slots from the client schematic.
2. Ignore slots explicitly marked optional.
3. Multiply each required reagent quantity by its lowest saved market unit price.
4. If a reagent slot permits alternatives, choose the cheapest alternative only when every alternative has a known market price.
5. Multiply the output's current lowest unit ask by the recipe's minimum output quantity.
6. Apply the configured AH cut (default 5%) to the gross output value.
7. Subtract total reagent cost from net sale proceeds.

`profit per craft = floor(output units × lowest ask × (1 − AH cut)) − total required reagent cost`

The minimum output quantity is used for variable-yield recipes, and the detail panel says so. A missing reagent price, missing quantity, variable reagent quantity, unknown output quantity or missing sale price is never silently treated as zero. Incomplete recipes do not enter the Profitable tab.

These are estimates from current lowest asks, not guaranteed sale prices. They do not include posting deposits, sale probability, undercuts, or market movement between scan and sale.

### Low supply and price history

- **Low supply** retains the 0.2.0 item-ID-level combined quantity threshold (default 5).
- **History** retains up to four completed full Replicate scan points per item ID.
- Full-market acquisition remains explicitly confirmed and respects the shared 15-minute Replicate cooldown.

## Recipe data source and scope

### Current 0.3.0 source

The initial automatic capture uses the client's `C_TradeSkillUI` profession/recipe APIs. It stores only recipes for which the client reports `learned == true`, and only for professions the character has opened. It uses the client's recipe schematic for output item ID, output quantity and reagent slots.

This is deliberately conservative:
- it does not infer that an unlearned recipe is available to the character;
- it does not treat skill-up difficulty thresholds as trainer learning requirements;
- it does not borrow another game version's trainer requirements;
- it does not invent missing output or reagent quantities.

**Important coverage limitation:** 0.3.0 shows the character's known recipes after the player opens each profession at least once. It does not yet enumerate every unlearned recipe or calculate future skill-level unlock opportunities. That requires a validated offline Forever recipe catalogue and separate learning-requirement evidence.

### ForeverDB research

ForeverDB's read-only API exposes profession recipe pages with reagents, outputs, skill colours, learning sources, trainers/vendors and some observed Forever acquisition information. It requires an approved account API key and visible ForeverDB attribution. The addon cannot make arbitrary Internet/API requests, so any ForeverDB use must be a reviewed build-time data import, not a live addon request. No key was available in this pass; ForeverDB data is therefore researched but not integrated.

### Offline recipe database candidate

MIT-licensed LibProfessionDB 1.9.1 ships a dedicated WoW Forever data tree with 2,511 client-derived recipes from build 1.60.1.69977. Its own documentation explicitly flags borrowed Vanilla learning-source and trainer-requirement values; only a small set of trainer requirements (42 recipes) are directly observed on Forever trainers. Those borrowed values must remain unconfirmed. It is a useful offline structural fallback, but ForeverDB is the stronger next source for Forever-specific learning-source provenance. Market 0.3.0 does not hard-depend on LibProfessionDB and does not bundle its files.

## Preserved 0.2.0 market capabilities

- Incremental catalogue construction and filtering (250 source rows per frame).
- One row per item ID, with lowest unit price, price depth where known, total quantity and variant count.
- 18-row virtualized list.
- Browse snapshots and confirmed full Replicate scans.
- Last-known-good snapshot preservation on incomplete Replicate scans.
- Four-point item-ID price/supply history.
- Low-supply filtering and native Blizzard frame/button/input templates.
- No Auction House purchase, bid, post, cancel or craft execution actions.

The 0.2.0 manual per-item cost basis remains in SavedVariables for backward compatibility, but it is no longer presented or used by the crafting-profitability UI.

## Runtime evidence

**FOREVER OBSERVED before 0.3.0:**
- Browse snapshot: 16,574 variants across 34 pages in 21.1 seconds.
- Browse snapshot persistence across `/reload`.
- One explicitly confirmed Replicate initial response: 291,276 auction records in 17.0 seconds; three samples reported `hasAllInfo=true`.
- 0.1.0 Market opening produced repeated whole-game stalls on the 16,574-row Browse snapshot; 0.2.0 source addressed the synchronous list path.

**SOURCE IMPLEMENTED in 0.3.0:**
- automatic profession-window event capture;
- character-scoped known-recipe storage;
- bounded 20-recipe-per-frame capture;
- reagent/output cost and sale-profit calculation;
- My crafts and Profitable crafts views;
- material-to-recipe and crafted-item relationships;
- removal of manual cost-per-unit and target-sale-price inputs.

**OFFLINE VERIFIED:**
- recipe capture harness: learned-only filtering, profession identity/skill, persisted known recipes;
- economics harness: required reagent quantities, optional slot exclusion, cheapest fully-priced alternative, AH cut, positive/negative profit and unknown-price handling;
- responsive UI harness: 16,574 source rows, 4,002 item IDs, 84 simulated frames, recipe detail, material relationships, profitable filter and history;
- Python regression suite and Lua syntax checks (see standalone runtime audit).

**NOT RUN / UNKNOWN:**
- actual Forever 0.3.0 profession event dispatch and capture;
- Forever `C_TradeSkillUI` schematic shape and output quantity behavior on the player's build;
- character-scoped SavedVariables persistence through `/reload` and full restart;
- UI visual acceptance and frame responsiveness in the actual game;
- complete unlearned Forever recipe catalogue;
- trainer learning requirements and skill progression opportunities;
- recursive make-versus-buy optimization for intermediate materials.

## Install and first use

1. Keep MODULO 1.0.48 installed and unchanged.
2. Replace the existing `AddOns/ModuloMarket` folder with the one from `ModuloMarket-0.5.2.zip`.
3. `/reload`.
4. Open each profession window once on the character. Market automatically captures known recipes.
5. Open Market with `/mm` or the minimap coin button.
6. Use **All Crafts** for the full supported recipe catalogue; install LibProfessionDB 1.9.1 separately for unlearned recipe candidates.
7. Use **Economics** to compare auction and vendor sale routes, and **Materials** to inspect reagents and what consumes them.

For the first in-client acceptance, do not start a new Replicate scan. Use the existing saved market snapshot to test responsiveness, profession capture, recipe cost math and UI. A full scan can be tested only after those pass.

## Separate addon boundary

Market remains a separate optional child addon:
- folder `ModuloMarket`;
- TOC version `0.5.2`;
- `Category: Modulo By Wells`;
- `Group: Modulo`;
- `Dependencies: Modulo`;
- SavedVariables `ModuloMarketDB`.

MODULO does not depend on Market. Market does not depend on Auctionator or ProfessionMaster. Market reads neither addon’s private SavedVariables nor private runtime services.

## License / third-party data

Market source in this package is project-authored. No ForeverDB API data or LibProfessionDB files are redistributed in 0.3.0. ForeverDB attribution is required for any future imported data displayed in Market. LibProfessionDB is MIT-licensed; any future bundling must include its license and exact source/version provenance.


## 0.3.1 search, sorting and presentation improvements

### All items search
- Search is case-insensitive and tokenized: punctuation and apostrophes are normalized, and query words may appear in any order.
- Market item search checks the grouped item name, item ID and saved variant names/IDs.
- Craft search checks output item, recipe name, profession, recipe ID, and known reagent names/IDs.
- Search never reduces the underlying All items catalogue; it filters the full 5,000+ item list.

### Sorting
Click a column heading to sort the complete result set; click it again to reverse direction. Sorting is incremental and does not only reorder the 18 visible virtualized rows.
- All items: Item, Cheapest, At price and Total.
- My crafts: Item, Sale / unit, Materials and Profit / craft.
- Profitable: Item, Sale / unit, Materials and Profit / craft (profit descending by default).
- Low supply: Item, Cheapest, At price / supply and Total.

The `Ranking 20 profitable crafts…` status in 0.3.0 was a count of 20 recipes that actually met the positive-profit filter at that moment, not a 20-row hard cap. Recipe capture itself processes at most 20 IDs per rendered frame and continues until the returned recipe-ID list is exhausted. The screenshots' My crafts count of 49 confirms the combined stored catalogue is not capped at 20.

### Presentation
- Market's dark background now requests a 76% opaque backdrop while leaving labels and controls at full opacity.
- Money values use the native gold, silver and copper coin textures, with gold, silver and copper text colours.
- Negative and positive craft profit retain red/green semantic colouring.

The exact backdrop-template region exposed by Forever is still subject to in-client visual acceptance; if that client template does not expose a mutable backdrop colour, the fallback frame texture path must be diagnosed from a live capture rather than assumed.


## 0.4.0 profession filters, future crafts and window usability

### Profession filter
- A profession dropdown is populated from captured character professions and the supported optional recipe database.
- On All items, selecting a profession keeps items that are known outputs, known reagents, future recipe outputs, or future recipe reagents for that profession.
- On My crafts and Profitable, the profession filter restricts the recipe list to the selected profession.
- The default is All professions.

### Item-role filter and classification
- **Known crafts** marks item IDs produced by recipes captured from the character's open profession windows.
- **Future crafts** uses optional LibProfessionDB 1.9.1 Forever data. It only marks an unlearned output as a future candidate when the database reports an acquisition source or marks it as auto-taught. Never-implemented recipes are excluded.
- Forever source/skill fields borrowed from Vanilla are marked as borrowed/unconfirmed. Recipes with no known source remain in an explicit unknown-source count and are not falsely labelled as obtainable.
- Item rows show `[C]` for a known learned output, `[F]` for a source-backed unlearned output, and `[F?]` when the source is borrowed from Vanilla. Items can have multiple markers.
- Install LibProfessionDB 1.9.1 separately to enable future-craft data. Until it is present and ready, the Future crafts filter is visibly disabled with an install hint. It is an OptionalDeps entry; Market still loads without it. CurseForge: https://www.curseforge.com/wow/addons/libprofessiondb/files/9095167
- The optional database identifies Forever as its own game flavour and includes 2,511 recipes across 10 professions. Source data is incomplete and partly borrowed; see its own provenance notes.

### Gathering classification
- The bundled map contains 87 explicit item IDs for Herbalism (182), Mining (186) and Fishing (356), sourced from ProfessionMaster 7.2.10's Forever gathering-skill table and mining-node secondary-drop table.
- Each item carries a minimum gathering skill threshold. Resource classification is independent of the character's current skill; the detail panel distinguishes "can gather now", "requires more skill", and "current skill not captured".
- Open each gathering profession window once so Market can capture the profession and skill level.
- The map includes Forever-specific gatherables present in the source data, including Azerothium Ore (248815). Skinning is excluded because no complete creature-to-item output map with skill thresholds was present in the supplied source evidence.
- ProfessionMaster and GatherLite are not dependencies; Market carries its own compact item-ID and skill-threshold map.

### Window and list
- Window uses TOOLTIP strata, `SetToplevel(true)` and `Raise()` when opened.
- Adds a direct launcher button to the Blizzard Auction House frame; `/mm` remains available.
- Adds the named frame to `UISpecialFrames` so Escape closes it.
- Tabs have a shared dark tab strip, individual backgrounds and a gold active-tab underline.
- Window expands to 1220×760; the item list pane widens to 735 pixels and the detail pane remains independent.
- Money columns use wider fixed widths and word wrapping is disabled on numeric columns.
- The virtual row pool increases from 18 to 23 rows. The full filtered result array remains scrollable and sortable; 23 is the visible widget pool, not a catalogue cap. The result count continues to show the complete result total.

### Dependencies and boundaries
- Market remains a separately packaged optional child of MODULO. MODULO is unchanged and has no dependency on Market.
- LibProfessionDB is optional; no required addon dependency was added.
- No dependency on Auctionator, ProfessionMaster or GatherLite was added.
- Market does not read other addons' SavedVariables or private databases.


## 0.4.1 runtime defect fixes and usability controls

### Full-catalogue rendering defect
The 0.4.0 virtual row pool updated row text on scroll but left every reusable row button anchored at the top of the scroll child. The ScrollFrame moved the child, so those buttons scrolled out of view and later catalogue offsets appeared blank even while the result counter advanced. 0.4.1 re-anchors each reusable row to its absolute catalogue index on every render. The pool is 25 rows to cover the 510px viewport at 22px per row, including partially visible rows at the top and bottom. It still creates only a small reusable row pool; it does not create one frame per catalogue item.

### Functional dropdown filters
Each dropdown entry now captures its own selected value and disabled state. This avoids Lua 5.1 loop-variable closure behaviour causing menu entries to resolve to the final option. Profession and item-role selection both rebuild the view using the selected value.

### Sorting indicator
The active sort direction is displayed with an up/down texture rather than Unicode triangle characters that rendered as missing-glyph boxes on the observed client font.

### Adjustable background
A 15%-85% background opacity slider controls the Market frame backdrop and inset backgrounds without fading text or controls. The chosen alpha is saved in `ModuloMarketDB.backgroundOpacity`; the initial default is 48%.

### Minimap launcher
A coin-icon minimap button opens Market on left-click. It can be dragged around the minimap and stores its angle in `ModuloMarketDB.minimapAngle`.

### Auction House launcher lifecycle
Launcher attachment now checks both modern and legacy Auction House frame globals and retries on `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD` and `AUCTION_HOUSE_SHOW`. The button is hooked to the parent frame's show lifecycle when available. The player has not yet tested this launcher in the Auction House, so its actual Forever runtime visibility remains NOT RUN.

### 0.4.1 offline verification
The new UI harness checks row anchoring and final-item visibility at maximum scroll, actual dropdown callback selections, sort arrow textures, opacity persistence, minimap opening/drag persistence, and Auction House launcher attachment. Offline checks do not establish Forever frame rendering or event delivery.


## 0.4.2 runtime follow-up

### Background opacity — corrected template target
- `BasicFrameTemplateWithInset` exposes its main tiled background as `frame.Bg` and its large inner panel as `frame.InsetBg`.
- 0.4.1 attempted to adjust `frame.Inset.Bg`, which is not the parent-key used by this template. The inner panel therefore remained fully opaque while the slider value and SavedVariables changed.
- 0.4.2 updates both `frame.Bg` and `frame.InsetBg` directly, with a compatibility fallback for nested inset templates. This is offline source/harness verified; the player's live opacity acceptance is still pending.

### Profession and item-role menus — replace inert stock dropdown path
- 0.4.1's test opened the dropdown initialization callback and invoked its entry callback directly. It did not exercise the actual dropdown button, menu popup, hit target or menu visibility. The player report demonstrates that this did not prove a working control.
- 0.4.2 replaces `UIDropDownMenuTemplate` with a native-looking `UIPanelButtonTemplate` control and a small local popup containing Blizzard-styled option buttons. The actual button click opens/closes the popup; selecting an enabled entry updates the filter and rebuilds the result set. Disabled data-dependent choices remain disabled.
- The new harness exercises the click-to-open path, visible popup, option-button click, selection text, popup close and resulting filtered rows. Live Forever menu rendering remains NOT RUN.

### Craft tab clarity
- My crafts explicitly means every captured known recipe, including loss-making recipes and recipes whose current market prices are incomplete.
- Profitable explicitly means only recipes with complete known market prices and positive estimated profit after the configured Auction House cut. It remains ranked by profit per craft.
- Both tabs now have concise explanatory tooltips so their different purposes are discoverable without adding more permanent UI clutter.

### Auction House launcher placement
- The launcher is smaller and anchored to the top-right header strip, away from the character portrait and main browse controls.
- The player has not yet supplied a live screenshot of the Auction House launcher after this repositioning; runtime appearance and click behavior remain NOT RUN.

### Verification status
- The 0.4.2 UI harness simulates actual button-click menu opening and selection, checks the correct BasicFrameTemplateWithInset `InsetBg` texture alpha, preserves full-catalogue virtual scrolling, verifies minimap interaction and checks the Auction House launcher anchor.
- Offline tests do not prove that the target Forever client renders or dispatches the controls correctly. Install and live acceptance remain required.


## 0.5.0 — market economics and profession catalogue

### Navigation
The former Profitable tab is replaced by two distinct views, and the old Profitable-only recipe list is no longer a separate tab:

1. **All Items** — unchanged full auction catalogue: cheapest buyout, quantity at the cheapest price and total listed units.
2. **Economics** — every market item with its current auction ask, cheapest known recipe material cost and estimated craft profit/loss where the recipe data is complete. Selecting an item shows both auction proceeds after the AH cut and vendor sell value; for a known recipe, the detail panel compares craft-to-AH and craft-to-vendor outcomes.
3. **My Crafts** — only recipes captured as learned from the character's profession windows, including loss-making and incomplete-price recipes.
4. **All Crafts** — learned recipes plus supported unlearned LibProfessionDB candidates. Rows distinguish known, source-backed future, borrowed-source and unknown-source recipes. Unknown and borrowed acquisition evidence is never presented as confirmed Forever availability.
5. **Materials** — items used as reagents by known or supported candidate recipes. It includes synthetic no-market-data rows when a reagent is absent from the current auction snapshot.
6. **Low Supply** — item-level supply view including materials. The default threshold is role-adjusted: materials/gatherables and consumables/trade goods use five times the configured base threshold; equipment uses the base; other items use twice the base. It displays total units and listing count separately where listing counts are known.
7. **History** — shows the current-vs-previous completed-scan price change and a compact four-point price graph. The graph is limited to the four retained full-market history points.

### Filters and item roles
- Profession and role filters now apply across item-oriented views, not just All Items.
- All Crafts uses the same second dropdown as a recipe-source filter: known by you, future/source known, borrowed source, or unknown source.
- My Crafts shows the known-by-you state; its profession dropdown still filters the recipe list.
- The gathering map is registered independently of current character skill. Mining resources therefore remain discoverable when Mining is selected even if the character has not reached the node skill threshold. The selected item detail reports the required/current skill state.
- Item names are colour-coded by role: known craft output, source-backed future candidate, borrowed-source candidate, unknown-source candidate, gatherable resource and crafting material. Role tags remain visible when an item has multiple relationships.

### Relationship text and tooltips
- The item relationship detail uses actual newline characters; it no longer prints literal `\n` text.
- Tab tooltips explicitly use TOOLTIP strata and a frame level above the Market window so they render in front of the panel.
- The existing background opacity slider, click-driven dropdown menus, full-catalogue virtual row pool, minimap button, Auction House launcher and Escape-to-close behavior are retained.

### Recipe and price certainty
- Known recipe economics continue to use the client-captured output and reagent quantities.
- LibProfessionDB 1.9.1 provides the optional Forever structural recipe catalogue. Candidate recipe reagent entries are normalized where the library exposes item IDs and quantities. Output quantity is used only when the data object supplies a recognized explicit quantity field; otherwise profit is withheld rather than assuming one output.
- LibProfessionDB's Forever acquisition sources and learning-skill values borrowed from Vanilla remain explicitly unconfirmed.
- ForeverDB's developer API was researched as a richer source for recipe output counts, reagents, trainer/vendor/quest/drop sources and gathering. It requires an approved account API key and visible ForeverDB attribution. No key was supplied, so no ForeverDB data is imported or redistributed in 0.5.0. The optional static-data import remains a future enhancement; Market makes no live Internet request.
- Vendor sell values are read from the client's cached item information on selection. If item data is not yet cached, Market requests that individual item and refreshes the detail when the client reports it loaded; the full catalogue render does not request item data per row.

### 0.5.0 runtime and performance boundaries
- All large list construction, recipe economics indexing, filtering and sorting are incremental and bounded across frames. The 25-row virtualized display pool is retained.
- No new auction-house requests, Replicate retries, purchases, bids, postings or cancellations are introduced.
- Market remains a separate optional child addon depending on MODULO 1.0.48; MODULO has no dependency on Market.


## 0.5.1 — known/future state correction and vendor-value reliability

### Player problems
- Items already craftable by the character could carry both `[C]` and `[F?]` markers because future candidates were inserted into the item relationship index even when they matched a known recipe.
- Selected items often remained at “Item value not cached” after Market requested item data.
- The item-role dropdown used overlapping, jargon-heavy labels that did not explain the difference between confirmed, borrowed and unknown acquisition sources.

### Changes
- Known recipes are now matched against unlearned library records by exact profession/recipe ID, with a fallback match on profession + output item ID + normalized recipe name. A matching known recipe is excluded from future arrays, candidate counts and All Crafts.
- Item-level craft roles now have a known-output precedence: an item with a learned recipe is classified as a known craft output, not simultaneously as a future/borrowed/unknown output. All Crafts still retains distinct unlearned recipe routes when they are genuinely different.
- When a known output has a genuinely different unlearned route, its detail section is titled **Other unlearned recipes**, not “Future crafts”.
- Vendor value lookup now supports the optional `C_Item.GetItemInfo` table result as well as legacy `GetItemInfo` returns. Item loading listens for both `GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT` (the latter is registered defensively).
- Vendor detail now distinguishes **Loading item data…**, **Unavailable from client data**, and a returned copper value. A completed load notification with no sell-price value is not retried continuously.
- Item-role dropdown labels are concise and explain their meaning through option tooltips: all item types, known craft outputs, unlearned confirmed, unlearned borrowed, unlearned unknown, gathering resources and crafting reagents. All Crafts uses similarly explicit recipe-source wording.

### Evidence and limitations
- The previous 0.5.0 screenshot demonstrated the overlap (`[C]` and `[F?]`) and repeated uncached vendor message.
- Offline regression coverage now includes a different-key duplicate recipe, item-level known-state precedence, asynchronous item-data request/refresh, and the updated filter labels.
- **Forever runtime acceptance remains NOT RUN.** The target client must confirm that its item-data event and item-info API populate vendor values for representative items, and that known/future markers are correct against the live LibProfessionDB data.

## Repository and licensing

This repository is the standalone public source home for ModuloMarket. It is maintained separately from the MODULO parent addon; ModuloMarket depends on MODULO, while MODULO does not depend on ModuloMarket.

The 0.5.2 source is provided for review and development. No open-source licence has been selected or granted yet; unless a licence is added by the author, the default copyright restrictions apply.

## Developer tooling: ForeverDB offline importer

The repository includes a standard-library Python importer under `tools/foreverdb_importer/`. It is not an addon dependency and is not loaded by WoW. It captures approved ForeverDB API responses to local raw JSON, records their SHA-256 hashes/build metadata, profiles the actual response shape, validates a provider-reviewed canonical recipe format, and compiles reviewed records to per-profession Lua build artifacts.

The 0.5.2 importer deliberately deferred the raw API mapper until an approved response was available. In 0.5.3, the reviewed 1.60.1.70862 capture is normalized by the provider-specific adapter and compiled into the build-gated addon dataset. API keys remain environment-only; do not commit them. Future raw imports and intermediate build outputs remain local.

See [`tools/foreverdb_importer/README.md`](tools/foreverdb_importer/README.md) for setup, Windows PowerShell instructions, evidence rules and commands.


## 0.5.2 patch correction

- Fixed normalization of sparse scalar itemID-to-quantity reagent maps so positive item IDs below or equal to 100 are not discarded as array indexes. Contiguous 1-based scalar arrays are detected as positional arrays, while table-shaped records continue to prefer explicit `itemID` fields.
- No new runtime dependency was added.
- Developer-only ForeverDB importer 0.2.0 is included under `tools/foreverdb_importer/`; it does not load in WoW. It captures, inspects, normalizes the reviewed response schema, validates canonical data and compiles compact runtime Lua.


## 0.6.3 inspector footer

Profit/loss and saved-price history are grouped in a bottom-anchored inspector footer. The history graph baseline is bottom-anchored so bars rise upward within the inspector border. See `MODULOMARKET-RUNTIME-AUDIT-0.6.3.md`.


## 0.7.5 search extraction

Full-tooltip search now prefers Forever 1.60.1's structured `C_TooltipInfo.GetItemByID` data, combining every available left/right tooltip line. The legacy hidden-GameTooltip path remains as a guarded fallback and now verifies that it actually populated readable lines before accepting the result. `/mmtooltipdebug itemID` prints the exact normalized text used by search; `/mmsearchdebug` reports extraction-path counters.

Tooltip-effect search remains an explicit Enter submission so ordinary typing does not warm every item tooltip or restart catalogue work.


## 0.7.6 runtime corrections

- Applies the active tab's visibility rules during initial UI construction, after all tab-specific controls have been created.
- Waits for `C_Item.IsItemDataCachedByID` or `GetItemInfo` before accepting structured tooltip data. A partial tooltip returned before item data is ready is no longer cached as complete; the bounded asynchronous warmup requests the item and retries after its load event.
