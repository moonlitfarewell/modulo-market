# MODULOMARKET RUNTIME AUDIT 0.9.4

## Result
Implemented the requested title-strip sizing and tab-separator cleanup in source. Offline validation passes. Forever runtime acceptance of 0.9.4 is NOT RUN.

## Player problem and observable result
The 0.9.3 screenshot shows the native Blizzard title strip still too shallow compared with the supplied default Blizzard windows. The title should remain centred but fit the taller title region. The tab row also has thin vertical lines between adjacent tabs that look like unintended dividers.

## Evidence and diagnosis
- User-provided 0.9.3 screenshot shows the main window title strip at the top, visibly shallower than the Map & Quest Log, Talents and Progress Track reference frames.
- Source inspection of `MarketUI.lua` found `frame.TitleText` anchored at -18 with a 360x28 region, while `frame.TitleBg` retained the template's default height. 0.9.3 did not explicitly size the native title background.
- Source inspection found each tab explicitly creates `marketLeft` and `marketRight` one-pixel textures, in addition to the top and bottom strokes. The adjacent left/right strokes explain the small vertical separators.
- User asked to remove the tab separators, not tab outlines or internal content borders.

## Changes in 0.9.4
- Set native `frame.TitleBg` height to 38 pixels when the template exposes `SetHeight`.
- Centre the title at y=-19 and size its text region to 280x24 so the label fits within the resized native title strip.
- Remove only the per-tab vertical `marketLeft` and `marketRight` textures.
- Retain each tab's background, top and bottom accent strokes, highlight, selected marker and label.
- Retain the tab-strip outer frame and all internal ModuloMarket panel/control borders.
- Preserve the 0.9.3 native frame background, title texture and close control, plus the 0.9.1 dropdown lifecycle fix.

## Ownership, dependencies and scope
- ModuloMarket UI only; no parent MODULO or specialist addon changes.
- No API/dependency, SavedVariables, market calculation, auction scan, recipe/gathering data, item catalogue or provenance changes.
- Six tabs remain; My Crafts remains absent.
- No new external dependencies or security-sensitive behavior.

## Acceptance and exit criteria
On WoW Forever 1.60.1 build 70938, verify:
1. Native title strip is visibly comparable in height to the supplied Blizzard reference windows.
2. “Modulo Market” remains centred and fits cleanly within the title strip.
3. No vertical one-pixel separators remain between adjacent tabs.
4. Tab top/bottom accents, hover, selected state and click behavior still work.
5. Internal panel borders and the native window frame remain intact.
6. Existing dropdowns still close correctly when the main window closes.

## Validation
- Focused 0.9.4 tests: 4 PASS.
- Full offline suite: 263 PASS / 61 historical failures.
- Exact 0.9.3 parent comparison: same 61 failing test IDs; zero new failing IDs.
- Lua syntax: 9/9 PASS.
- Archive CRC, manifest inventory, fresh extraction and fresh-extraction tests recorded after packaging.
- User screenshot provides FOREVER OBSERVED evidence for 0.9.3 visual appearance only. It does not prove 0.9.4 behavior. 0.9.4 Forever runtime acceptance: NOT RUN.

## Known evidence gaps
- The child repository does not include child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA or SOURCE-REVIEW-LEDGER records. They were not reconstructed.
- The uploaded screenshot is a visual report, not runtime evidence for this new 0.9.4 change.
