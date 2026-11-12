# ModuloMarket 0.6.2 — runtime defect and Dark Foundry layout audit

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.1.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48 (unchanged)  
**Scope:** asynchronous item-data callback crash; centre/inspector width rebalance; section header alignment; skill-up threshold visibility.  
**Runtime status:** FOREVER RUNTIME NOT RUN — awaiting player acceptance.

## Player problem and observable result

The user reported a repeated Lua error during ProfessionMaster's asynchronous profession initialization:

```text
ModuloMarket/MarketUI.lua:1077: attempt to index local 'button' (a nil value)
RenderRows -> vendorInfoEvents OnEvent -> ITEM_DATA_LOAD_RESULT / GET_ITEM_INFO_RECEIVED
ProfessionMaster ContinueOnItemLoad -> RequestItemLink -> BuildRecipesForSkill
```

The screenshot also showed:

1. It was unclear how to see Coarse Grinding Stone's green 70 / grey 90 skill-up thresholds.
2. The All Crafts Materials (cost) column was truncated by available centre width.
3. Inspector text extended beyond its panel border.
4. Panel titles and the result count did not sit consistently inside the assigned panel header strips.

## Exact evidence and diagnosis

- Supplied runtime stack reports `startIndex=1`, `i=1`, `index=1`, `item=nil`, `button=nil`, and the error at `button:ClearAllPoints()`.
- In source, `UI.rows` is initialized at module load as an empty table (`rows = {}`).
- The `vendorInfoEvents` frame registers its item-data events at module scope and its event handler calls `UI.RenderRows()` when the selected item does not match the arriving item.
- `CreateUI()` populates `UI.rows` later, after it creates `UI.scrollChild` and its 25 virtual row buttons.
- The old `if not UI.rows then return end` guard did not protect the early lifecycle because an empty Lua table is truthy.

### Competing hypotheses

1. **Early item-data callback before the row pool is created — supported root cause.** The module-scope event listener can receive ProfessionMaster's asynchronous item-load completion while `UI.rows` is still the initial empty table and before `UI.scrollChild` exists. The stack path and nil first row match this sequence.
2. **Sparse/partial row pool or row-count mismatch — secondary possible cause.** A missing row at a later index could also produce a nil button. The previous renderer did not bound the loop by the actual row pool or check each button.

The source ordering and reported nil locals support hypothesis 1. The 0.6.2 guards also handle hypothesis 2. A live event trace was not available, so exact scheduler timing remains inferred from source lifecycle and stack evidence.

## Implementation

### Runtime defect

- `RenderRows()` now returns until `UI.rows[1]` and `UI.scrollChild` exist.
- The loop is bounded by `min(visibleCount, #UI.rows)`.
- Each row button is checked before any frame method is called.
- Item-data events remain non-blocking; the renderer does not construct UI from an asynchronous item callback.
- Normal Market refresh after UI creation populates the rows as before.

### Workspace and layout

- Centre panel width: 780 → 834 px.
- Right inspector width: 354 → 300 px.
- Scroll viewport and virtual rows: 758 → 812 px.
- Craft Materials (cost) column: 105 → 166 px; row text and hover hit target align to the widened column.
- Market and Materials row positions were adjusted to align with their expanded header columns.
- Filters, centre content, and selected-item panel titles are anchored within their panel header strips; result count is moved into the centre header strip.
- Inspector content uses a 268 px content width, wrapping long names/metadata/detail text inside the border.

### Skill-up thresholds

- The selected recipe inspector now exposes captured Forever-client skill-up colour thresholds.
- For Coarse Grinding Stone (Blacksmithing recipe 3326), the 70888 source says Orange 50, Yellow 50, Green 70 and Grey 90.
- Classic orange 75 is shown separately as `CLASSIC_BORROWED`, explicitly not confirmed for Forever.
- The UI labels these as skill-up colours, not trainer learning requirements.

## Ownership and compatibility

Only the optional ModuloMarket child repository is changed. Parent MODULO 1.0.48 source is not modified. ModuloMarket still depends on MODULO; MODULO does not depend on ModuloMarket. No SavedVariables schema, API surface, data source, recipe catalogue, market snapshot gate, auction acquisition behavior or dependency was changed. Active recipe data remains ForeverDB 1.60.1.70888. The exact-current-client auction snapshot gate remains in place.

## Tests and verification

- Python regression suite: **172 passed**.
- Lua syntax: all **9 addon Lua files passed** `loadfile` parsing with `texlua`.
- New source-contract tests cover early callback guard ordering, row-pool bounds, per-button guard, centre/right panel dimensions, wider materials column, header placement, inspector wrapping, skill-up evidence separation and column alignment.
- ZIP CRC, exact manifest inventory, version agreement, fresh extraction and rerun are recorded in the final package verification.
- Parent MODULO 1.0.48 ZIP was independently rechecked: 506 entries, CRC PASS, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.

## Risks and remaining gaps

- Offline tests and Lua parsing do not reproduce the full WoW event scheduler or ProfessionMaster initialization lifecycle.
- In-game visual layout requires acceptance at the player's actual resolution and UI scale.
- FOREVER runtime behavior has not yet been verified for this slice.
- No claim is made that the nil-button defect is closed until the player confirms a clean login/profession initialization and Market use.

## Player acceptance / exit criteria

1. Log in with ProfessionMaster enabled and allow profession/gathering initialization to complete; no `MarketUI.lua:1077` error.
2. Open Market while item data is resolving; no error.
3. Switch all seven tabs, search, filter, scroll and select rows; no Lua errors or missing controls.
4. All Crafts Materials (cost) quantities/icons/cost fit the wider column; hover still reveals all reagent lines and total cost.
5. Filters, centre and inspector headings plus result count sit inside their respective header strips.
6. Selected inspector text remains within the right panel border at the user's UI scale.
7. Selecting Coarse Grinding Stone shows Green 70 / Grey 90, Orange/Yellow 50 as Forever-client skill-up colours and Classic orange 75 separately as borrowed.
8. Existing 70888 data baseline, three hotfix review flags, ForeverDB credit and exact-build auction snapshot gate remain unchanged.

**FOREVER RUNTIME: NOT RUN.** Release readiness and offline tests do not constitute Forever runtime verification.
