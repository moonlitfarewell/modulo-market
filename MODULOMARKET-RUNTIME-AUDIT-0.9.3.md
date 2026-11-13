# MODULOMARKET RUNTIME AUDIT 0.9.3

## Result
Corrected Blizzard-native main-window chrome and title treatment. Source implementation and offline validation are complete. Forever runtime acceptance of 0.9.3 remains NOT RUN.

## Player problem and requested result
The 0.9.2 change removed too much: the user wanted the thin decorative gold perimeter removed, not the Blizzard frame background/title-bar treatment. The custom centered title plaque should also be removed so the title sits directly in the window's native title region, matching the supplied default Blizzard frames (Map & Quest Log, Talents, Progress Track).

## Evidence and diagnosis
- User-provided reference screenshots show default Blizzard windows with a continuous textured/dark frame background, a native full-width title strip, centered title text in that strip, a close control at the upper-right, and internal content panels.
- User's explicit correction: restore the frame/title background, remove the separate custom title background/plaque, and position the title in the native title area.
- 0.9.2 source used `BasicFrameTemplateWithInset` but explicitly hid `NineSlice`, `Inset`, `TitleBg`, and `TopTileStreaks`. It then drew a separate 340x36 custom title plaque and anchored `TitleText` to that plaque. This is the direct cause of the mismatch.
- The 0.9.2 custom full-window gold bevel was already removed and remains removed. Inner panel borders are retained.

## Changes in 0.9.3
- Stop hiding Blizzard's `NineSlice`, `Inset`, `TitleBg`, and `TopTileStreaks`; the template's native background/frame/title strip are restored.
- Remove the custom 340x36 title plate, its inset tint, side accents and custom plaque bevel.
- Anchor `frame.TitleText` centered in the native top title region (`frame` top, -18px), with a width suitable for the centered title.
- Keep the custom full-window outer gold bevel absent.
- Preserve the native close control.
- Preserve all internal ModuloMarket panel, tab, filter, table, dropdown, inspector and history borders.
- Preserve 0.9.1 dropdown popup lifecycle fix and all market/data behavior.

## Ownership and scope
- ModuloMarket UI only. No parent MODULO or specialist addon changes.
- No API/dependency, SavedVariables, market calculation, auction scan, recipe/gathering data or provenance changes.
- Six tabs remain; My Crafts remains absent.

## Validation
- Focused native-window-chrome regressions: 4 PASS.
- Full suite: 259 PASS / 61 historical failures.
- Direct comparison against the exact 0.9.2 parent archive: the same 61 failing test IDs; zero new failing IDs.
- Lua syntax: 9/9 PASS.
- Fresh extraction, manifest inventory, ZIP CRC and fresh-extraction suite are recorded after packaging.
- 0.9.2 screenshot is FOREVER OBSERVED for 0.9.2 only. 0.9.3 target-client runtime acceptance: NOT RUN.

## Player acceptance
Install 0.9.3 on Forever 1.60.1 build 70938 and confirm:
1. Native textured frame/background and full-width title strip are visible again.
2. “Modulo Market” sits directly in the native title strip, with no separate plaque/background behind the text.
3. The extra thin gold full-window perimeter bevel remains absent.
4. Native close control works.
5. All inner panel borders remain unchanged.

- Focused tests: `tests/test_modulomarket_0_9_3_native_window_chrome.py` — 4 PASS.
- Full suite: `python -m pytest -q` — 259 PASS / 61 historical failures. Compared directly with the exact 0.9.2 parent archive, the same 61 failing test IDs remain; zero new failures.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
- Historical assertions that pinned the 0.9.2 release version were advanced to 0.9.3. The prior title-plaque assertion was updated to the native title-strip requirement.
