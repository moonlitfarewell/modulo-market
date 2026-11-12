# ModuloMarket 0.6.3 — inspector footer anchoring audit

**Previous child update:** `ModuloMarket-GitHub-Update-0.6.2.zip`  
**Target client:** WoW Forever 1.60.1 build 70888  
**Parent MODULO:** 1.0.48 (unchanged)  
**Scope:** keep selected-item profit/loss and price-history graph fully inside the inspector panel.  
**Runtime status:** FOREVER RUNTIME NOT RUN — awaiting player acceptance.

## Player-reported defect

The player confirmed the 0.6.2 interface is otherwise taking shape, but the profit/loss summary, saved-price history text and bar graph still render partly outside the Selected Recipe/Selected Item panel. The screenshot shows the bars crossing the panel's bottom border.

## Competing hypotheses and diagnosis

1. **Incorrect absolute anchors relative to the main frame — supported root cause.** The 0.6.2 code anchored `detailProfit`, `historyText` and `historyGraph` directly to the main frame at y offsets -694, -728 and -790. The inspector panel ends at frame-relative y=-808. The graph was 35px tall and anchored by its top edge at -790, so it extended to -825, outside the panel.
2. **Bar texture sizing or render-history recalculation — secondary possibility.** Bars use a variable height and are individually bottom-anchored to `historyGraph`; if the graph container itself were correctly placed, the bars should rise from its baseline. The screenshot and source show the container placement, rather than bar growth direction, is the primary failure.

The source geometry directly confirms hypothesis 1. The per-bar `BOTTOMLEFT` anchoring is already correct and is retained.

## Implementation

- Added `UI.detailFooter`, a dedicated 280x122 frame positioned from the main frame's bottom edge with its bottom 52px above the frame bottom. This places it inside the inspector panel, whose lower edge is 42px above the main frame bottom, leaving a 10px interior margin.
- Moved the profit/loss heading and history text into that footer as children.
- Anchored `UI.historyGraph` to the footer's `BOTTOMLEFT`, with a 220x48 area.
- Kept each history bar anchored to the graph's `BOTTOMLEFT`; its height extends upward from the shared baseline.
- No price-history data, ordering, colour logic, profit calculations, SavedVariables, APIs, dependencies or tab behavior changed.

## Tests and verification

- New regression tests assert footer containment geometry, child ownership, bottom anchoring and upward-growing bars.
- Full Python regression suite: **175 passed**.
- Lua syntax: all **9 addon Lua files passed** `loadfile` parsing with `texlua`.
- ZIP CRC: **PASS**; 109/109 archive entries match the manifest; fresh extraction and complete test rerun: **175 passed**.
- In-game rendering is not proven by offline tests.

## Acceptance

1. Open a selected recipe with a negative profit and confirm the loss summary remains inside the inspector.
2. Confirm the saved-history timestamps and prices remain inside the inspector.
3. Confirm every graph bar starts from a common baseline near the panel bottom and rises upward, never crossing the bottom border.
4. Repeat on a market item and a profitable recipe; confirm footer content remains contained.
5. Resize/UI-scale as usual and verify no clipping or overlap with inspector detail text.

**FOREVER RUNTIME: NOT RUN.**
