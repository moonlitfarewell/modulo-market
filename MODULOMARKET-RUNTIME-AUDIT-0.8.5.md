# ModuloMarket Runtime Audit 0.8.5 — WoW Forever 70938 compatibility diagnostics

**Release:** ModuloMarket 0.8.5  
**Parent baseline:** ModuloMarket 0.8.4, supplied `ModuloMarket-GitHub-Update-0.8.4.zip`, 157 files  
**Parent archive SHA-256:** `a3587c8429dc12996627e516bb9df09c6a7f9722159d81e0b927a48c78e4a76f`  
**Parent ZIP integrity:** PASS  
**Target client:** WoW Forever 1.60.1 build 70938 (2026-11-13)  
**Prior client / saved snapshot:** 1.60.1 build 70888  
**Parent MODULO:** 1.0.48; unchanged  
**Scope:** build/API availability and saved market snapshot compatibility diagnostics. Visual redesign and market calculations are explicitly out of scope.

## 1. Player problem and observable result

The user's 0.8.4 screenshot shows the All Items window rendering on Forever build 70938 while the Full Market auction snapshot is still stamped 70888. ModuloMarket's exact-build guard correctly withholds craft profitability from a mismatched snapshot. The player needs a precise recovery instruction and a safe way to distinguish:
- the running client build/interface;
- the actual saved Full Market snapshot build and its compatibility result;
- the bundled ForeverDB recipe-catalogue build/status;
- the presence of APIs used by the existing Auction House, item-data and tooltip paths.

The 0.8.5 observable result is `/mmcompat`, a read-only compatibility report, plus a clear instruction to create a new Full Market snapshot on the current client.

## 2. Source of truth and evidence available

### Canonical child source

- Baseline archive: `ModuloMarket-GitHub-Update-0.8.4.zip`.
- Archive CRC verified before extraction; 157 entries.
- Baseline SHA-256: `a3587c8429dc12996627e516bb9df09c6a7f9722159d81e0b927a48c78e4a76f`.
- 0.8.4 manifest, README, TOC, Core, ProfessionData, MarketUI, Scanner, Replicate, Diagnostics and 0.8.4 audit inspected from the supplied archive.
- GitHub `moonlitfarewell/modulo-market` default branch `main` was independently fetched at implementation start and confirmed at 0.8.4. Git blob SHA-1 values match the clean supplied 0.8.4 extraction for `MANIFEST.json` (`ae303a00568cbb31a1915a98589f2917e52b6f3e`), `README.md` (`c2af35e6911fdf90f4a88472f704d801a5bb2b47`), `Core.lua` (`ea2ae080c15c73039831c5a8a0328ef16501a136`), `Diagnostics.lua` (`dc1c7abf5f12ffb8018c738a09fe82d61a38e6f6`), `MarketUI.lua` (`7d4e17b8a24a81e1ecd0d2705dfff6f82686874d`) and `ModuloMarket.toc` (`b66459fe0bf47ea966cf8236b188d5029f06e1d2`). The 0.8.5 slice is therefore based on the exact GitHub 0.8.4 mainline source, not a reconstructed or older release.
- Child baseline was 0.8.4; no 0.6.8 source used.
- Parent MODULO 1.0.48 bundle is available and its Forever compatibility contract/changes and architecture/workflow records were consulted. No parent source file is changed.
- This child repository does not contain separate child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA or SOURCE-REVIEW-LEDGER records; missing child history was not reconstructed.

### User runtime evidence

The user supplied a 2026-11-13 in-game screenshot with footer `ModuloMarket v0.8.4 · Client 1.60.1 build 70938`. It visibly shows the All Items window, header, six tabs, left filters, table, selected-item inspector and status line. This is **FOREVER OBSERVED** evidence that the 0.8.4 All Items screen rendered on build 70938. It is not proof of every control, tab, API call, scan, or the 0.8.5 diagnostics.

The screenshot also shows the Full Market dataset captured on 70888 and the current client on 70938. This matches the existing exact-build safety gate.

### External build research — third-party game-data comparisons, not API documentation

