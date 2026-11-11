# ModuloMarket 0.5.0 — Runtime Capability Audit

**Record date:** 10 November 2026  
**Addon version:** 0.5.0  
**Parent MODULO:** 1.0.48 (unchanged)  
**Status:** SOURCE IMPLEMENTED; OFFLINE REGRESSION PASS; FOREVER RUNTIME NOT RUN

## 1. Player problem and observable result

The 0.4.2 Market interface had a complete visible All Items catalogue and a working background-opacity slider, but the item relationship panel printed literal `\n` sequences, Mining + Gatherable Resources could return no rows, the role dropdown was disabled outside All Items, and My Crafts / Profitable did not represent distinct player jobs.

The 0.5.0 target is a market workspace that separates:
- item-level auction discovery;
- item economics (auction vs vendor value and best known craft route);
- recipes already learned by this character;
- the wider supported profession recipe catalogue;
- crafting materials and their recipe relationships;
- role-adjusted low supply;
- recent price and supply movement.

The player should be able to inspect item and recipe economics without entering manual cost or target-sale values.

## 2. Evidence actually available

### Supplied project artifacts
- `ModuloMarket-0.4.2.zip` — 188,680 bytes; SHA-256 `525a877ee46803feaeed96492517d9bd82364c8735f50eeaefa4ce2db0129168`; ZIP CRC test passed.
- `MODULO-Project-Source-1.0.48.zip` — 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; ZIP CRC test passed.
- `MODULOMARKET-RUNTIME-AUDIT-0.4.2.md` from the 0.4.2 package.
- The user's 0.4.2 screenshots and reports in this conversation.
- The existing Market README, MANIFEST, Lua source and regression tests.

The parent MODULO 1.0.48 bundle was checked for ZIP integrity and parent version/provenance agreement. Its project start-here, README, WORKFLOW, progress, decisions, QA, source-review ledger, architecture and Forever compatibility contract were inspected for the separate-child boundary. No parent MODULO source was changed.

### External research
- ForeverDB developer documentation: https://foreverdb.net/developers (checked 10 November 2026). It documents recipe pages with reagent data, output count/min/max, learning sources, trainer/vendor/quest/drop acquisition and gathering. It requires an approved API key and visible attribution.
- LibProfessionDB 1.9.1 Forever recipe data remains an optional structural source. Its borrowed Vanilla acquisition/skill fields are not promoted to Forever-confirmed evidence.

No ForeverDB API key was supplied. No ForeverDB data was downloaded, imported or redistributed in this slice.

## 3. Source findings and counter-evidence

### Reproduced from source
1. `RenderMarketRecipeContext` used `table.concat(lines, "\\n")`, which emitted literal backslash-n text.
2. `ProfessionData.AddGatheringItems` only registered an item when a captured profession skill existed and met the resource threshold. This conflated resource classification with present character eligibility.
3. `SetTab` disabled the item-role dropdown on every tab except `market`.
4. The previous tab model split known recipes from positive-profit recipes, while lacking a full item-economics view, all-candidate recipe view and dedicated materials view.
5. 0.4.2's item list and role metadata did not mark recipe reagents as a first-class item role.
6. 0.4.2's history detail showed up to four values but no current-vs-previous delta column or graph.

### Preserved evidence / counter-evidence
- The user confirmed the opacity slider now works in 0.4.2. It was retained, not rewritten.
- The user confirmed the full All Items catalogue now displays and scrolls. The virtual row pool and absolute row anchoring were retained.
- The user previously observed a 16,574-variant Browse snapshot and a 291,276-auction Replicate response in earlier tests. Those are historical runtime observations, not evidence that 0.5.0 has been tested.
- No current screenshot or game session demonstrates the new 0.5.0 tabs or calculations at runtime.

## 4. Implemented changes

