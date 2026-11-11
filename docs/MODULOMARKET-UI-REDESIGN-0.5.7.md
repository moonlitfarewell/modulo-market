# ModuloMarket UI refinement — 0.5.7

## Player evidence

The user tested 0.5.6 on Forever client build 1.60.1.70888 and supplied screenshots showing: item/recipe hover help absent; tab help rendered behind the Market; the opacity slider changed only the frame's underlying background rather than the complete window; Materials showed a redundant Listings column; and the visual treatment remained less refined than the selected Dark Foundry reference.

## Findings from 0.5.6 source

- `CreateUI()` placed the Market at `TOOLTIP` strata. `RaiseMarketTooltip()` also placed `GameTooltip` at `TOOLTIP`; a frame-level adjustment within the same strata was insufficient to guarantee correct ordering.
- `ApplyBackgroundOpacity()` changed the template backdrop and inset textures, but custom left/centre/right panel textures retained fixed alpha values.
- Virtualized row buttons had click handling but no item/recipe hover handlers.
- Tab buttons had descriptions; profession-role dropdown options had option descriptions, but controls did not consistently expose their own hover help.
- Materials reused the generic item-table header set and therefore showed a Listings column.

## 0.5.7 implementation

- Market frame now uses `DIALOG` strata; GameTooltip and dropdown menus remain at `TOOLTIP`. Tooltip level is raised relative to its owner.
- Recipe/item row names have a hover target that requests a recipe spell tooltip for recipe rows and an item tooltip for item rows, with guarded API fallbacks. Selected item and recipe metadata each have hover targets.
- Search, profession and role controls show explanatory tooltips; dropdown options retain their detailed definitions.
- Opacity now applies through `frame:SetAlpha()`, affecting the whole Market window while leaving independent tooltips legible. Range is 35–100%.
- Materials uses five columns; Best Craft Profit occupies the former Listings position. Other tabs retain Listings where meaningful.
- Thin muted-bronze panel outlines refine the workspace.

## Compatibility and limits

Item and recipe tooltip methods are guarded because Forever's client API surface may differ. If the client lacks `SetItemByID` or `SetSpellByID`, hyperlink fallbacks are attempted; otherwise the addon must still remain error-free. Offline checks cannot prove that Forever resolves every item or recipe tooltip. Hover layering, opacity appearance, and material-column layout require live client acceptance.
