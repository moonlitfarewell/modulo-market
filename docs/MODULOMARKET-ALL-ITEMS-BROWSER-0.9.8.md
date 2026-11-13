# ModuloMarket All Items Browser — 0.9.8

## Player intent
All Items should behave like a lightweight Auction House browser, not a mixed market-economics report. It should show only the information needed to compare current auction availability.

## All Items columns
1. **Item** — item icon and client item-quality coloured name.
2. **Cheapest** — lowest current unit buyout.
3. **At Price** — quantity available at the cheapest price.
4. **Total Units** — total units across market variants.

`Listings` and `Best Craft Profit` are not shown in All Items. Auction listing count remains part of the underlying data and can continue to be used by other views/inspector logic. The existing `depth` sort key sorts At Price quantity; the existing `total` sort key sorts total units.

## Row status marker
A 3px marker at the far left of each non-craft item row communicates craft relationship independently of item name quality colour:

- Green — at least one known craft output.
- Yellow — at least one unlearned/learnable craft output, unless a known craft output takes precedence.
- Red — craft output exists but its learning status is unknown or unlearnable, when no known/learnable output takes precedence.
- White — no craft output relationship is recorded (ordinary market item, gathering-only item, reagent-only item, equipment drop, etc.).

The status marker does not imply an acquisition source, recipe profitability, current auction availability, or that a craft is currently profitable. It reflects the existing ProfessionData item-to-recipe relationships and `GetRecipeLearningStatus` evidence.

Item names use the colour returned by the game client for the item's actual quality. If item quality is not yet cached, the name temporarily uses white; the existing item-data event refreshes the visible virtual rows after the client resolves the item.

## All Items filters
The duplicate **Low supply only** shortcut has been removed from All Items because it duplicated the dedicated Low Supply view. Any old SavedVariables value for that shortcut is ignored and forced false. The Low Supply tab itself is retained unchanged for the user's planned later conversion.

The remaining quick filters are Crafting materials only, High profit only and Show review items only.

## Layout
- Removed the redundant centre-panel background rectangle and its perimeter border.
- Removed vertical table column guide textures.
- Removed the boxed inset table-header surface and border.
- Retained the existing subdued header band, horizontal rules, zebra row shading, selected-row treatment and scroll frame.
- All Items has its own four-column header and row anchors. Other tabs retain their own headers, column widths and row fields.

## Preserved behavior and scope
- Existing incremental sorting and selected-column indicator are retained.
- Existing virtual row pool, scroll child, scroll offset handling and item selection are retained.
- Existing Low Supply, Economics, Materials, Crafts and History tab data/calculations are not rewritten.
- No auction acquisition, recipe calculations, item catalogue, ForeverDB data, SavedVariables schema, dependencies, parent MODULO or specialist addon code changed.

## Known open issue
The user has reported that **Best Craft Profit is broken**. This slice removes that misleading column from All Items but does not repair the underlying profitability calculation. The column remains in other relevant tabs pending a separate diagnosis and acceptance.

## Acceptance
On WoW Forever 1.60.1 build 70938 verify:
1. All Items shows exactly Item, Cheapest, At Price, Total Units.
2. At Price matches quantity at the cheapest buyout; Total Units matches total variant quantity.
3. Sorting by Cheapest, At Price and Total Units works both directions.
4. Existing scroll movement and selected-row interaction work.
5. Item names use client quality colours after item data loads.
6. Row markers show green/yellow/red/white according to the documented craft relationship precedence.
7. Low supply shortcut is absent from All Items; Low Supply tab still opens and behaves as before.
8. No centre table rectangle or vertical table guides remain; the other tabs retain their distinct column layouts.
9. No Lua errors occur while switching between All Items, Economics, Crafts, Materials, Low Supply and History.

**Status:** SOURCE IMPLEMENTED; OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.
