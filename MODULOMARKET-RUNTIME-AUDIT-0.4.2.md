# MODULO MARKET — Runtime Defect Audit 0.4.2

**Audit date:** 2026-11-10  
**Base:** ModuloMarket 0.4.1 complete child bundle  
**Candidate:** ModuloMarket 0.4.2  
**Parent MODULO:** 1.0.48 (unchanged)  
**Target:** WoW Forever; TOC interface 16001  
**Scope:** backdrop opacity, profession/item-role dropdown interaction, craft-tab clarity, Auction House launcher placement. Full-catalogue rendering and minimap behavior are preserved.

## 1. Player problem and observable result

The player reports that after installing 0.4.1:

- The full 5,221-item catalogue now renders through the final entries.
- The minimap launcher works.
- The opacity slider thumb and percentage change, but the visible background does not.
- Profession and item-role dropdowns still do not open or apply selections.
- My crafts and Profitable appear too similar in practical use.
- The Auction House launcher appears out of place.

The full-catalogue and minimap fixes are accepted as player-observed for 0.4.1 and are preserved.

## 2. Evidence and root-cause diagnosis

### 2.1 Background opacity does not change the visible panel

**Competing hypotheses:**

- **A — wrong texture target:** the slider updates its numeric value and SavedVariables, but the large inner panel texture is not receiving the alpha change.
- **B — alpha is applied to the correct texture but an opaque child/overlay is painted above it.**

**Diagnostic:** inspect the frame template's named background regions and compare the code's alpha targets with the visible content region. The Blizzard `BasicFrameTemplateWithInset` template exposes its tiled main background as `Bg` and the large inner panel as `InsetBg` (parent key). The previous 0.4.1 code updated `Bg` and `Inset.Bg`; it did not update `InsetBg`. This directly supports hypothesis A. The 0.4.2 harness now creates and checks both template regions and verifies both receive the slider alpha.

**Implementation:** `ApplyBackgroundOpacity` now updates `frame.Bg`, `frame.InsetBg`, and the older nested `frame.Inset.Bg` fallback when present. The slider continues to save `ModuloMarketDB.backgroundOpacity`; labels and controls are not faded.

**External template reference:** `https://github.com/Resike/BlizzardInterfaceCode/blob/retail/Interface/FrameXML/UIPanelTemplates.xml` (BasicFrameTemplateWithInset / InsetBg parent key). This is corroborating FrameXML reference, not proof of the exact Forever client XML build.

### 2.2 Profession and item-role dropdowns remain inert

**Evidence:** the player reports both dropdowns still do not work after 0.4.1. The 0.4.1 harness directly called `UIDropDownMenu_Initialize` and invoked the selected entry callback. It did not click the rendered dropdown control, prove the popup became visible, or exercise the actual popup option button. Therefore its test did not cover the player's failing interaction path.

**Competing hypotheses:**

- **A — stock dropdown dispatch failure:** the `UIDropDownMenuTemplate` arrow/button is not dispatching to the menu-opening function or the target client's dropdown menu library is not creating/showing the menu.
- **B — popup visibility/interaction failure:** the menu is created, but is behind/clipped by the TOOLTIP-strata Market frame, positioned outside the visible area, or its entries do not receive clicks.

**Distinguishing diagnostic:** on the target client, click the dropdown arrow and inspect whether the stock dropdown list frame becomes shown and whether its option buttons are visible/hit-testable. No such runtime trace was supplied, so the precise 0.4.1 live failure mode remains UNKNOWN.

**Implementation decision:** replace the stock dropdown path rather than guess which of A/B is occurring. 0.4.2 uses a local `UIPanelButtonTemplate` control, a dedicated TOOLTIP-strata popup parented to `UIParent`, and visible Blizzard-style option buttons. The dropdown's own `OnClick` opens/closes the popup. Selecting an enabled option updates the selected value/text, invokes the filter rebuild, and closes the popup. Disabled Future/Gatherable choices remain disabled until their data requirements are met.

**Offline diagnostic coverage:** the new harness clicks the dropdown control, asserts that the popup is shown, clicks a visible option button, verifies selection state/text, verifies popup closure, and checks the filtered result set. This tests more of the real interaction chain than the previous callback-only test. Forever menu rendering remains NOT RUN.

### 2.3 My crafts versus Profitable

The underlying filter logic was already distinct:
- **My crafts** contains all captured known recipes, including loss-making and incomplete/unpriced recipes.
- **Profitable** includes only recipes with complete required market prices and positive estimated profit after AH cut; its default sort is profit descending.

The player-facing distinction was not discoverable enough. 0.4.2 adds concise tab tooltips explaining the inclusion rules. No economics calculation or recipe eligibility was changed.

### 2.4 Auction House launcher placement

0.4.1 attached a 132×20 button at the parent's top-left, offset 64px. This put it near the portrait and browse controls. 0.4.2 reduces it to 116×20 and anchors it to the top-right header strip, 42px from the right edge and 34px below the top. The button remains on TOOLTIP strata and still opens Market.

