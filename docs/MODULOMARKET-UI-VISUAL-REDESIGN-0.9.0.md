# ModuloMarket UI Visual Refinement 0.9.0 — combined Dark Foundry pass

## Player problem and observable result
The player's 0.8.9 Forever screenshot confirms dropdown colours are corrected, but exposes several related presentation issues: the ForeverDB status line is too long for its rail; the dropdown's help tooltip remains visible over its open menu; the left popup list is visually tall; Relationships has unused vertical space; and Market History's graph dominates its card. The 0.9.0 slice addresses these together.

## Evidence
- User screenshot: ModuloMarket 0.8.9 on WoW Forever 1.60.1 build 70938. It demonstrates dark/gold dropdowns, the open Item Types menu, overlapping Item Types tooltip, long clipped ForeverDB status text, current inspector proportions and four-point market-history graph.
- Source: `SetStatus` stores the full message in `UI.statusMessage`, displays a truncated line and exposes the full message in a status tooltip.
- Source: `CreateDropdown.openMenu` and `closeMenu` did not hide the dropdown's help tooltip; popup option rows were 22px spaced.
- Source: Relationships scroll viewport was 106px; Market History card was 224px with a 126px graph.
- Counter-evidence: screenshot confirms the dropdown palette fix is successful; no further palette change is needed. It does not establish any market-data or calculation defect.

## Implementation
1. Shorten the provider status string while preserving its essential classifications and counts: observed, Classic-borrowed, unverified, speculative, non-item outputs excluded, review flags. Full provider detail remains in the existing tooltip through `UI.statusMessage`.
2. Hide stale GameTooltip content when a dropdown opens and closes. Keep option-specific tooltips, selected values, disabled choices and callbacks.
3. Tighten popup option row spacing from 22/20px to 21/19px.
4. Increase Relationships viewport and scroll child from 106px to 124px.
5. Reduce Market History card from 224px to 206px and graph from 126px to 104px; preserve the history text and four displayed points.

## Ownership, dependencies and risks
- ModuloMarket owns its UI. No parent MODULO or specialist addon code changed.
- No API/dependency additions, new SavedVariables, market formulas, scan behavior, recipe/gathering data, acquisition evidence or attribution changes.
- Main risk: inspector graph rendering and tooltip lifecycle differ on Forever. Offline source tests and Lua syntax do not prove client behavior.

## Validation and acceptance
- Focused 0.9.0 visual regressions: 6 PASS.
- Full suite: 246 PASS / 61 historical failures; direct 0.8.9 parent comparison confirms identical 61 failing test IDs and no new failures.
- Lua syntax: 9/9 PASS. Manifest inventory, ZIP CRC and fresh extraction are verified in the runtime audit.
- Forever 1.60.1 build 70938 runtime: NOT RUN for 0.9.0. The screenshot is FOREVER OBSERVED for 0.8.9 only.
- Player acceptance: install 0.9.0; verify concise status line and full hover details, no stale tooltip over open dropdown, popup selection, Relationships scrolling and four-point history graph fit without clipping.