### Seven-tab information architecture
1. **All Items** — retained full auction catalogue.
2. **Economics** — all market items with auction sale/unit, best indexed recipe material cost and estimated AH profit/loss when complete. The detail panel compares auction proceeds after AH cut with vendor sell value and craft-to-vendor profit when the required data is present.
3. **My Crafts** — learned recipes captured from the character's profession windows; losses and incomplete prices remain visible.
4. **All Crafts** — known recipes plus LibProfessionDB unlearned candidates. Known, source-backed future, borrowed-source and unknown-source rows are distinguished. The former Profitable tab is removed; profitability is a sortable result, not a separate positive-only recipe catalogue.
5. **Materials** — items used as reagents by known or supported candidate recipes. Missing-market reagent rows can be shown without inventing a market price.
6. **Low Supply** — includes crafting materials; displays total units separately from auction listing count when known. Thresholds scale from the configured base: materials/gatherables and consumables/trade goods 5×, equipment 1×, other items 2×.
7. **History** — latest-vs-previous saved price delta plus a compact chart using up to four retained full-scan points.

### Classification and filters
- Gathering resource classification is independent of the character's current skill. Each resource retains its required skill and whether the character can gather it now.
- The supplied 87-item gathering map remains limited to Herbalism, Mining and Fishing. Skinning is still unmapped.
- Item roles now include known craft output, source-backed future craft output, borrowed-source candidate, unknown-source candidate, gatherable resource and crafting material. Item names use distinct role colours and markers.
- Profession filtering applies to item-oriented and recipe-oriented tabs.
- The second dropdown adapts to the view: item roles for item views; recipe source status for All Crafts; known-by-you status for My Crafts.
- The item-role dropdown is no longer disabled on non-All-Items views. Item views can filter borrowed-source and unknown-source outputs separately; All Crafts has corresponding recipe-source filters.

### Price and recipe certainty
- Known recipe economics continue to use captured client schematic output/reagent data.
- LibProfessionDB future recipe reagent entries are normalized only when item IDs and quantities can be interpreted. Explicit output quantity is used only when the source record supplies a supported quantity field. If output quantity or required prices are unknown, profit remains unavailable. The Economics best-route index excludes borrowed-source and unknown-source candidates; All Crafts still shows them with explicit warnings.
- Borrowed-source flags accept an explicit boolean or non-empty source label; false values are not treated as borrowed.
- Vendor value is read from client item information. A selected uncached item may be requested individually and its detail refreshed on `GET_ITEM_INFO_RECEIVED`. The virtualized full-catalogue render does not issue per-row item-data requests.
- The detail panel's relationship text uses actual newline characters.
- Tab tooltips are raised to TOOLTIP strata and a frame level above the Market frame.

### Scope and ownership
- Changes are confined to the standalone `ModuloMarket` child addon.
- MODULO 1.0.48 remains unchanged.
- Market continues to depend only on MODULO. MODULO does not depend on Market.
- Auctionator, ProfessionMaster and GatherLite are not dependencies; their SavedVariables/private services are not read.
- No auction purchase, bid, post, cancel or automatic scan retry behavior was added.

## 5. Implementation acceptance and offline tests

The 0.5.0 source acceptance targets are:
- Seven distinct views with the old Profitable-only tab removed.
- All Crafts combines known and supported unlearned candidates while preserving source certainty.
- Materials contains reagent items and can represent missing-market items.
- Mining resources remain discoverable when Mining is selected even if current skill is below the resource threshold.
- Item-role filtering is enabled in item views; All Crafts exposes recipe-source filtering.
- Economics computes only from available market/reagent/output data and displays vendor alternatives when item data is available.
- Low Supply includes crafting materials and shows units/listings separately.
- History provides delta and graph from retained points.
- All catalogue and recipe-index processing remains incremental; row rendering remains virtualized.

Offline verification executed for this package:
- Python regression suite: **104 passed** (includes the Lua UI integration harness invocation).
- Lua syntax compilation (`texluac -p AddOns/ModuloMarket/*.lua`): **passed**.
- Lua UI integration harness (`texlua tests/market_ui_0_5_0_harness.lua AddOns/ModuloMarket/MarketUI.lua`): **passed**.
- Harness covers click-driven dropdown selection, Mining + Gatherable Resources below skill threshold, seven tabs, known/future/borrowed/unknown recipe status, Materials, Economics, vendor detail, Low Supply, History delta/graph and tooltip strata.
- ZIP CRC validation: **passed**.
- Fresh extraction and manifest inventory comparison: **passed** (59 archive entries; 59 manifest-listed files).
- The fresh-extracted package independently reran the Python suite (**104 passed**), Lua syntax compilation and the Lua UI integration harness.
- Release ZIP CRC: **passed** (`ZipFile.testzip()` returned no corrupt entry).
- Final archive SHA-256 and byte count are recorded below.

