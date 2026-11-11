# Tooltip strata correction — 0.5.8

## Player evidence

0.5.7 Forever screenshots show item tooltip content behind the Market window. The player explicitly requested that the Market be at least one strata below native tooltips.

## Root cause

The Market was correctly set to `DIALOG` during creation and `OnShow`, but `UI.Raise()` changed it to `TOOLTIP` each time the window opened. The tooltip and Market then shared the same strata, allowing frame level/raise order to place the Market over the tooltip. The 0.5.7 tests checked the creation assignment but did not inspect the open/raise lifecycle.

## Correction

`UI.Raise()` now explicitly sets the Market to `DIALOG`. Native `GameTooltip` and custom dropdown popups remain at `TOOLTIP`. Tests now check the complete raise path and assert the Market remains `DIALOG`.

## Acceptance

Offline tests verify source behavior only. Forever runtime tooltip-over-window acceptance remains NOT RUN until verified on build `1.60.1.70888`.
