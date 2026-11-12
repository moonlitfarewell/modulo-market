# ModuloMarket 0.6.4 — table density, inspector wrapping and scroll/opacity layout audit

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.3.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48 (unchanged)  
**Scope:** compact craft material cells with detailed hover breakdown; inspector text wrapping; centre scrollbar containment; opacity label placement.  
**Runtime status:** FOREVER RUNTIME NOT RUN — awaiting player acceptance.

## Player problem and observable result

The user supplied screenshots from 0.6.3 showing:
1. Craft rows with many reagents truncate the inline materials list, obscuring the actual total cost.
2. The inspector has some long content that does not wrap cleanly.
3. The centre list scrollbar extends beyond the middle panel boundary.
4. The "Window opacity" label is aligned beside/over the slider rather than above it.

## Implementation

### Craft material column
- Crafting/all-crafts rows now show only the total material cost in the Materials (cost) cell.
- The existing hover tooltip remains the detailed view and now includes reagent item icons, names, quantities, individual line costs and total cost.
- Sorting by material cost and the selected-recipe reagent list remain unchanged.

### Inspector wrapping
- Long selected-item/recipe name, variant, detail and profit text are configured to word-wrap.
- Non-space wrapping is enabled where the client FontString supports `SetNonSpaceWrap`, preventing long unbroken tokens from escaping the inspector.
- Existing detail/footer anchoring and history graph baseline are preserved.

### Centre scrollbar
- The centre scroll frame receives a stable global name so its Blizzard template scrollbar can be addressed.
- Scrollbar is explicitly anchored inside the scroll frame's right edge.
- Scroll child and virtual row width are reduced to 796 px while the 812 px viewport remains fixed, reserving space for the internal scrollbar.
- Existing row content positions remain within the reduced row width.

### Window opacity
- Label is centred above the slider.
- Percentage readout is aligned with the label row.
- Slider remains below with the same range, step and saved opacity behavior.

## Ownership and compatibility

Only the optional ModuloMarket child repository is changed. Parent MODULO 1.0.48 is not modified. No SavedVariables schema, API surface, recipe data, data source, auction snapshot gate, dependencies or market acquisition behavior are changed.

## Tests and verification

Offline source-contract tests cover:
- Material cell displays only the total cost.
- Hover tooltip retains reagent icons, quantities and per-line costs.
- Inspector wrapping is enabled.
- Scrollbar is named and anchored inside the viewport; row pool width is reduced accordingly.
- Opacity label and value are above the slider.
- Core, TOC and manifest versions agree.

Lua syntax and package integrity are checked during packaging. Offline checks do not prove WoW runtime layout or client template behavior.

## Player acceptance / exit criteria

1. Select a recipe with many reagents: Materials (cost) cell shows the complete total cost without truncation.
2. Hover that cell: all reagent icons, names, quantities, individual prices and total appear.
3. Select a recipe/item with long detail text: all text wraps inside the inspector border.
4. Scroll the middle list to top and bottom: scrollbar track and buttons stay inside the centre panel.
5. Window opacity label and percentage appear above the slider without overlap.
6. Switch all seven tabs and verify sorting, scrolling, tooltips and selection remain functional.

**FOREVER RUNTIME: NOT RUN.** Release readiness and offline tests do not constitute Forever runtime verification.

### Executed verification in this build session

- Focused UI regression set: **16 passed** (`0.6.4` layout, prior inspector footer, tooltip strata and hover/material behavior).
- Lua syntax: **9/9 files parsed** with `texlua` + `loadfile`.
- Full historical pytest suite: **149 passed, 32 failed**. The failures are legacy source-contract assertions tied to earlier versions/layouts (including tests that require the TOC/Core to remain at 0.6.3, require reagent icons inline in the cell, or require the previous 812 px row width). They need test-suite maintenance; they are not represented as passing. The targeted tests for the new behavior pass.
- WoW Forever runtime: **NOT RUN**.
