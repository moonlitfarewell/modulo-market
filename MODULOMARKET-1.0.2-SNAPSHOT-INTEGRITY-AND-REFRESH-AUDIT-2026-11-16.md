# Modulo Market 1.0.2 — Snapshot Integrity Diagnostics and Saved-Snapshot Refresh

**Date:** 2026-11-16  
**Source supplied:** `/mnt/data/modulo-market.zip`  
**Source ZIP SHA-256:** `ef16c73b73112c75021e14475eced47f5dedb6fafe56d628a9940e28055bd327`  
**Git provenance in supplied ZIP:** `f3fc5e562d823bb7ad517a8e10dab01501c27f33` (`Reconcile`, branch `main`, tracking `origin/main`)  
**Latest known upstream main at start:** `0e1267b3804fc713a8dca35681ace5263b0dcce5`, a TOC version-alignment commit. The supplied ZIP predates that one-file commit; this slice carries forward the 1.0.1 alignment and advances release metadata to 1.0.2.  
**Pre-existing local changes preserved:** `data/README.md`, `tests/historical/test_modulomarket_0_11_0_themes.py`, `tests/historical/test_modulomarket_0_11_1_themes.py`.

## Player problem and intended result

The player reported that a Full Market scan completed (`346712` auction records processed, `36403` variants, zero unresolved) and printed the successful snapshot-saved message, but the UI still displayed a snapshot age of approximately 12 hours and an Enchantresses' Spire price matching an older history point. The target diagnostic confirmed five source auction rows and successful item-info loading, but did not expose the actual saved snapshot timestamp or the committed snapshot's target-item price.

The 1.0.2 slice adds evidence to distinguish scan completion, snapshot commit, and UI rebuild. It also adds an explicit **Refresh** action that rebuilds the view from the already-saved snapshot without issuing another auction-house request or bypassing the 15-minute Replicate cooldown.

## Evidence and counter-evidence

### Supplied player evidence

- UI header showed `Full Market data · 12h ago · 346712 auction records`.
- The Replicate diagnostic reported `outcome=complete auctions=346712 processed=346712 variants=36403 unresolved=0`.
- Enchantresses' Spire had five target auction rows; item info was successfully loaded and all five rows aggregated.
- The All Items price matched an older history point while Auctionator's current browse showed a higher starting price.
- The player confirmed seeing `Market snapshot saved: 36403 variants from 346712 auctions ...`.

This establishes a mismatch between successful-scan evidence and the displayed snapshot age. It does not establish whether the saved snapshot timestamp failed to advance, whether the saved snapshot was later overwritten, or whether the open UI retained a stale catalogue.

### Source inspection

- `Replicate.lua` constructs `snapshot.timestamp` at successful Finish, appends a history point, assigns `MM.db.lastMarketSnapshot`, updates `lastMarketScanAt`, and calls `OnMarketSnapshotCommitted(snapshot)`.
- `MarketUI.lua:GetSnapshot()` selects the complete Full Market snapshot ahead of the narrower Browse snapshot.
- `MarketUI.lua:UpdateMetadata()` derives the displayed age directly from the selected snapshot's `timestamp`.
- `MarketUI.lua:RenderHistory()` reads `marketHistory` independently. The All Items price is sourced from the Full Market catalogue, not directly from the history panel.
- The pre-change `/mmreplicatedebug` record exposed source-row acquisition details but not the committed snapshot timestamp, previous snapshot timestamp, commit identity, or target-item prices from the saved snapshot.

The source path intends to stamp and commit a new snapshot, but no live SavedVariables dump was supplied to establish what was actually persisted in the player's client.

## Competing hypotheses retained

1. **Snapshot commit/persistence mismatch:** the acquisition completes but the currently saved snapshot is old, or a later load/overwrite restores old state. Distinguishing evidence: compare `completedAt`, `snapshotTimestamp`, `previousSnapshotTimestamp`, and `commitConfirmed` in the new diagnostics.
2. **UI/catalogue stale after commit:** the saved snapshot advances but the open view still represents an earlier catalogue. Distinguishing evidence: `Refresh` rebuilds the UI from the exact saved snapshot; compare the metadata age and target price before and after.
3. **Acquired snapshot contains the old target price:** the saved snapshot timestamp is current but its target item rows contain the older minimum. Distinguishing evidence: inspect `snapshotMinPriceCopper`, per-variant `snapshotRows`, quantities, and auction counts from the newly committed snapshot.

No hypothesis is declared proven by offline tests.

## Implemented in this slice

### Scan and snapshot integrity evidence

