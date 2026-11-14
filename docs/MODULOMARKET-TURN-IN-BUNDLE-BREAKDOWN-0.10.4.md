# Modulo Market 0.10.4 — Turn-In material option breakdown

## Player problem

The 0.10.3 Required Bundles panel displayed the crate purchase and bundle alternatives as one long text block. In the narrow inspector scroll area this was difficult to scan and did not clearly explain the price composition of each accepted alternative.

## Observable result

- The crate purchase appears once, separately from material subtotals.
- Every accepted bundle alternative is shown independently and in source order; alternatives are mutually exclusive, not additive.
- Each option is headed by its option number. The cheapest fully priceable option is marked **BEST VALUE**.
- Each material line shows required quantity and known cheapest unit price, followed by its line cost.
- Each option shows a material subtotal only when all its required lines are priceable. Otherwise it shows **INCOMPLETE**.
- Unknown or insufficient cheapest-price depth remains explicit through the engine's existing reason text. Missing prices are not estimated and deeper auction levels are not inferred.
- The existing scroll area contains the complete breakdown; it can be scrolled to inspect every option.

## Implementation and ownership

Owner: ModuloMarket. `MarketUI.lua` replaces the Turn-In free-form multiline block with reusable two-column FontStrings inside the existing scroll child. Rows are reused and hidden when not needed. The ordinary relationship text renderer remains active for non-Turn-In tabs. No parent MODULO source, dependencies, SavedVariables schema, market snapshot, pricing arithmetic, market-depth gate, scanner, filters, sorting, crate dataset or Turn-In alternatives are changed.

## Evidence and counter-evidence

- The user screenshot of 0.10.3 showed the Required Bundles area containing only a crate purchase line and ellipsis in a small scroll viewport.
- Source inspection confirmed that all alternative details were concatenated into one `FontString`, with a 124px-high scroll viewport. The 30-crate data model exposes alternatives as separate `bundleAlternatives`, each with individual line prices and completeness reasons.
- The new renderer iterates every alternative independently and displays line-level pricing. Static/offline tests establish that the intended rendering path is present, but cannot establish actual WoW FontString layout, clipping, scrollbar interaction or Forever client behavior.
- No evidence supports changing the existing price engine or treating alternatives as cumulative; those behaviors remain unchanged.

## Tests and runtime evidence

See `MODULOMARKET-RUNTIME-AUDIT-0.10.4.md` for exact test results. Retail runtime: NOT RUN. Forever runtime: NOT RUN.

## Acceptance

1. The crate purchase price is shown separately and is not included in each material subtotal.
2. Every accepted alternative appears as a distinct option in the Required Bundles panel.
3. Every ingredient shows its required quantity, known cheapest unit price and line cost.
4. Each fully priceable option shows its material subtotal; incomplete options are labelled INCOMPLETE.
5. The cheapest fully priceable option alone is marked BEST VALUE; if none is complete, no option is falsely marked best value.
6. Unknown prices and insufficient cheapest-price depth remain explicit; no missing value is guessed.
7. Scrolling reaches every option without clipping or hiding content.
8. Switching to non-Turn-In tabs restores the ordinary relationship text renderer.
9. The 0.10.3 inspector font stability and immediate row highlight behavior remain intact.
10. Player-visible acceptance is confirmed on the relevant Forever client before closing the runtime scope.
