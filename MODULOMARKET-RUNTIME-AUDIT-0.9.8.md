# MODULOMARKET RUNTIME AUDIT 0.9.8

## Result
All Items browser redesign implemented and packaged as 0.9.8. Sorting and scroll implementation retained. The 0.9.7 bundle remains available as the immediate parent release; the previously requested 0.9.6 fallback archive remains unchanged. Offline validation passes. Forever runtime acceptance for 0.9.8 is **NOT RUN**.

## Player problem and observable result
The All Items table presented six columns, including Listings and Best Craft Profit, despite the intended use being a simple auction-house browser. Craft relationship status was encoded by changing item-name text colour, which conflicted with the game's item-quality colours. The centre table region also had a redundant panel rectangle and vertical column guides. A Low Supply Only checkbox duplicated the dedicated Low Supply tab.

Expected result: four All Items columns (Item, Cheapest, At Price, Total Units), quality-coloured item names, a separate craft-status marker, no redundant centre panel box or vertical guides, and no duplicate low-supply shortcut.

## Source of truth and evidence inspected
- Highest-version complete child source available before this slice: `ModuloMarket-GitHub-Update-0.9.7.zip`.
- 0.9.7 archive: 2,361,243 bytes, 197 entries, ZIP CRC PASS, SHA-256 `f5a71eff7cdfc654b2226b76901ff501dfadff9d61d2411ef28494976e037952`.
- 0.9.7 addon TOC, Core runtime version, README and manifest agreed at 0.9.7.
- The user's screenshots show the 0.9.7 All Items tab and the current row colouring/table layout. These are user-supplied visual evidence, not runtime evidence for 0.9.8.
- Inspected full `MarketUI.lua`, `ProfessionData.lua`, current README/manifest/TOC/Core, 0.9.7 audit and native-window design record, historical row-status design record, and relevant UI/version regression tests.
- The repository does not contain child-specific `PROJECT-START-HERE`, `WORKFLOW`, `PROJECT-DECISIONS`, `PROJECT-PROGRESS`, `QA`, `SOURCE-REVIEW-LEDGER`, a separate architecture file, or a Forever compatibility contract. Their absence is recorded; no missing history was reconstructed.

## Existing implementation confirmed before changes
- Incremental sorting already existed through `ComesBefore`, `StepRankSort`, per-tab `sortByTab`, header click callbacks and sort indicators.
- The virtualized scroll list already existed through `UI.scroll`, `UI.scrollChild`, `UI.listOffset`, `UI.visibleCount`, `UI.RenderRows` and `UI.FinishView`. The user's 10-row scroll movement was not rewritten.
- `At Price` was already sourced from `minPriceQuantity`; `Total Units` from `totalQuantity`; listing count from `auctionCount`.
- Craft relationship classification already existed in `ProfessionData.GetItem`, `GetRecipeLearningStatus` and known/future/unknown recipe lists.
- The old `GetItemDisplayName` coloured item names by craft role; this was the source of the conflict with item-quality colours.
- The old centre rectangle was `centerPanel` and its border was `AddPanelInnerEdge(286, -158, 834, 650)`. The table also had `tableHeaderSurface`, `tableHeaderBorder` and vertical `tableColumnGuides`.

## Implementation
### All Items columns
- All Items now exposes only Item, Cheapest, At Price and Total Units.
- The row fields map to `minPriceCopper`, `minPriceQuantity` and `totalQuantity`; the `auctionCount`/Listings field is no longer displayed in this tab.
- Sorting maps Cheapest to `price`, At Price to `depth`, and Total Units to `total`. Existing sort algorithm and click handling are unchanged.
- Dedicated All Items column geometry is isolated in its own `tab == "market"` layout branch. Other tab layouts retain their own header labels and anchors.

### Item colour and craft status
- Item names use the actual item quality supplied by `GetItemInfo` and `GetItemQualityColor`.
- If quality is not yet available, the fallback is white; no quality is guessed or fabricated.
- A 3px row marker displays known craft green, learnable/unlearned craft yellow, unknown/unlearnable craft red, or no recorded craft relationship white.
- Known craft takes precedence over learnable; learnable takes precedence over unknown/unlearnable. This preserves a single clear marker when an item has multiple recipe relationships.
- Existing item-data events already refresh visible rows after the item cache is populated; the marker and quality colour do not alter recipe state.

### Filters and layout
- Removed Low supply only from the All Items quick-filter controls. Legacy SavedVariables values are ignored and forced false, avoiding a stale hidden filter after upgrade.
- Kept the Low Supply tab unchanged.
- Removed the centre-panel background rectangle and its perimeter border.
- Removed the table's boxed inset surface/border and vertical column guide textures. Retained the restrained horizontal header band/rules, row zebra shading, selected-row treatment and scroll frame.

## Ownership, dependencies and risks
- All changes are ModuloMarket-owned presentation and display logic.
- No dependency changes; ModuloMarket still depends on MODULO and does not introduce dependencies on optional addons.
- No MODULO parent source, specialist addon, auction scan, auction data, ForeverDB catalogue, recipe engine, profitability calculation, SavedVariables schema, or acquisition behavior changed.
- Item-quality colours depend on client item info being available. Before cache completion, white is the explicit safe fallback.
- Craft marker reflects existing ProfessionData relationship evidence; it is not a profitability or source-confidence indicator.
- The reported Best Craft Profit calculation defect remains open outside All Items. This slice removes that misleading column only from All Items and does not claim the underlying calculation is fixed.

## Validation
- Focused 0.9.8 All Items regression tests: **10 PASS**.
- Full suite: **289 PASS / 61 failures**.
- Compared with the 0.9.7 parent suite: the same 61 historical failing test IDs; **zero new failing IDs**.
- Lua syntax: all 9 addon Lua files pass `texluac -p`.
- Full suite includes the existing sorting/scroll assertions, other-tab layout checks, quality-colour/status-marker checks, removal of redundant panel/column surfaces, and release metadata checks.
- ZIP integrity, manifest inventory, fresh extraction and fresh-extraction tests are recorded after final packaging below.
- Forever runtime: **NOT RUN** for 0.9.8.

## Acceptance / exit criteria
The source slice is complete. Player-visible acceptance remains open until the user tests 0.9.8 on WoW Forever 1.60.1 build 70938. Verify four columns and values, sorting, scroll, item quality colours after cache loading, craft markers, tab switching, filter removal, unchanged Low Supply tab, and absence of Lua errors.

## Final package verification
- Release archive: `ModuloMarket-GitHub-Update-0.9.8.zip`.
- ZIP CRC: PASS (`ZipFile.testzip()` returned `None`).
- Archive entries: 200.
- Fresh extraction: 200 files; manifest declares 200; exact sorted inventory match: PASS.
- Focused fresh-extraction tests: 10 PASS.
- Full fresh-extraction suite: 289 PASS / 61 historical failures; compared with the 0.9.7 parent suite, the exact same 61 failing test IDs remain and zero new failing IDs were introduced.
- Fresh-extraction Lua syntax: 9/9 PASS.
- The 61 existing failures are historical/superseded tests outside this slice; they are retained in the comparison rather than silently reclassified as passing.
