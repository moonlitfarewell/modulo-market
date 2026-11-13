# WoW Forever build 1.60.1.70938 compatibility review — ModuloMarket 0.8.5

**Review date:** 2026-11-13  
**Baseline:** ModuloMarket 0.8.4, 157-file bundle  
**Target:** WoW Forever 1.60.1 build 70938  
**Previous target/data build:** 1.60.1.70888  
**Scope:** client/API observation, auction snapshot provenance and recovery diagnostics. No visual redesign, market-calculation change or data-catalogue refresh.

## 1. Player problem and observable result

The user's 0.8.4 in-game screenshot reports Forever client build 70938 while the saved Full Market auction snapshot was captured on build 70888. ModuloMarket correctly withholds craft profitability when the saved snapshot build does not exactly match the running client. The player needs a clear recovery instruction and a read-only diagnostic that distinguishes client/API availability, saved auction snapshot provenance and bundled recipe-catalogue provenance.

Observable 0.8.5 result:
- `/mmcompat` opens a read-only compatibility report.
- The report shows the client version/build/date/interface, the actual `lastMarketSnapshot` provenance and exact compatibility-gate result, the bundled ForeverDB catalogue build/status, and the presence/absence of relevant Auction House, item-data and tooltip API functions.
- The market status explicitly instructs the player to open the Auction House, choose **Update Full Market**, confirm, and wait for a complete scan.
- A mismatched or unknown snapshot remains ineligible for craft profitability. The old complete snapshot is retained until a replacement scan completes.

## 2. Evidence and counter-evidence

### User-supplied Forever evidence

The 2026-11-13 screenshot shows ModuloMarket 0.8.4 rendering its All Items interface on Forever 1.60.1 build 70938. The title, header, tabs, left filters, table, inspector and status line are visible. This is **FOREVER OBSERVED** for the displayed All Items screen on 70938. It does not prove every tab, every control, scan operation, API behavior or the 0.8.5 diagnostic.

The screenshot's status explicitly identifies the saved auction snapshot as 70888 and the client as 70938. This is consistent with the saved snapshot build gate, not evidence that the gate itself is defective.

### External build research (third-party build-diff sources; not Blizzard API documentation)

- WoW Forever's 2026-11-13 build report compares 1.60.1.70938 with 1.60.1.70888 and reports 9 added spell rows, 43 changed spell rows, no added/removed item rows, and 2 changed item rows. It reports no zone/map/race/class record changes. Source: https://wow-forever.gg/news/2026-11-13-build-1-60-1-70938-report/
- The companion build announcement describes the update as 8 new spells and 42 changed spells. Source: https://wow-forever.gg/news/2026-11-13-build-70938-is-out/
- AHledger's item diff reports the two changed item records as Glimmering Mithril Insignia changing Armor type Mail to Miscellaneous, and Recipe: Elixir of Greater Firepower being renamed Recipe: Elixir of Holy Power. It also reports 20 removed item records, including recipe/consumable/trade-good records. Source: https://ahledger.com/wow-forever/changes/WOW-70938patch1.60.1_Retail
- ForeverDB's homepage, checked 2026-11-13, still identifies its current extracted client data as build 1.60.1.70888 (updated Nov 11). Source: https://foreverdb.net/

These third-party data comparisons are evidence about game data records, not a complete diff of the addon's runtime API, templates or frame behavior. No source found in this review documents a 70938 addon API removal/change affecting the ModuloMarket calls.

### Competing explanations

A. A client API/template change caused ModuloMarket behavior to fail.  
B. The client/UI continues to load, but the old 70888 auction snapshot is correctly rejected on 70938.

The screenshot supports UI loading and shows the exact snapshot/client mismatch. The build diff is primarily spell and item-data changes; it does not report an addon API change. B is currently better supported. The `/mmcompat` report distinguishes API function presence and snapshot/catalogue provenance. It does not by itself prove API behavior. A complete Full Market scan on 70938 is the runtime diagnostic for the remaining auction API/behavior question.

## 3. Current implementation and change

### Existing implementation preserved

- `Scanner.lua` and `Replicate.lua` stamp completed snapshots with `GetBuildInfo()` version, build and interface.
- `ProfessionData.IsMarketSnapshotCompatible()` requires a known snapshot version/build to match the running client.
- `MarketUI.lua` withholds recipe economics when the saved Full Market snapshot is not compatible.
- `ProfessionData.lua` loads the bundled ForeverDB catalogue as a provenance-preserving baseline when the client differs; it does not relabel the catalogue as current.
- `Replicate.Finish()` commits only a complete snapshot to `MM.db.lastMarketSnapshot`; incomplete scans retain the prior complete snapshot.

### 0.8.5 changes