- The persisted targeted Replicate diagnostic now records scan start, completion, snapshot timestamp/text, previous snapshot timestamp, committed snapshot auction counts, processed counts, and whether the exact new snapshot is still `MM.db.lastMarketSnapshot` after assignment.
- For Enchantresses' Spire (item ID `287025`), it records the number of matching snapshot variants, minimum unit price in copper, total quantity, auction count, and per-variant price/depth details.
- Successful diagnostics are saved after the new snapshot has been assigned to SavedVariables.
- Aborts record `commitConfirmed=false` and the preserved last-known-good snapshot timestamp. Aborts before the initial Replicate response also produce a durable outcome record.
- `/mmreplicatedebug` prints scan outcome/times, exact saved snapshot time/counts, prior snapshot time, and target-item saved snapshot price/depth.
- Both presentations show the most recent scan outcome and local completion time beside the scan state (`OK HH:MM` or `Failed HH:MM`). The saved snapshot age remains a separate value.

### Saved-snapshot Refresh action

- Blizz-like presentation: replaces the adjacent `Close` button with `Refresh`; the window title-bar close behaviour remains available.
- Modern presentation: adds `Refresh` beside `Scan Market`; the title-bar X remains the window close action.
- Refresh invalidates and rebuilds the local catalogue from `GetSnapshot()` / the already-saved complete snapshot.
- Refresh does not call `Replicate.Prepare`, `Replicate.Confirm`, `C_AuctionHouse.ReplicateItems`, or alter cooldown state.
- Cancel is repositioned to avoid overlap with Refresh while retaining its active-scan role.

### Version alignment

- TOC and runtime version metadata: `1.0.2`.
- `MANIFEST.json` version: `1.0.2`.
- Turn-in data's embedded version marker: `1.0.2`.

## Ownership and scope

This is Modulo Market's own snapshot acquisition, diagnostics, and presentation workflow. It does not alter Auctionator, Blizzard auction-house APIs, or any other specialist addon. No optional addon dependency is introduced. The scan safety gate, one-request-per-session rule, cooldown, complete-snapshot-only persistence, and last-known-good preservation remain in place.

## Tests and verification

- Focused Python tests: **59 passed** across the new integrity tests, snapshot/commit/cancel/performance regression tests, and manifest/projection checks.
- Full Python suite: **220 passed, 22 failed**. Compared with a clean `git archive HEAD` baseline (**198 passed, 37 failed**), there are **zero new failing test IDs**; 15 baseline failures now pass after current-version assertions and manifest inventory checks were reconciled.
- Lua syntax: **14/14 addon Lua files passed** with `texlua` loadfile parsing.
- Replicate scan-flow harness: **13 checks passed**.
- Modern UI visual harness: **35 checks passed**.
- The legacy market-engine harness still fails its pre-existing UI-refresh assertion on both this source and the clean baseline; it is not counted as a new regression.
- Forever 1.60.1 build 70938 runtime acceptance: **NOT RUN** — requires player installation and live client testing. Static source tests and mocked harnesses are not Forever runtime acceptance.

## Known limitations / open defect

The historical 12-hour-vs-successful-scan discrepancy is **not yet resolved**. This slice instruments the next scan so the exact saved timestamp and Enchantresses' Spire price can be inspected. If the new diagnostic says `commitConfirmed=true` and the timestamp is current but the displayed price remains old, inspect the target snapshot rows for their actual minimum price. If the snapshot timestamp is current but the UI age is old until Refresh, that demonstrates a stale presentation path. If commit is false or the timestamp remains old, investigate persistence/commit lifecycle before changing price aggregation.

The Refresh action is a local rebuild, not a fresh auction-house scan. It must not be described as recollecting live auction data.

## Acceptance / exit criteria

1. Install the 1.0.2 slice on Forever 1.60.1 build 70938.
2. Run a player-confirmed Full Market scan and verify the successful completion message.
3. Run `/mmreplicatedebug`; verify `outcome=complete`, `commitConfirmed=true`, the new snapshot timestamp is close to completion time, and snapshot auction/processed counts match.
4. Verify the target snapshot minimum price and per-variant rows against the actual captured listings and Auctionator's contemporaneous browse (allowing for listing churn between captures).
5. Verify the UI age updates from the newly committed snapshot. If it does not, click Refresh and observe whether the catalogue/price changes.
6. Verify Refresh does not initiate a new Replicate request or change the cooldown.
7. Verify the Refresh action and Cancel positioning in both Blizz-like and Modern presentations.

Until those player-visible checks pass, the data-integrity defect remains OPEN and Forever runtime status remains **NOT RUN**.

## Handoff

This is a source patch slice under `modulo-market/`, not a complete install bundle. The user reviews, merges, commits, and pushes locally. No remote repository was edited by ChatGPT.
