# Modulo Market 0.12.2 — search result scroll reset

Date: 2026-11-14

## Player problem and observable result

The player supplied a Forever screenshot with the search field set to `spire`. The result counter displayed `99-2 / 2`, the item rows were blank, and the inspector showed `Spire of the Stoneshaper`.

This is internally inconsistent: a two-item result set cannot have a first visible row of 99. The display is retaining a scroll offset from the previous, much larger result set. The result counter and virtualized row renderer both derive their starting row from `UI.listOffset`, so a stale offset can place the list beyond the end of the newly filtered results and make valid matches appear absent.

Expected result: every new result set starts at the top; any delayed scroll event is clamped to the valid range for the current result set; the range indicator cannot show a start row greater than the result count.

## Evidence inspected

- Exact uploaded `ModuloMarket-GitHub-Update-0.12.1.zip` (263 entries; ZIP CRC test passed).
- Exact uploaded `WTF.zip` SavedVariables snapshot.
- Player screenshot showing `spire`, `99-2 / 2`, blank result rows and selected item `Spire of the Stoneshaper`.
- 0.12.1 `MarketUI.lua`:
  - `StartViewBuild()` resets `UI.listOffset` and requests `SetVerticalScroll(0)` before the new result rows have been committed.
  - `FinishView()` replaces `UI.viewRows` and resizes `scrollChild`, but did not reset/clamp the list offset after the new result count was known.
  - `OnVerticalScroll` accepted the supplied offset without validating it against the current result set.
  - `RenderRows()` and `UpdateResultRange()` used that offset directly.
- The saved market snapshot contains `Spire of the Stoneshaper`, but no literal `Empresses' Spire` in either saved market or Browse snapshot. This is older persisted data and cannot establish whether Empresses' Spire was listed on the Auction House after that scan or whether the replication response included it.

## Root cause and competing hypotheses

1. **Stale virtual-list scroll offset. CONFIRMED.** The `99-2 / 2` counter is direct evidence that the new two-row result set is being evaluated with an offset beyond its end. The previous implementation reset before the new result set was committed and accepted later scroll callbacks without clamping.
2. **Search matcher omits Empresses' Spire. NOT ESTABLISHED by this screenshot.** The screenshot proves the result pane is positioned incorrectly; it does not show the two matching rows, so it cannot establish which records matched or whether Empresses' Spire was in the catalogue.
3. **Empresses' Spire absent from saved market snapshot. OBSERVED for the supplied persisted snapshot only.** Its literal name is absent from the saved Full Market and Browse snapshots. The exact item hyperlink/ID and a fresh full-market scan are needed to distinguish missing acquisition data from a name/indexing problem.

## Implementation in 0.12.2

- Added `GetMaximumListOffset(total)` and `ClampListOffset(offset, total)`.
- `FinishView()` resets the list offset after installing the new rows and resizing the scroll child, then resets the ScrollFrame.
- `RenderRows()` clamps offsets against the current result set before calculating the first visible row.
- `OnVerticalScroll` clamps stale offsets and corrects the ScrollFrame under a reentrancy guard.
- `UpdateResultRange()` clamps before computing the visible range.
- No search matching rules, debounce, tooltip search, rarity lookup, item-data loading, market acquisition, SavedVariables schema, or addon dependencies changed.
- Added regression tests for result-set reset, scroll callback clamping, range-counter clamping, and empty/small/large result bounds.

## Ownership and compatibility

Modulo Market owns its virtual list and search presentation. No ProfessionMaster or other optional addon dependency was introduced. No public API contract changed.

## Validation

- Focused 0.12.2 scroll, 0.12.1 rarity and 0.12.0 search compatibility tests: 15 passed.
- Full suite on exact 0.12.1 baseline: 373 passed / 90 failed.
- Full suite on 0.12.2 working tree: pending final package validation.
- Lua syntax, fresh extraction tests, ZIP CRC, manifest inventory and SHA-256 are recorded in the release handoff after packaging.

## Runtime status and acceptance

- Forever: 0.12.2 NOT RUN. The screenshot is evidence of the 0.12.1 defect, not proof of the correction.
- Retail: NOT RUN.
- Rarity colours and complete item-name rendering were player-confirmed on 0.12.1 and are preserved unchanged in this slice.
- The 0.11.9 no-freeze result remains player-observed; this slice does not alter that processing path.

Acceptance on Forever:
1. Install 0.12.2 over 0.12.1 without deleting SavedVariables.
2. Scroll All Items well down the list.
3. Enter `spire` and wait for the 500 ms debounce and filtering to finish.
4. Confirm the result counter starts at `1` (for example `1-2 / 2`), rows are visible, and the list is at the top.
5. Change the query quickly and confirm an older scroll position cannot hide the new results.
6. Clear the query and confirm the full catalogue is visible and scrolling works normally.

## Remaining blocker: Empresses' Spire

The saved snapshot does not contain the literal item name. The current screenshot's broken scroll position prevented visual inspection of the two search results, so it does not settle whether the search matcher includes Empresses' Spire.

Next evidence needed: the exact Auction House item hyperlink (Shift-click the item and paste the link) or a fresh Full Market scan taken while the item is listed. This supplies the item ID and allows us to distinguish source-data omission from name-index omission.
