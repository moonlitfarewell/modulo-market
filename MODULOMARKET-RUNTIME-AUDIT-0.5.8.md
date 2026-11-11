# ModuloMarket Runtime Audit — 0.5.8

**Date:** 2026-11-11
**Addon / bundle version:** 0.5.8
**Parent MODULO:** 1.0.48 — unchanged
**Scope:** Correct the Market frame strata regression that kept native and addon hover tooltips behind the window.

## Player problem and evidence

The user supplied 0.5.7 runtime screenshots from Forever client build `1.60.1.70888`. Native item tooltip content is visible through/behind the Market surface instead of compositing above it. This is a reproduced player-visible failure of 0.5.7's tooltip-layering acceptance criterion.

## Competing hypotheses and distinguishing diagnostic

1. **Tooltip strata is too low or tooltip frame level is too low.** Distinguish by inspecting `GameTooltip:GetFrameStrata()` and `GetFrameLevel()` while hovering.
2. **The Market is promoted into the tooltip strata and raised over GameTooltip.** Distinguish by tracing every `SetFrameStrata` call on the Market frame, especially the open/raise path, and comparing the strata of both frames.

Source inspection of the complete 0.5.7 `MarketUI.lua` identifies hypothesis 2. `CreateUI()` sets the Market frame to `DIALOG`; the `OnShow` script also sets `DIALOG`; however, `UI.Raise()` then unconditionally called `frame:SetFrameStrata("TOOLTIP")` each time the Market opened. The Market therefore occupied the same strata as GameTooltip, where frame level controls overlap. `RaiseMarketTooltip()` raising GameTooltip's frame level cannot guarantee it remains above a subsequently raised Market frame.

## Authoritative strata behavior

WoW orders frame strata from lower to higher: `BACKGROUND`, `LOW`, `MEDIUM`, `HIGH`, `DIALOG`, `FULLSCREEN`, `FULLSCREEN_DIALOG`, `TOOLTIP`. Frame level only orders frames within a shared strata. Thus the Market belongs at `DIALOG`, and hover tooltips at `TOOLTIP`. References: Warcraft Wiki Frame Strata and UI rendering process; Frame:SetFrameStrata API. This external documentation is general WoW UI behavior, not proof of the Forever client's exact runtime.

## Change

- `UI.Raise()` now explicitly keeps the Market frame at `DIALOG` before setting it top-level and raising it.
- `CreateUI()` and `OnShow` continue to set `DIALOG`, so all three lifecycle points agree.
- `GameTooltip` and custom dropdown popup frames remain at `TOOLTIP`.
- Tooltip frame-level adjustment remains local to the tooltip and cannot promote the Market.
- Historical tests that incorrectly expected the Market itself to use `TOOLTIP` were corrected to assert `DIALOG`.
- README's contradictory statement that the Market uses `TOOLTIP` was corrected.

No item/recipe tooltip content, opacity, filter, Materials layout, recipe capture, market data, auction snapshot gate, dependency, or parent MODULO code was changed.

## Risks and limits

- This source fix directly removes the identified strata inversion. It does not prove the Forever client has no additional custom tooltip owner/parent behavior.
- `GameTooltip:SetFrameStrata("TOOLTIP")` and Market `DIALOG` need live acceptance on build `1.60.1.70888`.
- If a tooltip remains behind after this change, next diagnostic is a bounded runtime dump of Market and GameTooltip `GetFrameStrata()`, `GetFrameLevel()`, `GetParent():GetName()`, and `IsShown()` at hover time, plus `/framestack` evidence. Do not add more frame-level offsets without that evidence.

## Offline verification

- Full Python test suite: see release verification results.
- Lua syntax: all addon Lua files.
- Focused regression asserts `UI.Raise()` uses `DIALOG` and never sets the Market to `TOOLTIP`.
- UI harness asserts opened Market remains `DIALOG`.
- ZIP integrity, manifest inventory, TOC/manifest/README version agreement and fresh extraction are checked.

## Runtime acceptance

**FOREVER runtime: NOT RUN.** Install 0.5.8 on Forever build `1.60.1.70888`, open the Market, hover an item name, recipe name, tab and filter. Every tooltip must render completely above the Market, including over opaque panel areas. Confirm the Market itself remains interactive and Escape-closeable. Capture `/framestack` while a tooltip overlaps the Market if any failure remains.

The defect remains OPEN until the user confirms the tooltip visibly renders above the Market on the target client.
