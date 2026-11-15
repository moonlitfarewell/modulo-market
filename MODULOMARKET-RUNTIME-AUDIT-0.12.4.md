# Modulo Market Runtime Audit 0.12.4

## Purpose
Make a successfully committed Full Market snapshot available to the open Modulo Market presentation immediately, without requiring `/reload` or a game restart.

## Player problem and observable result
A completed Replicate scan had successfully acquired and aggregated Enchantresses' Spire (item ID 287025), but the player only observed it in `/mm` after restarting the game. The runtime evidence does not establish that restart was necessary; it exposed a possible stale in-memory presentation/catalogue lifecycle. The required result is: after a successful scan, an open Market window rebuilds from the newly committed snapshot; if the window is closed, the next open uses that snapshot without a reload.

## Evidence
- 0.12.3 diagnostic output: 315,919 auctions returned and processed; 32,986 variants; zero unresolved; 18 records for item 287025; all 18 aggregated.
- Player screenshots after that scan showed item ID 287025 searchable by both numeric ID and `spire`, with 18 units and market history.
- The 0.12.3 source already called generic `MarketUI.Refresh()` after commit. That path returned immediately if the legacy UI frame had not been created and did not explicitly distinguish an open presentation from a hidden backend. The new slice makes the commit hand-off explicit and defers work when no presentation is open.

## Changes in 0.12.4
- `Replicate.Finish()` now calls `MarketUI.OnMarketSnapshotCommitted(snapshot)` only after the complete snapshot has been assigned to `MM.db.lastMarketSnapshot`. A fallback to the old `Refresh()` remains for compatibility.
- `OnMarketSnapshotCommitted` validates that the supplied snapshot is complete and is the exact committed `lastMarketSnapshot` table.
- When Blizz-like or Modern is open, it refreshes metadata and starts the catalogue rebuild immediately.
- When no presentation is open or no backend frame exists, it records a transient pending-refresh flag; the next UI refresh consumes it. This state is runtime-only and does not change SavedVariables schema.
- `Modern.Show()` explicitly calls `UI.Refresh()` after preparing the backend, covering the case where the transparent backend frame was already shown and therefore does not receive another `OnShow`.
- `StartCatalog()` increments the Modern view revision and clears both renderers immediately, preventing old rows from remaining visible while the new index is built.
- No scan is started automatically; no additional Replicate request is made; no auction data or prices are synthesized.

## Ownership and scope
Modulo Market owns its catalogue refresh and presentation lifecycle. ForeverDB remains a metadata/profession source, not a live auction feed. No optional addon dependency was added.

## Risks and compatibility
- Catalogue construction remains incremental using the existing per-frame processing path.
- If the scan is incomplete or aborted, `OnMarketSnapshotCommitted` is not called and the last-known-good snapshot remains untouched.
- A newer Browse snapshot can still be selected by the existing timestamp-based `GetSnapshot()` policy; this slice does not change source precedence.
- No Forever-specific API assumptions were added.

## Validation
- Focused snapshot-refresh/acquisition tests plus selected Modern UI and manifest harnesses: 11 passed.
- Fresh-extraction snapshot-refresh/acquisition tests: 8 passed.
- Full historical suite: 388 passed / 87 failed; compared with untouched 0.12.3 baseline (383 passed / 87 failed), the same 87 test IDs fail and there are zero new failing IDs. Five additional tests pass.
- Lua syntax: 14/14 addon Lua files passed `texluac -p`.
- ZIP integrity and manifest inventory: PASS, 268/268; fresh-extraction Lua syntax: 14/14 passed.
- Forever runtime: NOT RUN for 0.12.4. The previous player-observed scan and search results are preserved as evidence for 0.12.3 only; this new automatic refresh behavior requires client testing.
- Retail runtime: NOT RUN.
- GitHub remote: not updated.

## Acceptance criteria
1. With `/mm` open during a successful Full Market scan, the current presentation clears stale rows and indexes the new snapshot without restarting the client.
2. With `/mm` closed during a successful scan, the next `/mm` open indexes the committed snapshot without `/reload` or restarting.
3. An aborted/incomplete scan does not replace or refresh from an incomplete snapshot.
4. Both Blizz-like and Modern presentations behave consistently.
