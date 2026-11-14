# Modulo Market 0.11.9 Runtime Regression Audit

Date: 2026-11-14

## Scope and player problem

Player-visible defect: opening `/mm` with a large saved market snapshot (approximately 6,317 aggregated items in the supplied screenshot) can make the WoW process stop responding. The 0.11.8 build still hangs after the list populates. This is a hard UI-thread hang reported by Windows, not merely a slow render.

This is a separate optional child addon, Modulo Market. No parent MODULO source is used as an implementation baseline.

## Evidence inspected

- `ModuloMarket-GitHub-Update-0.11.6.zip` (251 entries; ZIP CRC PASS).
- `ModuloMarket-GitHub-Update-0.11.7.zip` (254 entries; ZIP CRC PASS).
- `ModuloMarket-GitHub-Update-0.11.8.zip` (256 entries; ZIP CRC PASS).
- User screenshots showing (1) empty list with `Sorting...` and `Loading selection...`, and (2) populated list with 6,317 items immediately before Windows reports the game not responding.
- Previously supplied WTF BugGrabber record: `MarketUI.lua:249`, query `spire`, item `Mage-Eye Blunderbuss` (itemID 3041), captured at 2026-11-14 16:21:53 UTC. This was addressed separately by the 0.11.8 lexical-scope fix. It does not explain an empty-query startup hang by itself.

## Source comparison: 0.11.6 to 0.11.7

The highest-risk new runtime path is in `MarketUI.lua`:

1. 0.11.7 added `RequestItemQuality()` and calls `C_Item.RequestLoadItemDataByID()` from `GetItemQualityHex()`, which is called by row rendering.
2. 0.11.7 added item-quality request/cache invalidation to the item-data completion handler.
3. The same handler unconditionally called `UI.RenderRows()` and `MM.ModernUI.RenderRows()`, potentially doing redundant work in both presentations for one event.
4. 0.11.7 added `Modern.UpdateColumnLayout()` and invokes it from `Modern.RenderRows()`. This is a secondary amplification candidate because each render now measures visible cell text and repositions columns.

The tooltip warm-up and structured-tooltip search path pre-existed in 0.11.6; it is not treated as a newly introduced 0.11.7 feature. Search work is unlikely to explain the launch hang when the search field is empty. Centering and Shift-click are interaction/positioning paths and are lower-probability causes. Artisan reward changes are static data.

## Competing hypotheses and distinguishing diagnostic

- H1 (primary): render-triggered item-data requests and their completion events cause repeated/redundant row rendering, with Modern layout measurement amplifying the event workload.
- H2 (secondary): Modern dynamic column measurement or another existing catalogue/view/selection operation is independently monopolising the UI thread after population.

The diagnostic discriminator is a controlled build that removes rarity-triggered item-data requests and avoids rendering the inactive presentation while leaving the rest of the 0.11.7 feature set intact. If the hard hang persists, H1 is weakened and the next isolation target is Modern dynamic column measurement and then the catalogue/view/inspector stages.

## 0.11.9 implementation

- Removed `RequestItemQuality()`, `itemQualityRequested`, and `itemQualityFailed`.
- `GetItemQualityHex()` now reads `GetItemInfo()` opportunistically and returns neutral white when the client has no cached quality. It does not initiate item-data requests from a render path.
- The item-data completion handler still invalidates relevant caches and preserves existing vendor-price/item-class refresh behaviour.
- The completion handler now refreshes only the active presentation: Modern when the selected theme is Modern; otherwise Blizz-like.
- Retained the 0.11.8 `GetItemName` forward-declaration fix and all other 0.11.7 features, including centering, dynamic Modern columns, Shift-click dispatch, inspector headings, search progress and the supplied Artisan reward schedule.
- No SavedVariables schema change and no addon dependency change.

## Static validation results

- Focused 0.11.7/0.11.8/0.11.9 regression tests: 15 passed.
- Full historical Python suite: 365 passed / 87 failed. The untouched 0.11.8 baseline produced 361 passed / the exact same 87 failing test IDs. No new failing test IDs; four additional tests now pass.
- Lua syntax: 14/14 addon Lua files passed `texluac -p`.
- Forever and Retail runtime acceptance remain NOT RUN.

## Acceptance and limitations

- Player-visible acceptance: NOT RUN. The user's next `/mm` launch test is required.
- Forever runtime: NOT RUN pending user retest on the target client.
- Retail runtime: NOT RUN.
- Static tests and Lua syntax do not establish that the game hang is fixed.
- Rarity-colour limitation is intentional: items whose quality is not already cached remain neutral white until another client/addon operation loads them. Modulo Market no longer fetches item data solely for this cosmetic purpose.
- If the hang persists, do not assume H1 is confirmed. Instrument/disable Modern dynamic column measurement next, then isolate catalogue, sorting, first selection and inspector work. Keep the defect open until player-visible acceptance passes.

## Acceptance sequence

1. Preserve existing SavedVariables and install 0.11.9 over 0.11.8.
2. Open `/mm` with the same market snapshot and no search text.
3. Confirm the window populates and remains responsive for at least 30 seconds.
4. Switch tabs and scroll.
5. Test a text search (including `spire`) and clearing the search.
6. Confirm available item-quality colours still appear for cached items; uncached items may remain white.
7. Report whether the hard freeze recurs and which presentation/theme was active.

## NOT RUN / UNKNOWN

- No Forever or Retail runtime test was performed during this source change.
- It is not yet known whether the removed request/event workload was the sole cause.
- It is not yet known whether the remaining dynamic column layout or catalogue/inspector processing causes an independent hang.
