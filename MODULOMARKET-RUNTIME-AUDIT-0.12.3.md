# Modulo Market Runtime Audit 0.12.3

## Purpose
Diagnostic-only acquisition slice for the confirmed Auction House target Enchantresses' Spire (item ID 287025). The user reports that the item is visibly listed in the Auction House but does not appear in the Full Market snapshot/search.

## Source findings
- Full Market acquisition is performed by `C_AuctionHouse.ReplicateItems()`, not by ForeverDB.
- `GetReplicateItemInfo(index)` supplies the item ID from tuple field 17 and `hasAllInfo` from field 18 in the current implementation.
- `GetReplicateItemLink(index)` supplies the hyperlink parsed into an item key.
- Records needing item data are queued, requested, retried, then aggregated.
- The snapshot is replaced only after a complete scan with zero unresolved/invalid records.
- Therefore the item can be absent because the replication response omitted it, the item ID/link was not returned or parsed, item data retry failed, or aggregation did not occur.

## Changes in 0.12.3
- Track item ID 287025 through the Replicate record, link parse, item-data queue/request/result/retry, and aggregation stages.
- Persist a bounded sample (maximum 30 matching auction records) in `ModuloMarketDB.lastReplicateTargetDiagnostics` on completion or abort.
- Add `/mmreplicatedebug` to print the last saved diagnostic record. It is read-only and does not issue another Replicate request.
- No change to auction acquisition decisions, item parsing, retry policy, snapshot completeness rules, or SavedVariables market snapshot schema.

## Diagnostic interpretation
- `records=0`: the Replicate response supplied no records whose tuple item ID was 287025. This points upstream of Modulo Market aggregation; it does not prove the Auction House UI and Replicate endpoint expose identical data.
- `records>0`, no link / parse error: inspect captured link and parse error.
- `queued>0`, load failure or retry failure: item metadata acquisition prevented aggregation.
- `records>0` and `aggregated>0`: the item entered the new snapshot; investigate item-key variants or UI/search indexing instead.
- `records>0`, `aggregated=0` without load failure: inspect the captured per-auction fields and processing outcome.

## Runtime procedure
1. Install 0.12.3 over the previous version without deleting SavedVariables.
2. Respect the existing shared 15-minute Replicate cooldown and one-attempt-per-session guard. Do not repeatedly press Scan.
3. Keep the Auction House open, clear the Sell tab, and run one full Market scan.
4. After completion or abort, run `/mmreplicatedebug` and provide the chat output plus a fresh WTF/SavedVariables export.
5. If the scan completes, `/reload` normally so the diagnostic SavedVariable is flushed. A hard crash may prevent the final save; the chat output is therefore also useful.

## Validation and limitations
- Focused diagnostic tests: 3 passed.
- Full suite on untouched 0.12.2 baseline: 380 passed / 87 failed.
- Full suite on 0.12.3: 383 passed / 87 failed; same 87 failing test IDs, zero new failures.
- Lua syntax: 14/14 addon Lua files passed `texluac -p`.
- ZIP CRC and manifest inventory: PASS, 266/266 files.
- No live Forever Replicate endpoint has been exercised by this development pass.
- Retail runtime: NOT RUN. Forever runtime: NOT RUN.
- This release does not claim to fix missing auction acquisition; it is a diagnostic slice.
