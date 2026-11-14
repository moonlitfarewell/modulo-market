# Modulo Market 0.10.4 — Runtime capability audit

**Status:** SOURCE IMPLEMENTED · FOCUSED TESTS PASS · NO NEW FULL-SUITE FAILURES VS 0.10.3 · FOREVER RUNTIME NOT RUN

## Canonical baseline and provenance

- Sole baseline: user-provided `ModuloMarket-GitHub-Update-0.10.3.zip`.
- Baseline SHA-256: `446db8e4c17d3549b3348196b787134eba347cfc0ca1a52755bb31c885908e33`.
- Baseline ZIP CRC check passed before extraction (`testzip() == None`).
- No other ModuloMarket branch or source bundle was mixed into this slice.

## Player problem and observable result

The user screenshot showed the 0.10.3 Required Bundles panel as a cramped text area that did not make the price composition of each accepted alternative easy to understand. The new panel shows every accepted one-of material alternative independently, with quantities, known cheapest unit prices, line costs, material subtotals and explicit unknowns. The crate purchase remains separate.

## Evidence, counter-evidence and ownership

- Source evidence: `TurnInEngine.BuildRows` produces `bundleAlternatives` in source order, with each ingredient's `quantity`, `unitPriceCopper`, `lineCostCopper`, `status` and `reason`, and marks `bestBundle` only when a full alternative is priceable.
- UI evidence: the 0.10.3 Turn-In inspector concatenated all alternatives into one multiline FontString inside a 124px scroll viewport.
- Counter-evidence/limits: no in-client observation yet confirms actual font rendering, scroll range or visual separation on Forever.
- Owner: ModuloMarket. No specialist addon or parent MODULO ownership is implicated.
- Pricing, market depth, scanner, sorting, filters, data and dependencies are intentionally unchanged.

## Implementation

- Replaced the Turn-In free-form text block with reusable two-column FontStrings in the existing scroll child.
- Displays crate purchase separately, then each accepted option independently and in source order.
- Shows quantity × material on a full-width row, known cheapest unit price and line cost on the following row, and the engine's explicit reason when a line cannot be priced.
- Shows a material subtotal only for complete options; incomplete options remain labelled INCOMPLETE.
- Marks only the cheapest fully priceable alternative BEST VALUE.
- Rows are reused and hidden between selections; ordinary non-Turn-In relationship text is restored by the existing text setter.
- Preserves 0.10.3 inspector font stability and immediate selected-row refresh.

## Risks and scope

- Narrow inspector width may still require in-client wrapping refinement for unusually long material names or failure reasons.
- More than one alternative increases scroll height; actual scrollbar range and wheel interaction require client validation.
- The current data uses one-item alternatives for known Waylaid crate definitions, but renderer handles multiple ingredients.
- No price or reward state is inferred when unavailable. Crate cost is not folded into material subtotals.

## Tests and runtime evidence

- Focused Turn-In/UI regression tests: **25 passed**.
- Lua syntax compilation: **11/11 addon Lua files passed** using `texlua` `loadfile`.
- Existing Turn-In Lua harness: **9 checks passed**, including 30 unique crate definitions, 96 one-of alternatives, completion economics, unknown rewards, insufficient price depth, missing crate price and one-time bonus separation.
- Full Python suite: **294 passed / 87 failed / 381 total**.
- Baseline 0.10.3 full suite: **285 passed / 87 failed / 372 total**. Exact failing test IDs: **87 unchanged; zero new failures; nine additional tests pass** (the new focused tests).
- Final archive CRC, fresh extraction, manifest inventory and version agreement: PASS; exact package hash is in the handoff.

## Runtime evidence and limitations

- User screenshot establishes the 0.10.3 presentation problem; it is not acceptance evidence for 0.10.4.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN. The in-client panel layout, scroll range, wheel interaction, clipping and currency presentation remain to be verified in Forever.
- GitHub remote: NOT UPDATED in this pass; this delivery is a local complete ZIP bundle.

## Exit criteria

1. All alternatives render separately and remain independently understandable.
2. Unit prices, line costs and subtotals are consistent with the existing engine output.
3. Unknown/insufficient-depth lines remain explicitly incomplete and never fabricate costs.
4. Crate purchase is not double-counted in material subtotals.
5. Scroll range exposes all content without clipping.
6. Other tabs retain their original relationship content.
7. 0.10.3 font and highlight fixes remain intact.
8. Forever runtime acceptance is captured before marking the visual capability verified.
