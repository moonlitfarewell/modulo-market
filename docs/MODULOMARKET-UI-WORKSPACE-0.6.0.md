# ModuloMarket UI workspace completion — 0.6.0

## Player problem and observable result
The 0.5.9 screenshot showed a visually richer list but a largely empty inspector on tab entry, a generic My Crafts filter presentation, and a Materials cost column that did not expose ingredient identities in the central table. The 0.6.0 goal is to complete the three-column workspace without removing tab information or changing the recipe/auction compatibility contract.

## Source evidence and current behavior
- `MarketUI.lua` had a selected-item inspector, recipe economics text, item/reagent icon lookup, seven tab-specific data sources and independent search/profession/role filter state.
- `SetTab` cleared the selected item unconditionally; `FinishView` rendered the list but did not select a result. This explains the empty inspector on a freshly opened tab.
- The craft table used a numeric material-cost field in the centre column and did not expose reagent identities there.
- Recipe detail data already exposed reagent lines, line costs, total material cost, output quantity, profit and recipe source status.

## Changes
- Added per-tab selected-entry memory. A tab restores its previous selection when it still matches the current result set; otherwise its first result is selected automatically. Empty results receive a clear no-match message.
- Added contextual craft filters to My Crafts and All Crafts: Craftable only, Profitable only, Review items only and Hide non-profitable. Definitions are explicit and conservative: craftable means known recipe + resolved output + complete reagent cost; profitable means calculated positive profit; review means explicit review status; hide non-profitable hides calculated zero/negative profit but does not hide incomplete-profit records.
- Replaced the craft table's numeric-only material column with up to two real reagent icon/quantity summaries plus total material cost. Hovering that column shows every reagent, its quantity, its line cost (or unknown-price state), and total material cost. Full reagent lists remain in the right inspector.
- Added explicit At Price quantity, total listed units, total material cost and acquisition classification to craft details; profit percentage is shown only when the net sale denominator is available.
- Craft table columns now use a dedicated layout; switching to non-craft tabs restores the standard item-market column positions.

## Ownership and compatibility
Changes are confined to the optional ModuloMarket child addon. MODULO 1.0.48 is unchanged. No optional addon dependency, ForeverDB recipe data, recipe provenance, market snapshot, or exact-current-build auction gate was changed.

## Risks and gaps
- Filter semantics are based on existing source fields and are not a claim that the character can physically craft a recipe at current skill; `Craftable only` is limited to known recipes with resolved output and complete reagent pricing.
- Ingredient icons in the compact table show up to two reagents; the hover tooltip and inspector retain the full reagent list.
- First-result selection is a UI default, not an inferred READY or acquisition state.
- Layout and checkbox interaction require Forever client runtime validation.

## Runtime acceptance
**FOREVER runtime: NOT RUN.** Verify all seven tabs; default selection and per-tab selection restoration; filter semantics for known/future/borrowed/unknown/review/incomplete-cost recipes; material icons and complete hover breakdown; inspector pricing/reagents/acquisition; column positions after switching craft and non-craft tabs; no Lua errors or data regression.
