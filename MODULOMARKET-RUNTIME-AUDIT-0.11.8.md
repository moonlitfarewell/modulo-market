# MODULO MARKET Runtime Audit 0.11.8 — 2026-11-14

## Result

**Confirmed crash cause corrected in source — Modulo Market 0.11.8.**

The newly supplied `WTF.zip` contains a BugGrabber record at `2026-11-14T16:21:53Z`:

```text
Interface/AddOns/ModuloMarket/MarketUI.lua:249:
attempt to call a nil value
```

The captured locals identify `query="spire"`, `includeTooltip=true`, and a valid item table for Mage-Eye Blunderbuss (`itemID=3041`). The stack enters `MatchesSearch` from the incremental view-build path.

## Evidence and diagnosis

### Competing hypotheses

1. **Search helper lexical-scope failure:** `MatchesSearch` calls `GetItemName(item)` before the later `local function GetItemName(item)` declaration. In Lua, the local name is not in scope before its declaration; the earlier reference resolves as a global. No global `GetItemName` is defined, so the call is nil.
2. **Invalid item or missing item metadata:** the current item row is malformed or lacks item data, causing a helper to be absent.

The diagnostic is the saved BugGrabber locals plus source order. The row is a valid table with `itemName`, `itemID`, prices and quantities. The failing source expression is specifically `GetItemName(item)` at line 249; the helper declaration is later at line 324. This distinguishes hypothesis 1. The helper does not depend on the item's item-data cache being populated to exist.

### Why the client could appear frozen

`StepView` advances `build.index` only after the current item has been processed. The nil call throws before that increment. The active incremental build can therefore encounter the same row again on a later update, repeatedly throwing while the search build remains active. This is a credible explanation for the repeated error/UI stall reported by the player; exact client freeze behaviour still requires runtime acceptance.

### Scope and provenance

- Inspected the newly supplied `WTF.zip`; ZIP CRC test passed, 420 entries.
- `WTF/Account/453173582#1/SavedVariables/!BugGrabber.lua` contains 27 error records. The Modulo Market nil-call above is the relevant recorded error.
- `ModuloMarket.lua` SavedVariables are present in this archive. `Enchantresses' Spire` (item ID `287025`) appears in `lastSnapshot` (the Browse snapshot). It does **not** appear in the serialized `lastMarketSnapshot` text, so this archive does not establish that the item was present in the Full Market snapshot used by `/mm` search. This distinction preserves the snapshot-only search boundary.
- GitHub `main` was fetched and is at commit `324b3b220069c93a0bc4660bfd8a0b672d752aa0`, titled `Update to Modulo-Market 0.11.6`. The same `MatchesSearch` / later-local-helper ordering is present in that GitHub source. The bug is therefore a latent source defect present on GitHub main, not proven to have been newly introduced by the 0.11.7 UI slice.
- The uploaded 0.11.7 GitHub-update archive SHA-256 is `ed1a01824a3cd61ba3e2d649e69977497401e4cd1f981f1e7af2cb65aa247c56`; it contains 254 entries and passes ZIP CRC validation.

## Change in 0.11.8

`MarketUI.lua` now forward-declares `local GetItemName` before `MatchesSearch` and assigns the helper later with `GetItemName = function(item)`. The reference in `MatchesSearch` therefore resolves to the intended local function rather than a nil global.

No SavedVariables schema, market snapshot, search boundary, UI ownership, addon dependencies, or other player-facing behaviour was intentionally changed. The 0.11.7 features remain.

## Verification

- Focused 0.11.7 runtime-slice + 0.11.8 lexical-scope regression: **11 passed**.
- Lua syntax across 14 addon Lua files (`texluac -p`): **14/14 PASS**.
- Full historical suite baseline on the unmodified 0.11.7 archive: **359 passed / 87 failed**.
- Full suite after the code/version change: **361 passed / 87 failed**; the **same 87 failure IDs** remain, with **zero new failing IDs**. Two additional regression checks pass.
- Final package: 256 files; exact archive inventory matches `MANIFEST.json`; ZIP CRC/integrity **PASS**.
- Fresh extraction: exact 256-file inventory **PASS**; focused regression **11 passed**; Lua syntax **14/14 PASS**.
- Bundle size: 2,761,735 bytes. SHA-256 is recorded in the handoff accompanying the archive.

## Runtime acceptance and limits

- Forever client runtime retest: **NOT RUN**. Source/static tests do not prove the client no longer stalls.
- Retail runtime: **NOT RUN**.
- Player-visible acceptance remains OPEN until the player installs 0.11.8, opens `/mm`, searches `spire` (or another ordinary text query), and confirms the window remains responsive with no Modulo Market Lua error. Also confirm clearing the query and switching tabs still work.
- No claim is made that the source correction has been runtime verified.