The player's screenshot shows the 0.4.1 placement; no 0.4.2 Auction House screenshot has yet been supplied. New placement is source/offline verified only.

## 3. Ownership, boundaries and dependencies

- ModuloMarket owns all changes in this slice.
- MODULO 1.0.48 is unchanged; MODULO does not depend on Market.
- Market remains a separate optional child addon depending on Modulo.
- No dependency on Auctionator, ProfessionMaster or GatherLite is introduced.
- LibProfessionDB remains optional.
- Existing market snapshot, scanner, Replicate cooldown, recipe capture, SavedVariables, profit calculations and virtualized catalogue are not intentionally changed.

## 4. Implementation in 0.4.2

1. Apply alpha to the actual `BasicFrameTemplateWithInset` inner texture `InsetBg` as well as `Bg`, retaining compatibility with nested inset templates.
2. Replace `UIDropDownMenuTemplate` with a local click-driven popup using native panel buttons. Profession and role filters still call the existing `UI.StartViewBuild()` path.
3. Add explanatory tooltips to My crafts and Profitable tabs without adding permanent text clutter.
4. Move and resize the Auction House launcher to the top-right header strip.
5. Preserve 0.4.1 full-catalogue row positioning, 25-row viewport pool, sort texture, draggable minimap button, SavedVariables and ESC registration.

## 5. Tests and offline evidence

- Python regression suite: **91 passed** (including 5 new 0.4.2 source checks; see final command record).
- Lua syntax: all addon and harness Lua files checked with `texluac -p`.
- 0.4.2 UI harness: click-driven profession and role menu open/select/close, filtered result set, `Bg` and `InsetBg` alpha, full catalogue intermediate/final scroll, My crafts/Profitable semantics, minimap interaction, Auction House header anchor.
- Existing recipe, profession-data, scanner and Replicate harnesses rerun.
- Archive CRC, manifest inventory, TOC/Core/manifest version agreement, fresh extraction and SHA-256 are checked after packaging.

These are offline tests and source checks, not live client acceptance.

## 6. Forever runtime status

**FOREVER OBSERVED:**
- 0.4.1 full-catalogue scroll now renders all items, confirmed by player screenshot.
- 0.4.1 minimap launcher opens Market, confirmed by player.
- 0.4.1 opacity control's value changes without visible background transparency.
- 0.4.1 profession and role dropdowns remain non-functional.
- 0.4.1 Auction House launcher appears out of place.

**0.4.2 SOURCE IMPLEMENTED / OFFLINE VERIFIED:**
- correct template inner background alpha target;
- click-driven profession and role menus;
- clarified craft-tab semantics;
- Auction House launcher repositioning.

**FOREVER NOT RUN / UNKNOWN:**
- 0.4.2 slider visibly changes both background textures on Forever;
- alpha setting persists after `/reload` on Forever;
- profession and role popup open, visibility, selection and result updates on Forever;
- disabled Future/Gatherable option behavior on Forever;
- tab tooltips display correctly on Forever;
- Auction House launcher placement, visibility and click on Forever;
- any new live Lua error or interaction conflict.

No Forever runtime verification is claimed.

## 7. Acceptance and exit criteria

Install 0.4.2 and `/reload`, without starting a new Replicate scan:

1. Drag Background slider from about 15% to 85%; confirm the inner panel visibly changes from transparent to opaque. Confirm text/buttons remain readable and do not fade. `/reload` and confirm the value persists.
2. Click All professions, choose a captured profession (e.g. Tailoring), and confirm the list/count changes. Restore All professions.
3. Click All item roles, choose Known crafts, and confirm only known craft outputs appear. Restore All item roles.
4. Confirm My crafts includes loss-making/incomplete recipes and Profitable excludes them, retaining only fully priced positive-profit recipes.
5. Open Auction House and inspect the new top-right header placement; click it and confirm Market opens.
6. Reconfirm the final catalogue entries and minimap launcher remain correct.

A failed live interaction remains open until the player-visible behavior passes. The 0.4.2 source and offline harness do not close the Forever runtime defect.


## 8. 0.4.2 build verification record

Commands and results on the candidate source tree:

- `pytest -q -p no:cacheprovider tests` — **91 passed**.
- `texluac -p` on all 17 addon and Lua harness files — **PASS**.
- `texlua tests/market_ui_0_4_2_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**, 181 simulated frames.
- `texlua tests/recipe_engine_0_3_0_harness.lua AddOns/ModuloMarket/RecipeEngine.lua` — **PASS**.
- `texlua tests/profession_data_0_4_0_harness.lua AddOns/ModuloMarket/ProfessionData.lua AddOns/ModuloMarket/GatheringItems.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**.
- Manifest file inventory matches the complete extracted package tree — **PASS**.
- TOC, Core and manifest version agreement at 0.4.2 — **PASS**.
- Fresh extraction, archive CRC and per-file SHA-256 comparison — **PASS** (56 files; no hash mismatches).

The earlier 0.4.1 UI harness is retained as historical evidence and is not expected to pass against the new custom dropdown implementation; the new 0.4.2 click-driven harness replaces that UI acceptance path.