1. Added a read-only `MM.Diagnostics.BuildReport("COMPAT")` report section:
   - guarded `GetBuildInfo()` version/build/date/interface;
   - actual `MM.db.lastMarketSnapshot` source, schema, version/build, timestamp, item variants, auction count, processed count and completion flags;
   - the existing `IsMarketSnapshotCompatible()` result;
   - bundled ForeverDB provider build, current build, availability, baseline/match state, review count and status;
   - presence checks for the Auction House Replicate/Browse functions, C_Item metadata functions and C_TooltipInfo item-tooltip function.
2. Added `/mmcompat`, which opens the existing diagnostics window with the compatibility report selected. The report sends no auction requests and performs no scans or mutations.
3. Improved the All Items status text to explain the recovery path when the Full Market snapshot is missing or mismatched.
4. Bumped child addon and bundle version to 0.8.5. Parent MODULO remains unchanged.

## 4. Data and compatibility disposition

- The bundled ForeverDB catalogue remains `1.60.1.70888`, its actual source provenance. ForeverDB's public homepage still reports 70888 as its current extracted client build on the review date.
- 70938's item diff includes a reclassification and a recipe-scroll rename, plus removed records. The prior Full Market snapshot therefore remains stale for the new client and is not promoted to current.
- No guessed 70938 dataset is included. No recipe IDs, source claims, item mappings, prices or calculations are changed.
- No compatibility exception/allow-list was added. No build mismatch is silently accepted.
- Craft profitability becomes eligible again only after a new complete Full Market snapshot is captured on the running client build and passes the existing exact-build check.

## 5. Ownership, dependencies and non-goals

- Owner: standalone optional ModuloMarket addon; diagnostics in `Diagnostics.lua`, command registration in `Core.lua`, status copy in `MarketUI.lua`.
- Parent MODULO remains 1.0.48 and unchanged. MODULO does not gain a dependency on ModuloMarket.
- No new dependencies, external assets, protected actions, scan requests, SavedVariables schema changes or automatic scans.
- No visual redesign, market engine changes, pricing logic changes, recipe catalogue updates, item mapping changes, or changes to scanner/Replicate acquisition behavior.

## 6. Risks and remaining gaps

- API function presence is not proof that a function returns the expected values or behaves correctly in the current client.
- The user's 70938 screenshot proves the All Items window rendered, but does not prove that `ReplicateItems`, response events, auction item-data resolution, full-scan completion or persistence work on 70938.
- The `/mmcompat` report itself has not yet been exercised by the user on Forever.
- ForeverDB recipe data is a 70888 baseline, not a 70938-verified catalogue. The current provider does not expose a verified 70938 dataset in the evidence reviewed.
- No source-supported reason was found to weaken the exact snapshot gate.

## 7. Tests and runtime evidence

Offline tests and package verification are recorded in the release handoff and final audit summary. The compatibility harness uses mocked APIs and a 70888 snapshot on a 70938 client; it verifies reporting and fail-closed diagnostics only. It does not simulate or prove Forever runtime behavior.

### Required Forever acceptance

1. Install 0.8.5 on Forever 1.60.1 build 70938.
2. Run `/mmcompat`; verify it reports client build 70938, interface, actual saved Full Market snapshot build 70888, compatibility `false`, and ForeverDB catalogue build 70888 as a baseline.
3. Verify the listed Auction House, C_Item and C_TooltipInfo functions report their actual runtime types.
4. Open the Auction House. In ModuloMarket choose **Update Full Market**, confirm the full scan, and allow it to finish.
5. Reopen `/mmcompat`. Verify the saved snapshot now records 70938 and the exact compatibility result is `true`.
6. Reopen Market. Verify craft profitability is available only after the complete 70938 snapshot was committed.
7. If the scan errors, APIs are missing, or the snapshot remains 70888, capture `/mmcompat` output and the Lua error. Keep the issue open; do not bypass the gate.
8. Check that the 0.8.4 graphical appearance remains unchanged.

**FOREVER RUNTIME:** `/mmcompat` NOT RUN; 70938 Full Market rescan NOT RUN; craft-profitability recovery NOT RUN. The user screenshot is **FOREVER OBSERVED** for the 0.8.4 All Items screen only.


## 2026-11-13 catalogue reconciliation addendum (ModuloMarket 0.8.6)
The complete 2026-11-13 ForeverDB capture for client build 1.60.1.70938 is now normalized and validated. It contains 2,493 recipes across all 12 professions; per-profession captured totals match reported totals and no pagination shape is unknown. Compared with 70888, recipe additions/removals/changed records are all zero. The bundled catalogue provenance advances to 70938; this does not change the independent Full Market snapshot gate. See `FOREVERDB-DATA-REVIEW-2026-11-13.md`. Runtime acceptance remains NOT RUN.
