# MODULO MARKET — Runtime Defect Audit 0.4.1

**Audit date:** 2026-11-10  
**Base:** ModuloMarket 0.4.0 complete source bundle  
**Candidate:** ModuloMarket 0.4.1  
**Scope:** Market UI rendering, filters, sort indicator, backdrop opacity, minimap launcher and Auction House launcher lifecycle  
**Parent MODULO:** 1.0.48 (unchanged)  
**Target client:** WoW Forever; interface target in the addon TOC remains 16001. Exact live client build for the new screenshots was not supplied in this turn.

## 1. Player problem and observable result

The player supplied screenshots showing:

- Profession dropdown appears but selecting it does not change the list.
- Item-role dropdown appears but selecting it does not change the list.
- The sort-direction glyph renders as a small missing-character box.
- Market's dark backdrop is too opaque and needs an in-window adjustment.
- Scrollbar and result-range counter advance through the 5,221-item market, but the rows are blank at later offsets, including near the end.
- Market needs a minimap launcher.
- The Auction House launcher has not yet been tested by the player.

Acceptance target: every scroll position displays the corresponding catalogue items through the final item; each enabled dropdown selection changes the result set; sort direction is visible; backdrop alpha is adjustable and saved; a movable minimap button opens Market; Auction House launch remains separately testable.

## 2. Evidence and competing hypotheses

### 2.1 Blank rows at later scroll offsets

**Observed evidence:** the screenshots show result ranges advancing to approximately `1582-1604 / 5221`, `2696-2718 / 5221`, and `5198-5220 / 5221` while the list area is blank. This is not evidence that the underlying result array has only 23 items; it shows the scroll position and range counter advance while the visible row pool does not follow.

**Hypothesis A — virtual rows remain anchored at the top of the scroll child.** The ScrollFrame scrolls its child, but the reusable row buttons retain their original top-of-child anchors. The render function changes their text without moving them to the absolute index they represent. At later offsets, those buttons have scrolled out of the viewport. **Source inspection confirms this defect.**

**Hypothesis B — scroll-child height or offset-to-index arithmetic is wrong.** This could also cause an incorrect result range or rows to be hidden beyond the child. However, 0.4.0 sets the child height to `#viewRows * rowHeight`, and the screenshot's counter follows the offset through the full result count. It does not explain why the row buttons themselves are never re-anchored.

**Distinguishing diagnostic:** at a non-zero scroll offset, inspect `GetVerticalScroll()`, `startIndex`, `viewRows[startIndex]`, each visible row's anchor relative to `scrollChild`, and `IsShown()`. Hypothesis A predicts the data index advances while row anchors remain at their original y positions; Hypothesis B predicts incorrect child dimensions or index arithmetic. The source-level inspection and new harness assert the former. The harness also asserts that the final item is assigned to a visible row at the maximum scroll offset.

### 2.2 Dropdowns that appear inert

**Hypothesis A — Lua 5.1 callback closure captures the generic-for option variable.** Every `info.func` closure may resolve to the final menu option rather than its own entry. In the role menu the final Gatherable option can be disabled, making all selections appear inert; in the profession menu choices can all resolve to the final profession. **The source used this unsafe closure pattern.**

**Hypothesis B — no profession data was populated or the selected role was disabled.** Profession options depend on captured profession data and future recipe provider state; some role choices are intentionally disabled when the data provider or skill data is unavailable.

**Distinguishing diagnostic:** open the actual menu, enumerate each entry's `value` and `disabled` state, invoke one enabled entry's callback, and inspect the filter state/result count. 0.4.1 captures a fresh `selectedValue` and `selectedDisabled` for each entry. The new Lua harness opens both menus and selects Tailoring and Known crafts, then verifies the resulting filtered item set.

### 2.3 Sort arrow rendered as a box

The source appended Unicode triangle characters to the column label. The screenshot shows those characters are not rendered by the client's active font. The replacement uses Blizzard's scrollbar up/down arrow textures, cropped to show the direction triangle without the square button border.

## 3. Ownership and scope

- ModuloMarket owns these catalogue controls, list rendering, background presentation and its launchers.
- MODULO 1.0.48 is unchanged. MODULO does not depend on Market.
- Auctionator, ProfessionMaster, GatherLite and LibProfessionDB remain independent; LibProfessionDB remains optional for future-recipe data.
- No other addon SavedVariables or private runtime APIs are introduced.
- No scanner, Replicate, recipe-capture, market persistence or economics behaviour is intentionally changed.

## 4. Implementation in 0.4.1

### 4.1 Virtualized list rendering

- `UI.RenderRows()` now clears and re-anchors each reusable row button at `-((index - 1) * rowHeight)` relative to the scroll child on every render.
- The full result array and incremental catalog/filter/sort processing are retained.
- The row pool is 25 rather than 23. With a 510px viewport and 22px row height, this covers partially visible rows at both viewport edges. It remains a small reusable pool, not one widget per item.
- The new harness checks an intermediate offset, verifies the first visible row's text and anchor, then scrolls to the maximum offset and confirms the final catalogue item is rendered.

### 4.2 Functional dropdowns

- Each dropdown menu callback captures its own value and disabled flag in locals.
- Profession and role filters continue to use the existing `ProfessionData.Matches` index and incremental `StartViewBuild()` path.
- Disabled Future crafts/Gatherable choices remain disabled when their required data is unavailable; this is not represented as an empty result set.

### 4.3 Sort direction indicator

- Removed font-dependent Unicode triangles.
- Added a small texture indicator beside the active sortable column label, using `UI-ScrollBar-ScrollUpButton-Up` or `UI-ScrollBar-ScrollDownButton-Up` and cropping the button border.

