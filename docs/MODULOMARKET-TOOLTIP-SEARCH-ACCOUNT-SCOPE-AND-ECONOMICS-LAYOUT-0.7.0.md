# ModuloMarket 0.7.0 — tooltip search, crafting scope and Economics layout

## Player problem and observable result

The player needs to find market goods by their actual effects (for example, healing or spell damage), distinguish account planning from the currently logged-in character's real crafting ability, and use the Economics table width more efficiently.

## Implementation

- Search checks existing item/recipe/profession/ID/reagent fields first, then checks cached item tooltip text when the query is not already satisfied. Tooltip data is loaded through the client item cache and refreshed on `ITEM_DATA_LOAD_RESULT` / `GET_ITEM_INFO_RECEIVED`. Search is additive; it does not replace existing matching fields.
- The persistent header selector offers Account Crafting and Character Crafting.
- Character scope reads only the current realm/character recipe store and the native profession list.
- Account scope unions learned recipe records from all saved character stores and merges positive profession observations. A profession absent from a saved character is not treated as absent from that character; unobserved account status remains Unknown. Account scope disables the negative Not learnable filter because absence across every character cannot be proven from partial captures.
- Readable native profession lists are stored per character as positive evidence. Existing saved recipe records are not rewritten.
- Economics table widths are measured from visible headers and row values, clamped to avoid a single long value consuming the table, anchored from the right, and the Item column receives remaining width.

## Ownership and dependencies

ModuloMarket remains a separate optional addon depending on MODULO. MODULO does not depend on ModuloMarket. No ProfessionMaster, Auctionator, LibProfessionDB, ForeverDB or other addon runtime dependency was added. No ForeverDB requests or API credentials are involved.

## Evidence and limitations

- Parent MODULO source bundle 1.0.48 ZIP integrity PASS; parent unchanged.
- Previous ModuloMarket 0.6.9 GitHub update ZIP integrity PASS and used as the source base.
- Current character recipes are stored by `realm:character` under `professionRecipesByCharacter`.
- Account scope can only combine characters that have logged in and contributed profession/recipe evidence to the saved database. It does not know unobserved characters' professions.
- Tooltip search depends on the Forever client's tooltip and item-data APIs. If an item tooltip has not loaded, its item data is requested and the search is rerun when the client reports completion. A tooltip API incompatibility may require a runtime-specific adapter.
- Economics sizing measures the currently visible row pool; it recalculates as rows are rendered/scrolled. This is intentionally bounded rather than scanning every off-screen string each frame.
- No new ForeverDB content or source assertions are created.

## Verification

- Lua syntax: all nine addon Lua files parse with texlua.
- Focused source tests: recorded separately in release handoff.
- Historical test suite contains legacy assertions tied to older versions/layouts; those are not accepted as current regressions without updating the tests.
- Forever runtime: NOT RUN. No user-client testing has yet confirmed tooltip effect search, account/character switch behavior, character snapshot persistence, or column fit.

## Acceptance checklist

1. Search for `healing`, `spell damage`, and a known food effect finds items by tooltip text even when the item name does not contain the term.
2. A not-yet-cached item triggers an item-data request; once loaded, the active search refreshes without a manual reload.
3. Account Crafting combines known recipes from saved characters and treats missing character evidence as Unknown.
4. Character Crafting only shows current-character learned recipes and uses that character's native profession list.
5. Switching scope rebuilds Crafts, Materials and Economics without stale selected rows or stale craft economics.
6. Economics columns remain within the middle panel, fit visible values and headers, and allocate leftover width to Item.
7. Existing market snapshot exact-build gate, acquisition-source evidence and all six tabs remain unchanged.
8. No Lua errors, taint, blocked interactions or visible UI overlap.

**Exit status:** SOURCE IMPLEMENTED; STATIC CHECKS PASS; FOREVER RUNTIME NOT RUN.