- WoW Forever's detailed 2026-11-13 build report compares 1.60.1.70938 with 1.60.1.70888 and reports 9 added spell rows, 43 changed spell rows, no added/removed item rows, and 2 changed item rows; no zone/map/race/class record changes. URL: `https://wow-forever.gg/news/2026-11-13-build-1-60-1-70938-report/`.
- The companion announcement headline says 8 new spells and 42 changed spells. URL: `https://wow-forever.gg/news/2026-11-13-build-70938-is-out/`. The headline and detailed report counts differ; this audit preserves that discrepancy rather than silently reconciling it.
- AHledger's item diff describes Glimmering Mithril Insignia changing Armor type Mail to Miscellaneous, and Recipe: Elixir of Greater Firepower being renamed Recipe: Elixir of Holy Power. It also reports 20 removed item records, including recipe/consumable/trade-good records. URL: `https://ahledger.com/wow-forever/changes/WOW-70938patch1.60.1_Retail`.
- ForeverDB's public homepage checked on 2026-11-13 still identifies its extracted client dataset as build 1.60.1.70888, updated Nov 11. URL: `https://foreverdb.net/`.

These sources describe game-data records; they are not a complete client addon API/template diff. No reviewed source documents an addon API removal affecting the APIs used by ModuloMarket.

## 3. Player problem diagnosis and competing hypotheses

**Hypothesis A — API incompatibility:** build 70938 changed/removed an API used by ModuloMarket, so a runtime path may fail even though the main frame opens.

**Hypothesis B — stale auction snapshot:** the UI loads, but the saved Full Market snapshot is from 70888 and is intentionally rejected on 70938.

Evidence favors B:
- the user's screenshot visibly shows the 0.8.4 All Items interface rendering on 70938;
- the screenshot identifies the saved Full Market snapshot as 70888 and the client as 70938;
- available 70938 build comparisons focus on spells/items and do not document a ModuloMarket addon API change.

The diagnostic that distinguishes remaining A/B behavior is `/mmcompat` for function availability, followed by a complete Full Market scan on 70938. API function presence is not proof of API behavior. The actual scan/response/persistence path remains to be exercised.

## 4. Existing implementation and accepted behavior preserved

- `Scanner.lua` and `Replicate.lua` stamp completed snapshots with `GetBuildInfo()` version, build and interface.
- `Replicate.Finish()` writes only a complete, fully resolved snapshot to `MM.db.lastMarketSnapshot`. A failed/incomplete scan leaves the previous complete snapshot unchanged.
- `ProfessionData.IsMarketSnapshotCompatible()` requires the saved market snapshot's version/build to match the current client.
- `MarketUI.lua` withholds craft profitability when that exact check fails.
- The bundled ForeverDB recipe catalogue is loaded as a provenance-preserving baseline when the client differs; it is not relabelled current.
- These behaviors are intentionally preserved. No allow-list, fuzzy version comparison, mismatch bypass, guessed dataset, automatic scan or market-calculation exception was introduced.

## 5. 0.8.5 implementation

### `Diagnostics.lua`

- Added `AddCompatibilityReport()` and a `COMPAT` report mode.
- Reports client version/build/date/interface using guarded `GetBuildInfo()`.
- Reads the actual Full Market snapshot from `MM.db.lastMarketSnapshot` (not the separate Browse Scan snapshot).
- Reports source, schema, client version/build, timestamp, result count, auction count, processed count, completion flags and `ProfessionData.IsMarketSnapshotCompatible()` result.
- Reports ForeverDB provider name, catalogue build, current build, match/baseline state, availability, review count and provider status.
- Reports function presence for `C_AuctionHouse` Browse and Replicate APIs, `C_Item` item metadata APIs and `C_TooltipInfo.GetItemByID`.
- States explicitly that API presence is not behavioral verification and that the report sends no requests.
- Added `MM.Diagnostics.ShowCompatibility()` using the existing diagnostics window.

### `Core.lua`

- Bumped addon version to 0.8.5.
- Added `/mmcompat` to open the read-only report.
- Existing `/mm`, `/mmscan`, `/mmdebug`, `/mmsearchdebug`, `/mmtooltipdebug` and `/mmversion` commands remain.

### `MarketUI.lua`

- Kept the exact-build profitability gate unchanged.
- Changed only the stale/missing snapshot status copy to explain: open Auction House, choose Update Full Market, confirm and wait for the full scan to finish.
- Existing complete snapshot remains until a complete replacement is committed.

### Data and UI disposition

- The bundled ForeverDB catalogue remains 1.60.1.70888 because that is the provider build evidenced on 2026-11-13. No unverified 70938 recipe catalogue is fabricated.
- No item/recipe IDs, acquisition sources, item mappings, prices or recipe records are changed.
- No UI layout, visual skin, controls or design work is changed.
- No market economics formula, scanner acquisition algorithm, Replicate behavior or SavedVariables schema is changed.

## 6. Ownership, dependencies, scope and risks

