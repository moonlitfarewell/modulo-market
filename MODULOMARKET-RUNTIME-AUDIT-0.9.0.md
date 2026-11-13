# MODULOMARKET RUNTIME AUDIT 0.9.0

## Result
Combined Dark Foundry visual refinement slice. Source implementation is complete; offline and package validation are pending execution. Forever runtime acceptance remains NOT RUN until tested in the target client.

## Player problem and observable result
The 0.8.9 screenshot confirms dropdown colour correction but shows a clipped status/provenance line, dropdown tooltip overlapping the open menu, oversized Market History graph relative to Relationships, and uneven inspector use of vertical space.

## Evidence and competing explanations
- Screenshot evidence: 0.8.9 on Forever 1.60.1 build 70938. The status line ends clipped; Item Types help tooltip floats over the open menu; Relationships has spare space; graph takes a large share of Market History.
- Source evidence: status summary string is verbose while the full message is already retained in `UI.statusMessage` and exposed by `UI.statusTooltip`; dropdown open/close did not hide GameTooltip; inspector scroll height 106px, history card 224px, graph 126px.
- Alternative hypothesis: clipping is caused by font metrics/scale rather than message length. Shortening the provider summary addresses the visible symptom without removing full details. The actual rendered fit still requires Forever runtime acceptance.
- Alternative hypothesis: tooltip overlay is intended because pointer remains over the dropdown. It is not useful while the popup is open; hiding it on open/close is a bounded interaction correction.

## Changes
- Compact provider status summary, preserving all key counts/categories; full status remains in tooltip.
- Hide dropdown help tooltip on menu open and close.
- Tighten popup option rows.
- Increase Relationships scroll viewport 106px -> 124px.
- Reduce Market History card 224px -> 206px and graph 126px -> 104px; keep history text and four-point chart.

## Ownership and scope
- ModuloMarket UI only. Parent MODULO and specialist addon ownership unchanged.
- No market calculations, recipe/gathering data, scan behavior, SavedVariables, dependencies, APIs or attribution changes.
- Six tabs remain; My Crafts remains absent.

## Validation

- Focused visual regressions: `tests/test_modulomarket_0_9_0_visual_refinement.py` — 6 PASS.
- Full suite: `python -m pytest -q` — 246 PASS / 61 historical failures. Compared directly with the 0.8.9 parent archive: the same 61 failing test IDs remain; no new failing IDs. Six additional tests pass due to new coverage and updated historical geometry assertions.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
- Historical layout tests were updated only where they asserted superseded inspector dimensions; their semantic checks remain.
- Fresh extraction: PASS. ZIP CRC: PASS (`ZipFile.testzip()` returned `None`). Manifest inventory: 176/176 files match the fresh extracted tree. Full suite on fresh extraction: 246 PASS / 61 historical failures with the same 61 failing test IDs as the 0.8.9 parent. Lua syntax on fresh extraction: 9/9 PASS.
