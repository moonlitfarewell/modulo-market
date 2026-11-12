# ModuloMarket Runtime Audit 0.7.0 — tooltip search, crafting scope and Economics layout

**Previous child bundle:** `ModuloMarket-GitHub-Update-0.6.9.zip`  
**Target client:** WoW Forever 1.60.1 build 70888 (target only; runtime NOT RUN)  
**Parent MODULO:** 1.0.48, unchanged  
**Release status:** SOURCE IMPLEMENTED; FOCUSED OFFLINE CHECKS PASS; FOREVER RUNTIME NOT RUN.

## Player problem and observable result

The player wants to search item effects/descriptions (e.g. healing or spell damage), choose whether recipe planning combines characters or is restricted to the currently logged-in character, and remove wasted width/truncation in Economics.

## Change summary

1. Item search now supplements name/recipe/profession/ID/reagent matching with loaded item tooltip text. Tooltip lines are cached by item ID. When item data is not loaded, the client load is requested with a maximum of 20 outstanding requests and 60 uncached tooltip inspections per filtering frame; item-data completion restarts the active search.
2. A persistent Account Crafting / Character Crafting selector occupies the top-right header gap. Account mode unions learned recipes and positive profession evidence across saved character stores. Character mode uses only the logged-in character's realm/name store and native profession list.
3. Current native profession lists are saved per character when readable. Account absence is not treated as negative evidence: recipes for professions not represented by saved character evidence remain Unknown, and the Not learnable filter is disabled in account scope.
4. Economics numeric columns are measured from their headers and visible row values, anchored from the right edge, clamped, and the Item column receives remaining width. Measurements update as visible rows change.

## Evidence and ownership

- Source base: `ModuloMarket-GitHub-Update-0.6.9.zip`; CRC verified before modification.
- Parent source: `MODULO-Project-Source-1.0.48.zip`; CRC verified. MODULO remains unchanged.
- Character recipe evidence is stored by realm and character in `professionRecipesByCharacter`.
- Account mode includes only characters represented in saved recipe/profession evidence. It cannot assert facts about an unobserved character.
- No new API requests to ForeverDB, API credentials, external addon dependencies, or market data changes were introduced.
- ModuloMarket remains a separate optional child addon; MODULO does not depend on it.

## Verification performed

- Lua syntax: all 9 addon Lua files parse with `texlua` — PASS.
- Account-scope Lua harness: union across two saved characters, current-character isolation, profession union and snapshot persistence — PASS.
- Focused source/regression tests: 18 passed (new 0.7.0 feature tests, 0.6.9 profession economics/status tests, and 0.6.8 row status tests).
- Full historical suite: 166 passed, 51 failed. Failures are retained in the report rather than relabelled as passes; many are stale assertions tied to old versions, removed tabs, and prior layout contracts. These require a separate historical test maintenance pass.
- ZIP CRC, manifest inventory, version agreement and fresh extraction are recorded in the release handoff after packaging.

## NOT RUN / UNKNOWN

- Forever client runtime: NOT RUN.
- Tooltip method behavior and tooltip font-string extraction on Forever build 70888: UNKNOWN until in-game test.
- Whether `ITEM_DATA_LOAD_RESULT` and `GET_ITEM_INFO_RECEIVED` provide the expected item IDs for every item class: UNKNOWN until in-game test.
- Account view coverage depends on characters logging in and saving profession snapshots/recipe lists; unobserved characters remain unknown.
- Economics layout uses the currently visible virtual row pool for text measurement; long values in off-screen rows may cause a width adjustment when scrolled into view.
- Retail compatibility: NOT RUN.

## Player acceptance checklist

1. Search for a known food's `healing` effect and an item with `spell damage` in its tooltip; results must include matches even when the name does not contain the term.
2. Search results must update automatically after previously unloaded item data arrives; no Lua errors or freezes.
3. Account Crafting includes known recipes from previously captured characters.
4. Character Crafting excludes recipes learned only by another character and uses only current-character professions.
5. Switching scope rebuilds Crafts, Materials and Economics without stale data.
6. Missing account evidence remains Unknown; it must never become a false Not learnable state.
7. Economics columns stay within the middle panel, do not overlap, and allocate remaining width to Item.
8. All six tabs, item selection, filters, history, price calculations and tooltips remain functional.
9. No Lua errors, taint, blocked actions or visible overlap.

**Exit status:** SOURCE IMPLEMENTED; OFFLINE CHECKS PASS; FOREVER RUNTIME NOT RUN. Do not claim Forever verified until the user accepts it in-game.
