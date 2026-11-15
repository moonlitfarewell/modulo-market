# Modulo Market Runtime Audit 0.12.5 — Release Hardening

## Status

**IN PROGRESS — source/offline validation only.** This audit records the current 0.12.5 hardening work. It is not a 1.0.0 approval and does not claim Forever client acceptance.

## Player problem and observable result

A newer Browse snapshot could eclipse a complete Full Market snapshot because `GetSnapshot()` previously selected by timestamp. Browse is a narrower capture and must not replace the complete market catalogue. After a successful Full Market commit, the correct snapshot must drive both presentations; aborted/incomplete scans must leave the last-known-good market data untouched.

## Evidence and decision

- 0.12.4 audit documents the post-commit refresh hand-off and deferred refresh behavior.
- 0.12.4 left timestamp-based selection unresolved; its audit explicitly records that a newer Browse snapshot could be selected.
- The README and capability design distinguish Full Market from narrower Browse capture.
- **Decision for 0.12.5:** a complete `lastMarketSnapshot` always wins. `lastSnapshot` is used only when no complete Full Market snapshot exists. Timestamps do not override source authority.

## Changes

- `MarketUI.GetSnapshot()` now prefers a complete `lastMarketSnapshot` regardless of timestamp.
- A complete Browse snapshot is a fallback only when Full Market is missing or incomplete.
- Neither incomplete source is selected.
- The commit hand-off still validates that the supplied snapshot is complete and is the exact committed `MM.db.lastMarketSnapshot` table.
- Open Blizz-like and Modern presentations receive an immediate refresh; closed presentation work is deferred.
- The expanded Lua harness exercises the real `UI.Refresh()` path for Blizz-like open, Modern open, both closed with a backend, and first open after deferred refresh. It verifies the catalogue build consumes the committed Full Market rows rather than newer Browse rows.
- The same harness loads `Replicate.lua`, sends a confirmed scan into the empty-initial-response abort path, and verifies that the prior Full Market snapshot remains untouched and the commit callback is never called.
- Aborted/uncommitted/incomplete commit payloads are rejected by the hand-off.
- No SavedVariables schema, acquisition policy, scan frequency, price calculation or optional dependency changes.

## Regression-suite disposition

The captured untouched 0.12.4 baseline log in the supplied audit workspace records 388 passed / 87 failed. Those failures came from milestone-era tests asserting pre-0.10 source layouts, exact historical versions, old tab structures and old widget placement. The 65 pre-0.10 test modules are retained under `tests/historical/` and excluded from the current pytest gate. Two ForeverDB importer tests remain active. The 12 0.10–0.12 tests that had stale 0.12.4 version assertions were updated to assert 0.12.5 metadata.

This is a test-suite scope cleanup, not deletion of the historical evidence. If a pre-0.10 behavior remains a 1.0 requirement, it must be ported into a current behavior-oriented test against the 0.12.x implementation.

## Validation so far

- Current active pytest suite: **136 passed**.
- Focused 0.12.1–0.12.5 acquisition, snapshot, scroll, rarity and compatibility checks: **19 passed** (includes the expanded 0.12.5 Lua behavior harness).
- Lua syntax: **14/14 addon Lua files passed** `texluac -p`.
- Candidate ZIP: ZIP CRC PASS (`testzip() == None`); 276 files plus one root directory entry (277 ZIP entries).
- Fresh extraction: exact manifest inventory **276/276**; active pytest suite **136 passed**; Lua syntax **14/14 passed**.
- Candidate SHA-256 is supplied in the delivery handoff.
- Public GitHub `main`: checked read-only on 15 November 2026; TOC and Core.lua both report 0.12.5; scoped LICENSE and THIRD-PARTY-NOTICES.md exist. README and runtime audit still contained stale pre-push statements claiming 0.12.4/no remote update/no licence. No remote writes performed. Full remote-tree/archive equivalence NOT ESTABLISHED.
- Forever runtime: **PARTIAL OBSERVATION** — user screenshot confirms a closed-window Full Market refresh on Forever 1.60.1, with the new complete snapshot displayed after reopening. Open-window refresh, aborted-scan preservation, alternate presentation and complete tab/feature acceptance remain **NOT RUN**.
- Retail runtime: **NOT RUN**.

## Provenance and documentation findings

- Active canonical ForeverDB dataset is build `1.60.1.70938`; its review records 2,493 recipes across 12 professions and zero recipe-record differences from 70888. The runtime Lua metadata also reports 70938.
- The old 0.12.1 Spire note described the 14 November snapshot only. The later 0.12.3 diagnostic records Enchantresses' Spire, item ID 287025, with 18 records aggregated, and player screenshots showed it searchable. The historical statement is retained but explicitly superseded in the current README.
- `MANIFEST.json` currently points to parent MODULO 1.0.48 with SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.
- Child bundle lineage requires reconciliation: the inherited `supersedesChildBundle` points to 0.11.5 even though a verified 0.12.4 source bundle is supplied. The final manifest must point to 0.12.4 and preserve the known intervening bundle hashes.
- A scoped MIT `LICENSE` and `THIRD-PARTY-NOTICES.md` are present in the candidate and live main. The MIT grant is limited to original source code. ForeverDB rules support visible attribution and bundling but are not a general open-data licence. Six UI textures have no author/licence metadata; CMaNGOS-labelled records have unresolved provenance/rights. See `MODULOMARKET-PROVENANCE-AUDIT-2026-11-15.md`.

## Remaining work and acceptance criteria

1. Expand current behavioral coverage for Full Market/Browse precedence and post-commit refresh across both presentations, visible/hidden states, and abort paths.
2. Reconcile manifest child-bundle lineage and rebuild exact file inventory after all documentation/test changes.
3. Finish README, installation/upgrade, scope and known-limitations documentation.
4. Verify source/data licensing and redistribution permission. Do not invent or select a licence without the owner's decision and adequate upstream permission.
5. Build a fresh 0.12.5 source ZIP; verify ZIP integrity, manifest, TOC/Core/data version agreement, fresh extraction, syntax, focused/full tests and SHA-256.
6. Synchronize stale README/audit statements on GitHub and compare the complete remote tree/file hashes to the finalized release. No remote writes performed in this pass.
7. Run structured Forever acceptance: acquisition, persistence, both windows, every tab, search, crafting, history, turn-ins, post-scan refresh open/closed, aborted scan and error-free operation.

**Exit:** 0.12.5 is not complete until the offline/package gates pass and unresolved licence/remote/runtime gates are either resolved or explicitly accepted as blockers. 1.0.0 remains a separate release decision.


## Reconciliation note — 15 November 2026

The manifest `supersedesChildBytes` field was inconsistent with its own SHA and `previousChildBundles` entry. The verified 0.12.4 archive is 2,805,520 bytes with SHA-256 `9bc8c51d2b2cda5fa407f978798da0a60052cddda57b0452f9d0742bc303fb53`; the candidate manifest has been corrected to that byte count. The six local TGA textures were inspected as 64×64 RGBA glyphs; appearance does not prove authorship or licence.
