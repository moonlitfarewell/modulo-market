# Modulo Market 0.10.2 — Turn-In reward and inspector sizing correction

## Player problem

The 0.10.1 merged reward column still printed both dimensions (for example `20 F · 0 Rep`) even though the column is intended to show one reward type. The selected Turn-In inspector's metric labels and values also remained visually cramped: the labels were enlarged beyond their narrow width, while the values inherited large-font creation and depended on later font-object resets.

## Observable result

- Each crate's compact reward cell shows exactly one value: reported Favor takes precedence; otherwise reported reputation is shown; if neither is reported, the cell shows `?`.
- The inspector's corresponding reward value follows the same exclusive rule, using the full words Favor or Reputation.
- A known zero reputation remains `0 Rep` / `0 Reputation`; an unknown reward remains `?`.
- Turn-In metric labels use the small native label font and shorter wording. Values are created at `GameFontHighlight` body size and receive 160px, with the value column starting at x=1248.
- Non-Turn-In tabs continue to explicitly restore their original large value font.

## Scope and ownership

Owner: ModuloMarket. This is a presentation correction plus accurate `rewardStatus` classification when reputation is the only reported dimension. No parent MODULO source, dependencies, SavedVariables schema, auction snapshot, price arithmetic, market-depth gate, crate definitions or material alternatives change.

## Evidence and competing sizing hypotheses

1. **Font-state hypothesis:** the large font assigned at construction or a later font-object transition remains active on the selected Turn-In view.
2. **Geometry hypothesis:** the enlarged labels and 132px value column are too constrained for the actual label/value strings, independently of font-state transitions.

Source inspection supports both contributing factors: labels were enlarged at creation, values were created as `GameFontHighlightLarge` and enlarged, and the old split was 128px/132px. The correction removes enlargement at creation, makes the body font the default, shortens labels and widens values to 160px. Distinguishing the remaining in-client rendering behavior requires reading the actual font/region dimensions and visual confirmation on the target client; source tests cannot establish WoW's rendered pixel geometry.

## Tests and runtime evidence

- Focused Python tests: recorded by the release audit.
- Lua syntax and Turn-In harness: recorded by the release audit.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN. The uploaded screenshot is evidence of the 0.10.1 defect, not acceptance evidence for 0.10.2.

## Acceptance

1. All 30 crates remain visible.
2. A Favor-reward crate shows only `N F`, not a second reputation value.
3. A reputation-only crate shows only `N Rep`; known zero remains `0 Rep`; no reported reward shows `?`.
4. The selected inspector displays only one reward type.
5. The four metric labels fit their label column; currency/reward values are fully visible in the wider value column.
6. Switching between Turn-Ins and every other tab preserves the existing non-Turn-In font sizing.
7. Pricing arithmetic, unknown-price fail-closed behavior and material alternatives remain unchanged.

Release readiness does not mean Forever runtime verified.
