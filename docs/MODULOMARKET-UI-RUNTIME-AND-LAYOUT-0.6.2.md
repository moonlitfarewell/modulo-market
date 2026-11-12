# ModuloMarket 0.6.2 — asynchronous row-pool safety and workspace layout

**Scope:** repair the user-reported `MarketUI.lua:1077` nil-button runtime error; make the existing three-column workspace fit its contents; expose captured skill-up colour thresholds in recipe inspection.

## Player problem and observable result

The player reported 36 Lua errors during ProfessionMaster's profession initialization. The stack enters `MarketUI.lua:1077` from `vendorInfoEvents`' item-data callback, triggered by ProfessionMaster's asynchronous `ContinueOnItemLoad` work. The failing locals were `item=nil` and `button=nil`.

The renderer previously checked only `if not UI.rows then return end`. At module initialization `UI.rows` is already an empty table, which is truthy in Lua. The event handler can therefore call `RenderRows()` before `CreateUI()` has constructed `UI.rows[1]` or `UI.scrollChild`. The first loop iteration dereferenced `button:ClearAllPoints()` without checking that the virtual row exists.

## Competing hypotheses and distinguishing evidence

1. **Early lifecycle callback before row-pool creation (supported root cause):** `UI.rows` is initialized as `{}` at module load; `vendorInfoEvents` registers at module scope; the event handler calls `UI.RenderRows()`; `CreateUI()` populates the 25 rows later. The stack originates in an asynchronous ProfessionMaster item-data callback, and the nil `button` at index 1 is consistent with the empty initial pool.
2. **Sparse/partially constructed row pool or visible-count/pool mismatch (secondary robustness risk):** a pool may be incomplete or a visible-count value may exceed constructed buttons. The nil `button` would also be possible later in lifecycle. The new renderer bounds iteration by actual pool size and checks each button before use.

The stack and source ordering support hypothesis 1. The guard and per-row checks also close hypothesis 2. No client instrumentation trace was available beyond the user's stack, so the exact event timing has not yet been observed in a debugger.

## Implementation

- `UI.RenderRows()` now returns unless the row table, first pooled row and scroll child exist.
- The render loop is bounded by `min(visibleCount, #rows)` and protects each row button before dereference.
- The item-data event remains asynchronous and non-blocking; it does not attempt to construct UI during addon initialization. The next normal UI refresh renders after row creation.
- The centre panel grows from 780 to 834 pixels; the right inspector narrows from 354 to 300 pixels. The scroll viewport and virtual rows grow from 758 to 812 pixels.
- Craft table's Materials (cost) column grows to 166 pixels, with aligned row text and tooltip hit area. Existing reagent details remain available in the hover tooltip and inspector.
- The three panel headings and result count are anchored inside their respective header plates.
- Inspector labels, metadata and detail body are constrained to the narrower 268-pixel content width and wrap instead of extending beyond the right panel border.
- Skill-up colour thresholds from the normalized ForeverDB recipe record are displayed in the selected recipe/item inspector. Yellow/green/grey and the client orange field are shown only with `FOREVER_CLIENT` threshold evidence. `orange_classic` is shown separately as Classic-borrowed and explicitly not Forever-confirmed. These are skill-up colours, not trainer learning requirements.

## Ownership and compatibility

Only the optional ModuloMarket child addon, its tests, docs, README and manifest change. Parent MODULO 1.0.48 remains unchanged. ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket. No API, SavedVariables schema, market snapshot gate, recipe dataset or acquisition evidence was changed. ForeverDB 1.60.1.70888 remains the active recipe dataset; the exact-current-client auction snapshot requirement remains independent.

## Risks and limitations

- The user-visible Lua failure is not closed until the player tests the updated addon on Forever and confirms no repeat errors during login, profession initialization, opening Market, tab changes and item-data completion.
- Offline source-contract tests do not reproduce the full WoW event scheduler or ProfessionMaster lifecycle.
- UI geometry is source-validated but requires in-game visual acceptance at the user's resolution/UI scale.
- Skill-up thresholds remain sourced from the captured ForeverDB provider data with per-field evidence; the Classic orange value is not upgraded to Forever evidence.

## Acceptance

1. Log in with ProfessionMaster enabled and allow profession/gathering initialization to complete; no `MarketUI.lua:1077` error.
2. Open Market while item data is resolving; no error.
3. Switch all seven tabs, filter, scroll and select rows; no nil row references.
4. Materials (cost) values/icons no longer clip due to the previous centre-width constraint; hover still shows full reagent detail.
5. All three panel titles and result count sit inside their header plates; inspector text stays within the right panel border.
6. Selecting Coarse Grinding Stone shows Forever-client skill-up colours Green 70 / Grey 90 (and Orange/Yellow 50), with Classic orange 75 separately marked borrowed/not Forever-confirmed.
7. Existing 70888 recipe baseline, three hotfix review flags, and exact-build auction snapshot gate remain unchanged.

**FOREVER RUNTIME: NOT RUN.**