- Owner: standalone optional ModuloMarket child addon. Diagnostics live in `Diagnostics.lua`; command dispatch in `Core.lua`; recovery status in `MarketUI.lua`.
- Parent MODULO 1.0.48 remains unchanged. Parent MODULO does not depend on ModuloMarket.
- No new dependencies, external assets, protected actions, automatic requests, SavedVariables schema changes or addon-to-addon dependency.
- Main risk: the read-only report may show APIs as present while their runtime behavior or event lifecycle is broken. The scan is the required behavior diagnostic.
- Another risk is provider lag: ForeverDB catalogue build remains 70888 and must remain explicitly labelled baseline.
- Scope is intentionally limited to the new client build compatibility check and recovery guidance.

## 7. Verification

### Focused regressions

Command:
`python -m pytest -q tests/test_modulomarket_0_8_5_build_compatibility.py tests/test_modulomarket_0_8_4_visual_redesign.py tests/test_modulomarket_0_8_3_visual_refinement.py tests/test_modulomarket_0_8_2_mockup_alignment.py tests/test_modulomarket_0_8_1_visual_foundation.py tests/test_modulomarket_0_8_0_status_integrity.py tests/test_modulomarket_ui_0_6_4_layout.py tests/test_modulomarket_ui_0_6_3_inspector_footer.py tests/test_modulomarket_ui_0_6_2_runtime_layout.py tests/test_modulomarket_profession_capture_0_7_8.py tests/test_modulomarket_0_7_7_debounced_search_and_sell_launcher.py tests/test_modulomarket_acquisition_compact_0_6_6.py`

Result: **76 passed**.

### Lua syntax

Command: `texluac -p AddOns/ModuloMarket/*.lua`  
Result: **9/9 PASS**.

### Read-only compatibility harness

Command: `texlua tests/build_compatibility_0_8_5_harness.lua`  
Result: **PASS**. It uses a mocked 70938 client, a saved 70888 Full Market snapshot and stub API functions. It verifies report content and fail-closed reporting only; it does not simulate Forever.

### Existing profession capture harness

Command: `texlua tests/profession_capture_0_7_8_harness.lua`  
Result: **PASS**.

### Full historical suite and failure comparison

Command: `python -m pytest -q --tb=no`

- Clean 0.8.4 baseline: **231 passed / 61 failed**.
- 0.8.5 source: **235 passed / 61 failed**.
- Failure-ID comparison: **0 new failing test IDs**; all 61 baseline failures remain unchanged.
- Four new 0.8.5 regression tests pass. Eight existing version-alignment assertions were advanced from 0.8.4 to 0.8.5 so the historical tests validate the current release metadata.

## 8. Final package validation

- Bundle: `ModuloMarket-GitHub-Update-0.8.5.zip`.
- Archive size at final packaging: 1,775,504 bytes.
- ZIP CRC: PASS.
- Exact manifest inventory: 161/161 files; no missing manifest entries or unlisted source files.
- Fresh extraction: PASS; TOC/Core/README/manifest release version 0.8.5.
- Fresh-extraction focused regression suite: **76 passed**.
- Fresh-extraction full historical suite: **235 passed / 61 failed**; all 61 failure IDs match the clean 0.8.4 baseline; zero new failing test IDs.
- Fresh-extraction Lua syntax: **9/9 PASS**.
- Fresh-extraction build compatibility harness: **PASS**.
- Fresh-extraction profession capture harness: **PASS**.

## 9. Forever runtime acceptance — NOT RUN

The following must be completed by the player on actual Forever build 70938:

1. Install 0.8.5 and run `/mmcompat`.
2. Verify client build 70938/interface, saved Full Market snapshot build 70888, compatibility `false`, and ForeverDB catalogue build 70888 labelled baseline.
3. Verify the API function types in the report against the actual client.
4. Open the Auction House. In ModuloMarket choose **Update Full Market**, confirm the full scan and wait for completion.
5. Run `/mmcompat` again. Verify `MM.db.lastMarketSnapshot` now records build 70938, complete status and compatibility `true`.
6. Reopen Market. Confirm craft profitability is enabled only after the new complete snapshot is committed.
7. If an API is missing, a scan fails, the saved build remains 70888, or a Lua error occurs, capture the report and error. Keep the issue open; do not bypass the gate.
8. Confirm the existing 0.8.4 visual appearance is unchanged.

**FOREVER OBSERVED:** 0.8.4 All Items screen rendered on build 70938, based on the user's screenshot.  
**FOREVER NOT RUN:** 0.8.5 `/mmcompat`; API behavior; 70938 Full Market scan; snapshot persistence; profitability recovery.  
**Exit:** source implementation and offline verification complete; actual client compatibility/scan acceptance remains open pending the user's `/mmcompat` report and full scan.