### 4.4 Adjustable backdrop opacity

- Added an in-window horizontal slider with a 15%-85% range and a percentage readout.
- The slider updates the frame backdrop, main background texture and inset background only; text and controls retain their normal alpha.
- The chosen alpha is stored in `ModuloMarketDB.backgroundOpacity`.
- Default alpha for a new install is 48%; an existing saved value is preserved.

### 4.5 Minimap launcher

- Added a coin-icon button attached to `Minimap`.
- Left-click opens/toggles Market; drag moves the button around the minimap.
- Its angular position is saved in `ModuloMarketDB.minimapAngle`.
- Tooltip explains open and drag interactions.

### 4.6 Auction House launcher retry

- Checks both `AuctionHouseFrame` and legacy `AuctionFrame` when present.
- Retries on `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD` and `AUCTION_HOUSE_SHOW`.
- Hooks the parent frame's `OnShow` when `HookScript` is available.
- The player explicitly has not tested the Auction House launcher yet. This source change is not an observed runtime pass.

## 5. Dependencies, compatibility and risks

- TOC interface remains 16001; no dependency or optional dependency changes.
- SavedVariables additions are non-destructive: `backgroundOpacity` and `minimapAngle` are optional numeric keys with defaults when absent.
- Slider, texture, minimap and Auction House frame methods are Blizzard UI APIs, but their exact availability/visual behavior on the player's Forever build is NOT RUN in this pass.
- TOOLTIP strata remains as previously implemented; no new evidence was supplied that would justify changing the accepted frontmost-window policy.
- The 25-row pool increases widget count by two only. It does not scale with the 5,221+ item catalogue.
- A texture path existing in Blizzard UI source is not proof that the texture appears correctly on the target client; visual confirmation is still required.

## 6. Tests and offline evidence

Commands run for this candidate:

- `pytest -q -p no:cacheprovider tests` — **86 passed**.
- `for f in AddOns/ModuloMarket/*.lua tests/*.lua; do texluac -p "$f"; done` — **PASS** for every addon and harness Lua file.
- `texlua tests/market_ui_0_4_1_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**, 181 simulated frames; exercises row anchoring at intermediate and final offsets, both dropdown callbacks, sorting indicator, opacity persistence, minimap click/drag and Auction House launcher.
- `texlua tests/recipe_engine_0_3_0_harness.lua AddOns/ModuloMarket/RecipeEngine.lua` — **PASS**.
- `texlua tests/profession_data_0_4_0_harness.lua AddOns/ModuloMarket/ProfessionData.lua AddOns/ModuloMarket/GatheringItems.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**.
- `ModuloMarket-0.4.1.zip` — **CRC PASS**, 53 files; fresh extraction completed and every extracted file SHA-256 matched the working tree; TOC/Core/manifest version agreement **PASS**.

These are offline source/harness tests. They do not establish live Forever behavior.

## 7. Forever runtime status

**FOREVER OBSERVED:** player screenshots from the 0.4.0 installation show the counter/scrollbar advancing through a 5,221-item market while later list rows are blank; the player confirms the two dropdowns are not working and sort glyph appears as a box. The player has not tested the Auction House launcher.

**SOURCE IMPLEMENTED / OFFLINE VERIFIED:** absolute row re-anchoring; 25-row viewport coverage; dropdown callback capture fix; texture sort arrow; opacity slider and SavedVariables persistence; minimap launcher and angle persistence; Auction House launcher lifecycle retries.

**FOREVER NOT RUN / UNKNOWN:**
- 0.4.1 installed and loaded on the actual Forever client.
- Full scroll from first item through final item with all rows visible.
- Profession dropdown menu opening and filtering on the live client.
- Item-role dropdown menu opening and filtering on the live client.
- Sort arrow texture appearance and orientation on the live client.
- Opacity slider drag, background alpha and SavedVariables persistence across `/reload`.
- Minimap button appearance, click, drag and saved position across `/reload`.
- Auction House button visibility on open, click-to-open Market, modern/legacy frame lifecycle and overlap with Auctionator.
- ESC close behavior and TOOLTIP strata visual acceptance remain previously implemented but are not retested by this pass.

No Forever runtime verification is claimed.

## 8. Player acceptance and exit criteria

Install 0.4.1, `/reload`, then test against the existing saved market snapshot without starting a new Replicate scan:

1. Open `/mm`; verify the background slider changes the backdrop from darker to more transparent and retains its value after `/reload`.
2. Open the profession dropdown; choose a profession with captured recipes. Verify the list and count change. Return to All professions.
3. On All items, choose Known crafts and verify only known craft outputs appear. Test Gatherable only after a supported gathering profession and skill are captured. Test Future crafts only with LibProfessionDB installed and ready.
4. Click Cheapest twice; verify an up/down triangle appears and the sort reverses.
5. Scroll to a middle offset and to the absolute bottom. Verify rows remain populated and the last item is visible; the final range must include item 5,221 for the supplied screenshot's 5,221-item snapshot.
6. Click the minimap coin button; verify Market opens. Drag it to another minimap position, `/reload`, and verify it remains there.
7. Open the Auction House and look for the Modulo Market launcher. Click it and verify Market opens above Auctionator. This specific step has not yet been tested by the player.
8. Press Escape and verify Market closes.

**Exit:** close this defect only after the player-visible checks pass on the relevant Forever client. If any control still fails, keep the defect open and capture the exact client build, Lua errors, selected filter, result count, scroll offset, visible row text/anchors, and minimap/Auction House frame state.