These tests are source/offline acceptance only. They do not establish Forever client runtime behavior.

## 6. Risks, gaps and NOT RUN / UNKNOWN

1. **FOREVER RUNTIME NOT RUN:** no 0.5.0 game installation or client session was available. The new tabs, popup filters, vendor item-data event, frame layering, scroll behavior and responsiveness need live acceptance.
2. **Future recipe quantity coverage UNKNOWN:** LibProfessionDB 1.9.1 may not expose an explicit output count for every recipe. Such candidates remain visible, but profit is withheld. ForeverDB is the stronger documented source for min/max output count and Forever learning-source provenance; integration is blocked pending an approved API key and attribution approval.
3. **Future recipe schema UNKNOWN at runtime:** the adapter normalizes documented structural fields conservatively, but exact 1.9.1 data shape has not been exercised in the target Forever client.
4. **Gathering coverage PARTIAL:** the bundled 87-item map covers Herbalism, Mining and Fishing only. It is not a complete world-resource database; Skinning and future Forever additions remain UNKNOWN.
5. **Low-supply thresholds are heuristics:** 5×/1×/2× role multipliers are a starting point, not empirically validated demand thresholds. Tune after player review.
6. **Vendor data depends on client item cache:** a vendor price can remain unknown if the client does not provide item information or the request event differs on the target build.
7. **History is limited to four full-scan points:** the graph is a compact four-point bar trend, not a long-term price series or moving-average forecast.
8. **No profit guarantee:** lowest ask is not a sale guarantee; deposits, sale probability, undercuts, market movement and player-specific sale timing remain excluded.
9. **Current client build and UI API compatibility:** NOT RUN. Retail/source tests do not prove Forever runtime behavior.

## 7. Required player runtime acceptance

Use the existing saved market snapshot; do not begin a new Replicate scan for these tests.

1. Open `/mm`; confirm the seven tabs appear and the tooltip renders above the window.
2. All Items: select Mining + Gatherable Resources; confirm ore/stone resources appear even if current skill is below their node threshold.
3. Select a resource; confirm required/current skill status is accurate.
4. Materials: confirm reagent items appear, including an explicit no-market-data state where applicable; inspect Used In relationships and line breaks.
5. My Crafts: confirm only learned recipes appear, including loss-making and incomplete entries.
6. All Crafts: confirm source-backed, borrowed-source and unknown-source candidates are visibly distinguished; filter each status and profession.
7. Economics: select a craftable item; confirm auction ask, vendor value, material cost, AH profit and vendor-route profit. Select a non-craftable item and confirm no fabricated material/profit value appears.
8. Low Supply: verify units and listing count; verify low-stock materials appear.
9. History: after at least two completed full scans, verify signed price delta and graph direction.
10. Move the background opacity slider; confirm labels remain readable and tooltips stay in front.
11. Test scrolling to the last row in All Items, Economics, Materials, Low Supply and History. Confirm no blank region or UI stall.
12. Close with Escape; reopen with `/mm`, minimap button and Auction House launcher.

Keep any failed player-visible result open as a runtime defect and capture the exact screenshot/error before changing the implementation.


## 8. Release archive verification

- Archive: `ModuloMarket-0.5.0.zip`
- ZIP entries: 59
- ZIP CRC: PASS
- Fresh extraction: PASS
- Fresh-extracted MANIFEST version: 0.5.0
- Fresh-extracted TOC/Core version agreement: 0.5.0
- Fresh-extracted manifest inventory: 59/59 files match
- Fresh-extracted regression suite: 104 passed
- Fresh-extracted Lua syntax compilation: PASS
- Fresh-extracted UI integration harness: PASS
- Archive size and SHA-256 are reported in the release handoff.
