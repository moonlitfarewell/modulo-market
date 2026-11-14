# MODULOMARKET-RUNTIME-AUDIT-0.11.6

**Release:** Modulo Market 0.11.6  
**Audit date:** 2026-11-14  
**Scope:** shared Blizz-like / Modern presentation, row status and rarity, three-snapshot market history, item search and Shift-click, native tooltips, inspector layout, Turn-In header.  
**Source baseline:** `ModuloMarket-GitHub-Update-0.11.5.zip`  
**Source baseline SHA-256:** `1bb4568df5fc8424773df36256e534922b0edeae9aa2dfd227181a8543c4b023`  
**Parent MODULO source metadata:** `MODULO-Project-Source-1.0.48.zip`, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da` (parent source not modified).

## 1. Player problem and observable result

The player reported:
- Blizz-like learning-state row markers worked in All Items, Economics and Materials, but not Crafts or Turn-Ins; Modern had the same Crafts gap.
- Item names should use WoW item rarity colours, independently of learning-state markers.
- Some Artisan Waylaid Crate reward values still displayed UNKNOWN.
- Turn-In column header should read `REP / FAV` and align with its numeric values.
- History should retain three snapshots rather than a 72-hour window with up to four snapshots.
- Shift-click should follow native WoW item-link behaviour and support chat, not only fill an AH search box.
- Row hover must show the actual item tooltip, not an explanatory Shift-click tooltip.
- Snapshot search missed a name that was visible in Auctionator Shopping.
- Both inspectors should be named `Inspected Item`, with a bordered item card in Blizz-like matching Modern.

## 2. Implementation

### Learning-state markers and item quality

- Both presentations now render the existing 3-pixel row-edge status marker on every tab, including Crafts and Turn-Ins.
- Craft rows use the shared normalized `GetCraftSourceStatus` result. Other rows use the existing item-level profession status aggregation; Writ rows prefer their linked crafted output ID. Crates without profession status remain neutral.
- Item names use the client's item quality (`GetItemInfo` / `GetItemQualityColor`) in every tab. Learning state is no longer represented by the Crafts row-name font colour; it remains on the row edge.
- Missing client quality data safely falls back to white; no rarity is guessed.

### Market History

- Removed the wall-clock 72-hour filter.
- `Replicate.SaveHistoryPoint` now retains the latest three completed full-market snapshots.
- `MarketUI.RenderHistory` reads only the last three saved snapshot records, so older SavedVariables are displayed consistently even before another scan trims them.
- Blizz-like and Modern allocate three graph bars/labels.
- The period represented is the elapsed time between the latest three completed scans; no fixed time window is claimed.

### Native tooltip and Shift-click

- Modern and Blizz-like now share the native item/recipe tooltip function on row hover.
- Removed the custom "Shift-click to fill the Auction House search field" tooltip line.
- Shift-click first checks for an active WoW chat edit box and uses `ChatEdit_InsertLink` with the real item hyperlink. If chat is not active, and the native Auction House is open, it fills `BrowseName` with the plain uncoloured item name, focuses/highlights the field, and does not auto-submit.
- No global chat-link hook or chat interception is installed.
- If client item cache data is not yet available, the chat path constructs a standard item hyperlink from the item ID and plain item name.

### Snapshot search coverage

- The saved snapshot catalogue is still the search boundary; the code does not initiate an implicit live Auction House query.
- If the snapshot row's `itemName` is absent, name matching now falls back to the client-cached `GetItemInfo` name. If it is not cached, the existing bounded asynchronous tooltip warm-up continues to resolve searchable tooltip text.
- This should address snapshot rows whose name field was absent but whose item ID is known to the client.
- **Unresolved evidence gap:** the user's screenshot shows an Auctionator Shopping result but no SavedVariables export or item ID. We cannot prove that the exact item was present in the saved full-market snapshot. If the item ID is absent from `snapshot.rows`, a snapshot-only search cannot display it. Reproduction must compare the item ID from the Auctionator result with the saved snapshot. This remains a runtime/data-coverage acceptance check, not a claimed fix.

### Inspector and Turn-Ins

- Blizz-like now has a bordered Inspected Item card above Market Information, matching the Modern inspector's item-card hierarchy.
- Both presentations use `INSPECTED ITEM` for the inspector and item card title.
- Turn-In column title is `REP / FAV`; existing numeric-column alignment remains right-aligned.
- Turn-In values and calculations are unchanged.

### Artisan Waylaid Crate reward evidence

The eight Artisan crate entries in `TurnInData.lua` still have `rewardFavor=nil`, `rewardCashCopper=nil` and no reputation value. This is deliberate UNKNOWN, not a defect that can safely be filled from the current sources.

Public Forever references checked on 2026-11-14:
- Wowhead Forever Durotar guide: known Apprentice/Journeyman crate rewards are listed, with the full list still forthcoming: https://www.wowhead.com/forever/guide/durotar-supply-and-logistics-reputation-professions
- Wowhead Forever Azeroth Commerce Authority guide: known Apprentice/Journeyman rewards are listed; no confirmed Artisan payout: https://www.wowhead.com/forever/guide/azeroth-commerce-authority-reputation-professions
- 60.tools Merchant's Favor guide explicitly lists Expert/Artisan rewards as unknown: https://www.60.tools/guides/merchants-favor
- ForeverSpec guide also marks Artisan Favor unconfirmed: https://foreverspec.com/quests/waylaid-crates/

No Expert value, green-quality multiplier, player-level guess or inferred payout has been copied onto Artisan records. A quest-completion screenshot, authoritative quest/reward record or updated Forever source is needed before this data can be changed.

## 3. Ownership, dependencies and scope

- Owner: standalone Modulo Market addon.
- Parent MODULO remains unchanged.
- No optional addon dependency added.
- No SavedVariables schema change.
- Full Market snapshot capture, pricing, market depth, recipe data, Writ reward provenance, bundle pricing and fail-closed behaviour are unchanged.
- Search remains snapshot-backed. A live AH search integration was intentionally not added because it would change data source semantics and could disrupt Auction House state.

## 4. Before/after evidence and counter-evidence

- Source inspection confirmed the row-marker omissions were presentation branches, not missing status data.
- Source inspection confirmed Crafts name text was using learning-state colour while other tabs used item-quality colour; the two signals are now separated.
- Source inspection confirmed the old search helper used a coloured display string for `BrowseName` and did not call `ChatEdit_InsertLink`; the new path uses a hyperlink for chat and plain text for Browse.
- Source inspection confirmed the prior history implementation used a 72-hour cutoff and four points; both retention and display now use three snapshot records.
- The user's screenshot footer visibly reports `ModuloMarket v0.11.4 · Client 1.60.1 build 70938`. It is useful defect evidence, but it is not acceptance evidence for 0.11.5 or 0.11.6. Confirm the installed build with `/mmversion` before runtime testing.

## 5. Validation results

### Focused tests

- 0.11.6 current-slice tests plus 0.11.4 regression tests: **27 passed**.
- All 14 addon Lua files compiled with `texluac -p`: **14/14 passed**.
- Turn-In/Writ harness: **11 Writ checks + explicit crate-type check passed**; 145/150 exact recipe coverage verified against embedded `ForeverDBData.lua`.
- Waylaid crate harness: **8 checks passed**, including unknown Artisan rewards, one-of bundle alternatives, pricing depth and missing AH price fail-closed behaviour.
- Modern UI harness: **29 checks passed**, including Crafts row-edge marker visibility.
- Scan state-machine harness: **8 checks passed**.
- Existing custom TGA inventory: **6/6 valid RGBA 64×64 TGA files**.

### Full regression suite

- Baseline 0.11.5: **345 passed / 87 failed / 432 total**.
- 0.11.6: **350 passed / 87 failed / 437 total**.
- The same **87 failing test IDs** remain; **zero new failing IDs** were introduced. Five new 0.11.6 tests pass.
- The 87 failures are pre-existing historical suite failures, not runtime acceptance evidence.

### Runtime evidence

- Forever runtime: **NOT RUN**.
- Retail runtime: **NOT RUN**.
- No in-game acceptance is claimed for row layout, quality colours, item tooltips, chat link insertion, Auction House Browse fill, history rendering, or the `Spire` search.
- GitHub push: **NOT RUN**. The previous remote write attempt was blocked with HTTP 403; this release is supplied as a complete local bundle.

## 6. Acceptance and exit criteria

0.11.6 source/offline acceptance is complete. The slice remains open for target-client runtime acceptance until the player confirms:

1. Markers and rarity colours on all six tabs in both presentations.
2. Three history points/bars after three scans, with no fourth point from old SavedVariables.
3. Native item/spell tooltip on hover.
4. Shift-click into active chat inserts a proper item hyperlink; with no active chat and native AH open, Browse receives the plain item name without auto-search.
5. The `Spire` query returns the expected item if its ID is in the saved snapshot; otherwise the missing snapshot row is diagnosed separately.
6. Artisan rewards remain UNKNOWN until authoritative evidence is supplied.
7. Both inspector layouts and REP / FAV header alignment.

**Exit status:** source implementation and offline validation complete; Forever and Retail runtime acceptance remain NOT RUN; the specific `Spire` snapshot-membership question remains UNKNOWN.
