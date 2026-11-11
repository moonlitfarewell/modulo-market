# Modulo Market Runtime Audit 0.0.7 — last-known-good persistent snapshot

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.7  
**Parent:** MODULO 1.0.48 (unchanged)  
**Parent bundle:** unchanged  
**Package:** standalone optional child addon; independent version and release lifecycle.

## Player problem and observable result

The player currently has to export and preserve nine JSON parts to retain a complete Auction House snapshot. A scan is expensive and can take many minutes. The addon should persist the last completed snapshot in its declared `ModuloMarketDB` SavedVariables and restore it after reload/restart, while never losing a known-good snapshot because a later scan was interrupted.

Observable result: `/mm` shows the last completed snapshot after reload; export works without rescanning; a new scan replaces it only after confirmed completion.

## Exact evidence and counter-evidence

### Available source evidence

- Canonical input package supplied in this turn: `ModuloMarket-0.0.6.zip`; ZIP integrity passed before extraction.
- `ModuloMarket.toc` already declares `## SavedVariables: ModuloMarketDB`.
- `Core.lua` initializes `_G.ModuloMarketDB` and assigns `MM.db`.
- 0.0.6 `Scanner.lua` held `Scanner.completedSnapshot` only in memory. Its `Finish()` assigned that field; `Start()` reset only the active scan's working rows.
- 0.6 README explicitly deferred persistence pending a controlled complete scan and Sell-tab safety acceptance.
- User supplied nine export chunks with matching metadata, contiguous ranges and 16,475 rows. This demonstrates a completed export artifact, not the addon persistence lifecycle.
- The 0.0.6 source test explicitly asserted that `MM.db.lastSnapshot` was not written.

### Counter-evidence / limits

- No supplied live test demonstrates SavedVariables write/restore.
- A complete scan screenshot/export does not establish save-on-logout or reload behavior.
- A SavedVariables table assignment is not an immediate durable disk write; the WoW client serializes it during its normal save lifecycle. A crash before flush may lose the latest in-session replacement.
- Sell-tab safety and concurrent Auction House behavior remain unproven on the target client.

## Before/after behavior

**Before:** completed snapshot is session-memory only; export parts must be copied before reload.  
**After (source implementation):** `ModuloMarketDB.lastSnapshot` stores one complete snapshot. `RestoreSavedSnapshot()` restores only a structurally complete record with `resultCount == #rows`. The scan working set remains separate. `Finish()` performs the replacement only after `HasFullBrowseResults()` returns true and snapshot construction completes. `Start()` and `Abort()` do not mutate SavedVariables.

## Ownership and dependencies

- Market owns its own optional addon implementation, SavedVariables and package.
- MODULO core remains unchanged at 1.0.48 and does not depend on Market.
- Auctionator remains independent; no private Auctionator queue/database is accessed.
- No external dependency or new client API was introduced.

## Risks and scope

- A 16,475-row snapshot is approximately 1.48 MB as compact JSON; WoW's Lua SavedVariables representation may be larger. Actual file size, load time, logout serialization time and memory cost require client measurement.
- Only one snapshot is retained; no historical database is created.
- Replacement is last-known-good at the Lua table level, not transactional storage at scan-finish time.
- Snapshot restoration is guarded by completeness and row-count consistency, but deeper per-row schema validation is not performed.
- Existing throttle pacing, page/result/time limits, Sell-tab guard and read-only behavior are unchanged.

## Acceptance / exit criteria

1. Existing complete snapshot remains available while a new scan is running.
2. A successful full scan replaces the previous snapshot exactly once, after the full-results gate.
3. Stop, timeout, browse failure, Auction House close, throttle drop and safety-gate failure preserve the previous saved snapshot.
4. `/reload` restores the last completed snapshot and JSON export works without rescanning.
5. Full client restart restores the snapshot after normal SavedVariables flush.
6. A realistic 16k+ snapshot does not cause unacceptable load/logout stalls or memory use.
7. Normal Auction House browsing and Sell-tab posting still work after scanning.

## Validation

- ZIP integrity: PASS on input 0.0.6; output package checks recorded at handoff.
- Static source tests: run for 0.0.7.
- Lua scanner model harness: NOT RUN if no Lua interpreter is available in the build environment; report exact result.
- Lua syntax check: NOT RUN if no Lua interpreter is available.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN / UNKNOWN.
- SavedVariables serialization size and lifecycle: NOT MEASURED.
- Reload/restart restore: NOT RUN.
- Sell-tab safety and concurrent AH use: NOT RUN.

## Required live runtime test

Use a disposable copy of the existing SavedVariables file or first complete a known-good scan. Start a second scan and verify the saved snapshot remains intact during scanning. Abort it and verify the prior snapshot remains. Then complete a new scan, `/reload`, open `/mm`, verify timestamp/count, and export a part. Finally restart the client normally and verify restoration again. Repeat with a 16k+ row scan and measure login/logout responsiveness. Test Sell-tab behavior separately with no other Auction House activity.

**Status:** source capability implemented; player-visible persistence acceptance remains NOT RUN / UNKNOWN. This audit does not claim runtime verification.
