# ModuloMarket All Items Column Fit — 0.9.9

## Player problem
The 0.9.8 four-column All Items browser looked cleaner, but removing the centre panel perimeter also removed its top, left and bottom edges. Numeric columns still occupied overly wide fixed areas, leaving the item column unnecessarily constrained.

## Observable result
- Restore a complete one-pixel perimeter around the centre table panel.
- Do not restore the centre panel's redundant filled background.
- Do not restore vertical column divider textures or a boxed table-header surface.
- Size the numeric columns to the widest displayed header/value in the currently visible row pool.
- Anchor numeric columns from the right edge in this order: Total Units, At Price, Cheapest.
- Let Item fill the remaining space to the left of Cheapest.
- Recalculate the widths whenever visible rows are rendered, including after scrolling, sorting, filtering and tab refresh.
- Keep all other tab-specific column geometry unchanged.

## Layout implementation
The centre panel outline uses the existing `AddPanelInnerEdge`/`AddBevelBorder` helper at `(286, -158)` with size `834 x 650`. This adds only four one-pixel edges; no centre background texture is created.

All Items column widths are measured using the existing client font-string `GetStringWidth()` method:
- Cheapest measures the Cheapest heading and visible `row.price` strings.
- At Price measures its heading and visible `row.depth` strings.
- Total Units measures its heading and visible `row.atPrice` strings.
- Each measured width receives 14px of breathing room and a conservative minimum; defensive upper bounds prevent pathological strings from consuming the whole table.
- Starting from the right edge of the 796px virtual row, Total Units is placed first, then At Price, then Cheapest. Item receives the remaining width.
- Header anchors use the same global x positions as their corresponding row fields.

This is a visible-row content-fit layout rather than a scan of all 5,996 catalogue records. As the user scrolls, the currently visible values are remeasured and the numeric columns can adapt.

## Preserved behavior
- Sorting and its existing sort indicators are unchanged.
- Virtualized 25-row pool and existing scroll offset/increment behavior are unchanged.
- Cheapest still displays the minimum buyout, At Price still displays quantity at the minimum buyout, and Total Units still displays total market quantity.
- Item quality colouring and the craft-status marker from 0.9.8 are unchanged.
- Low Supply tab, all other tabs, calculations, scans, data, SavedVariables and dependencies are unchanged.

## Acceptance
On WoW Forever 1.60.1 build 70938:
1. Centre panel has continuous top, left, bottom and right edges.
2. Centre panel remains transparent/unfilled behind the table.
3. No vertical table column guides return.
4. Total Units, At Price and Cheapest align to the right and fit their widest currently visible content.
5. Item uses the remaining width and does not overlap Cheapest.
6. Scroll to rows with longer prices/quantities; columns resize and remain aligned.
7. Sorting and filtering recalculate visible content widths without breaking header clicks.
8. Switch between All Items, Low Supply, Economics, Crafts, Materials and History; each retains its own column layout.
9. No Lua errors.

**Status:** SOURCE IMPLEMENTED; OFFLINE TESTS PASS; FOREVER RUNTIME NOT RUN.
