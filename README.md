# Modulo Market 0.12.12 — settings and minimap refinements

**Current source milestone:** 0.12.11 refines the native Blizzard Settings presentation; 0.12.9 completed the repository and release-package reconciliation for commit `803bdf73042236ce741e9bedf8ae6c2df0a621aa`. The filtered 1.60.1.70938 projection retains non-speculative recipe structures, outputs and reagent quantities labelled `FOREVER_CLIENT`, plus acquisition rows labelled `FOREVER_OBSERVED` or `FOREVER_CLIENT`; it excludes speculative recipes and the specified Classic-borrowed/unknown acquisition and comparison material. The three unfiltered canonical snapshots have been deleted from public `main` by commit `671df73`. The complete projection rules and before/after counts are in `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

The closed-window and open-window Full Market refresh paths remain FOREVER OBSERVED PASS on Forever 1.60.1; explicit cancellation remains FOREVER OBSERVED PASS in both presentations. See `MODULOMARKET-RUNTIME-AUDIT-0.12.8.md` for the exact inherited evidence scopes. No new player runtime test was needed for this data-only projection.

**0.12.9 reconciliation status: CLOSED/PASS.** The post-push local Git tree export at the GitHub-confirmed `main` head contains 379 entries (366 blobs, 13 directory entries). The repository verifier checked all 293 release-manifest paths against the tree with zero hash mismatches after CRLF-to-LF normalization of a temporary copy of the Windows ZIP extraction; the ZIP itself was not modified. All 73 repository-only files are classified (72 tests and one superseded audit), and no raw canonical snapshots remain. See `MODULOMARKET-REPOSITORY-RECONCILIATION-0.12.9.md` and `MODULOMARKET-RUNTIME-AUDIT-0.12.9.md`. The root `LICENSE` applies MIT terms only to original Modulo Market source code and the six project-authored UI assets listed in `ASSET-PROVENANCE.md`, to the extent contributors have the rights to license them. The retained ForeverDB-derived projection is not MIT-licensed. ForeverDB's published developer instructions describe fetching and bundling data with releases, visible attribution and no API keys; they are not a general open-data licence or a blanket Blizzard rights grant. The projection removes explicitly Classic-borrowed and unknown records/fields, but retained Forever-client/player-observed material remains third-party/provider-derived and its broader rights are not independently cleared. See `THIRD-PARTY-NOTICES.md`. Current active regression gate and package verification are recorded in `MODULOMARKET-RUNTIME-AUDIT-0.12.8.md`. The 0.12.8 archive was clean, but the public GitHub `main` tree at parent commit `c34bb314084f4308ecb0ff9d420473e4ab7a2995` still exposed the three unfiltered canonical snapshots outside the 290-file release manifest. The 0.12.9 cleanup removed those paths from public `main`; the post-push verifier now confirms the 293-file 0.12.9 package and complete 379-entry tree agree, with repository-only history separately classified. Historical tests and the superseded 0.7.9 audit remain repository-only artifacts. Runtime evidence remains scoped and is not upgraded to FOREVER VERIFIED.

## 0.12.9 — repository and distribution reconciliation

The 0.12.8 archive's 290-file release manifest was internally exact and excluded all three unfiltered canonical snapshots. The public Git tree nevertheless exposed those 44,409,368 bytes as three additional blobs. The 0.12.9 cleanup removed those paths from public `main`. The completed 0.12.9 reconciliation verifies all 293 release-manifest paths against the 379-entry tree, classifies 73 repository-only historical files (72 tests and one superseded audit), and confirms no forbidden snapshots remain. The package manifest and repository tree are deliberately separate inventories. See `MODULOMARKET-REPOSITORY-RECONCILIATION-0.12.9.md` and `MODULOMARKET-RUNTIME-AUDIT-0.12.9.md`.

## 0.12.8 — conservative data distribution projection

The active 70938 distribution payload is now derived from a field-level projection. It retains 2,350 non-speculative Forever-client recipe structures and 4,166 acquisition rows (4,133 Forever-observed and 33 Forever-client). It removes 2,289 Classic-borrowed and 3,867 unknown acquisition rows from retained recipes, 143 speculative recipes, 93 non-observed trainer entities, Classic trainer locations/prices, Classic comparison metadata and skill thresholds without Forever-client evidence. The old unfiltered 70862/70888/70938 canonical files are not shipped in the 0.12.8 release ZIP and were removed from the public Git repository by the 0.12.9 cleanup. A reproducible sanitizer and strict tests are included. This reduces mixed-provenance distribution risk but does not grant rights over retained Blizzard/ForeverDB-derived data. See `MODULOMARKET-DATA-CLEANUP-0.12.8.md`.

## 0.12.7 — UI asset provenance and acceptance reconciliation

The six undocumented UI TGA glyphs are replaced with project-authored 64×64 assets rendered from included SVG masters. The source geometry and deterministic Pillow renderer are included, and `ASSET-PROVENANCE.md` records the asset-to-source mapping and licence scope. The root MIT notice now explicitly includes these original project-authored UI assets while continuing to exclude third-party datasets and material. The runtime acceptance record is reconciled with the user's Forever 1.60.1 screenshots: open- and closed-window refresh and explicit cancellation in both presentations are FOREVER OBSERVED PASS for those exact scopes. Broader runtime evidence remains scoped and is not upgraded to FOREVER VERIFIED.

## 0.12.6 — active Replicate cancellation

After the player confirms a Full Market Replicate scan, the Cancel control remains visible in both Blizz-like and Modern presentations. Cancel now aborts the active in-memory transaction, removes its event/update handlers, preserves the last-known-good Full Market snapshot, and does not invoke the successful commit/refresh hand-off. The one-shot request and 15-minute cooldown remain consumed. Offline state-machine and UI harness coverage is included; the active suite passes 139 tests and all 14 addon Lua files pass syntax validation. Forever runtime acceptance is NOT RUN; see `MODULOMARKET-RUNTIME-AUDIT-0.12.6.md`.

## 1.0 scope and known limitations

Modulo Market is an Auction House snapshot and profession-information companion. Full Market auction prices and depth come only from a completed client Replicate snapshot; ForeverDB supplies profession/catalogue metadata, not live auction prices. Browse captures are narrower and never supersede a complete Full Market snapshot. Craft economics fails closed when the saved Full Market snapshot is incompatible with the running client build or does not contain sufficient price depth.

Known limitations for the 1.0 candidate:
- Forever runtime evidence is partial and specific: closed-window Full Market refresh PASS; open-window Full Market refresh PASS; explicit Replicate cancellation PASS in Modern and Blizz-like presentations on Forever 1.60.1. These are FOREVER OBSERVED results for those exact scopes, not a claim that every tab or feature has been runtime-tested. Following the project acceptance-by-exception policy, unreported capabilities remain accepted operationally unless a defect or contradictory evidence is raised; they are not relabelled FOREVER VERIFIED.
- The 0.12.8 data projection excludes explicitly Classic-borrowed and unknown acquisition records/fields and speculative recipes. It retains Forever-client recipe structures and Forever-observed/client facts under the provider's published fetch-and-bundle developer workflow with visible attribution and no API key. That workflow is not a general open-data licence or a blanket Blizzard rights grant; retained data remains third-party/provider-derived and is not MIT-licensed. No unrestricted redistribution claim is made.
- A scoped MIT `LICENSE` applies only to original project source code and the six project-authored UI assets listed in `ASSET-PROVENANCE.md`, to the extent contributors hold those rights. Third-party datasets, assets and dependencies are excluded; see `THIRD-PARTY-NOTICES.md` and `MODULOMARKET-PROVENANCE-AUDIT-2026-11-15.md`. The six 0.12.6 UI textures had no embedded authorship/licence metadata; 0.12.7 replaces them with project-authored glyphs and editable SVG masters, documented in `ASSET-PROVENANCE.md`. Some provider records are explicitly labelled Classic/CMaNGOS and not confirmed in Forever; their exact source/licence chain is unresolved. These block an unrestricted distribution claim.
- The 0.12.8 release ZIP was clean, but its public Git repository tree contained three unfiltered canonical snapshots outside the package manifest. 0.12.9 removes those repository blobs. The completed 0.12.9 audit confirms the full Git-tree/package reconciliation and distinguishes package inventory from repository-only historical tests/audits.
- Fishing commodity valuation, disenchant expected-value calculations and skill-progression opportunity ranking are outside the current 1.0 scope unless separately accepted and implemented.

## Installation and upgrade

1. Install the required MODULO addon first.
2. Copy the `AddOns/ModuloMarket` folder into the same WoW Forever client `Interface/AddOns` directory as MODULO.
3. Enable Modulo Market in the AddOns list and log in. The addon declares MODULO as required and LibProfessionDB as optional.
4. For upgrades, exit the client or reload the UI before replacing the addon folder. Replace only `AddOns/ModuloMarket`; do not delete `WTF` or `ModuloMarketDB` SavedVariables. Existing market snapshots, history and window settings are intended to persist across upgrades.
5. After upgrading, verify the addon version in `/mmversion` and confirm the expected presentation opens before performing a Full Market scan.

0.12.6 adds a player-facing Cancel control that remains visible after confirmation while a Replicate scan is active. Cancelling stops the in-memory transaction, unregisters its events, leaves the last-known-good Full Market snapshot untouched, and does not call the commit/refresh hand-off. The confirmed one-shot attempt and cooldown remain consumed. The implementation is accepted by offline tests and FOREVER OBSERVED runtime tests in both presentations; see `MODULOMARKET-RUNTIME-AUDIT-0.12.7.md` for the player evidence.

# Modulo Market 0.12.2

**Current player milestone:** 0.12.2 fixes stale virtual-list scroll offsets when a new search result set replaces the previous one. The visible row range is clamped to the current result count, the scroll position is reset when results finish building, and delayed scroll events cannot leave a short result set positioned beyond its final row. This addresses the Forever screenshot showing `99-2 / 2` with an empty result pane despite two matches and an inspector selection. No search matching, tooltip loading, rarity lookup, market data acquisition or SavedVariables behavior is changed. See `MODULOMARKET-RUNTIME-AUDIT-0.12.2.md`.

**0.12.1 search and rarity milestone:** separates ordinary catalogue search from deep tooltip search. Typing uses a 500 ms trailing debounce and searches item names, IDs, recipes, professions and variant names without initiating tooltip warm-up; pressing Enter explicitly starts the deeper tooltip-description pass. Search-name recovery now reads display names embedded in auction item hyperlinks and uses a local GetItemInfo compatibility path that falls back to `C_Item.GetItemInfo` when the global is absent, following ProfessionMaster's compatibility approach. Item rarity uses the same passive `GetItemInfo` plus `ITEM_QUALITY_COLORS` pattern as ProfessionMaster, with a neutral fallback when quality is not cached. Modulo Market does not request item data solely to colour rows. The supplied saved Full Market snapshot does not contain the literal name `Empresses' Spire`; item ID and whether the item was present during the saved scan remain unconfirmed. See `MODULOMARKET-RUNTIME-AUDIT-0.12.1.md`. This was the evidence state for that 14 November capture only; the later 0.12.3 diagnostic and player screenshots record Enchantresses' Spire (item ID 287025) in a completed Full Market snapshot, with 18 records aggregated. See `MODULOMARKET-RUNTIME-AUDIT-0.12.3.md`.

**0.11.9 stability milestone:** retains the 0.11.8 search lexical-scope fix and replaces 0.11.7's render-triggered asynchronous item-rarity loading with passive cached lookup. Item quality is coloured only when `GetItemInfo()` already exposes it; unavailable quality remains neutral white. Item-data completion events may refresh the active presentation, but the addon no longer requests item data merely to colour a row and no longer redraws both UI presentations for one event. Modern dynamic columns, centering, Shift-click dispatch, inspector headings and the Artisan reward schedule are retained. This is a diagnostic regression-isolation release; it does not yet establish that the hard hang is fixed.

Artisan Waylaid Crate rewards use the supplied category schedule: raw-material Artisan crates (Herbs, Ore, Textiles, Curiosities) return 20 Merchant's Favor and 10 Silver; processed-material Artisan crates (Fabrics, Ingots, Parts) return 40 Merchant's Favor and 20 Silver. This is 50 copper per Favor. Reputation remains unfilled because the supplied schedule did not specify a reputation amount.

The three-snapshot Market History, learning-state edge markers, native hover tooltips, pricing, scanner and SavedVariables structures remain preserved. See `MODULOMARKET-RUNTIME-AUDIT-0.11.7.md`. Forever runtime acceptance is **NOT RUN**; Retail runtime is **NOT RUN**.

## Preserved capabilities

- The existing Blizz-like and separate Modern windows remain selectable and use the same market data, pricing, calculations, scanning pipeline and SavedVariables.
- Both windows remain movable beyond the visible client viewport with saved positions and reset controls.
- Writ buy/craft routes, 150-entry catalogue, unknown-reward handling, variable Coin Pouch treatment and fail-closed market-depth rules remain.
- The 0.11.3 Scan Market → Confirm Scan → Cancel workflow and settings-based Browse Scan diagnostics remain.
- No optional addon dependency was added.


## 0.11.8 — search nil-call crash fix

The 0.11.7 search filter called `GetItemName` from `MatchesSearch` before the later `local function GetItemName` declaration entered lexical scope. Lua therefore treated the earlier reference as a global lookup. A non-empty text query such as `spire` raised `attempt to call a nil value` during incremental filtering. `GetItemName` is now forward-declared before `MatchesSearch` and assigned later into that local. The saved profile's BugGrabber stack and locals directly match this call path. No SavedVariables schema or search boundary changed. Offline regression coverage asserts the local binding order; Forever runtime acceptance remains NOT RUN.

## 0.11.7 — centered windows, native links, Modern column fit and Artisan payouts

Both windows center on each explicit `/mm` open. Visible item rows request missing item quality asynchronously and rerender on item-data completion. Shift-click now calls Blizzard's `ChatFrameUtil.InsertLink` dispatcher first, allowing the client to choose active chat hyperlink insertion or native Auction House name search. Modern numeric columns measure their current headers and visible values and align right across All Items, Economics, Crafts, Materials, Turn-Ins and History. Search reads `GetItemInfo` without a separate cache-probe gate and shows filtering/description warm-up progress. The Modern inner inspector card is titled `Selected Item`. Artisan Favor/cash use the supplied raw/processed category schedule. See `docs/MODULOMARKET-0.11.7-UX-AND-SEARCH.md`.

## 0.11.6 — item status, quality, history and inspection

Restored learning-state row markers on Crafts and Turn-Ins, applied client item-quality colours to every tab, changed history to three latest snapshots, restored native hover tooltips, corrected Shift-click to use native chat link insertion or native Auction House Browse fill, improved snapshot name fallback, and aligned the Blizz-like inspector card/title with Modern. Artisan Waylaid Crate payouts remain explicitly UNKNOWN because current public sources do not confirm them. See `docs/MODULOMARKET-ITEM-STATUS-QUALITY-HISTORY-INSPECTOR-0.11.6.md`.

## 0.11.4 — movable windows and Craftsman's Writs

Introduced movable/persisted windows, settings scroll containment, visible checkboxes, normalized inspector values, Artisan UNKNOWN correction and the Writ catalogue. See `docs/MODULOMARKET-WINDOWS-AND-WRITS-0.11.4.md`.

## 0.11.3 — scan and Modern controls

Unified scan controls, custom Modern TGA icons, search field, profession dropdown default, three-day history and Browse Scan settings launcher. See `docs/MODULOMARKET-SCAN-AND-MODERN-CONTROLS-0.11.3.md`.

## 0.11.1 — separate Modern window foundation

Introduced the independent Modern window while preserving the existing Blizz-like appearance. See `docs/MODULOMARKET-SEPARATE-MODERN-WINDOW-0.11.1.md`.

## 0.11.0 — historical theme foundation

Introduced the first settings page and retained colour treatments now under the Blizz-like window. See `docs/MODULOMARKET-THEMES-0.11.0.md`.


## 0.12.1 — search staging and ProfessionMaster-compatible item information

Typing now waits 500 ms after the last text change, then runs ordinary name/ID/recipe/profession/variant matching only. Pressing Enter explicitly opts into the existing deeper tooltip-description search. New search generations continue to invalidate obsolete filter builds and warm-up state. Search can recover a missing `itemName` from the auction hyperlink display name, including variant links. A local GetItemInfo compatibility helper calls the global when present and otherwise falls back to `C_Item.GetItemInfo`, following ProfessionMaster's LibMasterAddons compatibility contract. Rarity uses `ITEM_QUALITY_COLORS[quality].hex` when cached item info is available, with the existing quality-colour function as a fallback; it does not request item data from row rendering.

The supplied 14 November 2026 SavedVariables snapshot contains 29,351 market variants from 268,656 processed auctions and 6,317 grouped item IDs, but no `Empresses' Spire` name in either saved snapshot. The snapshot is complete for the records returned by `C_AuctionHouse.ReplicateItems`; that does not prove that a listing seen at another time was included in that response. An item hyperlink/item ID and a fresh scan at the time the listing is visible are needed to distinguish acquisition coverage from name/indexing failure. This describes that historical capture only; the later 0.12.3 diagnostic and player screenshots record Enchantresses' Spire (item ID 287025) with 18 records aggregated.

## 0.12.1 — item rarity colour markup correction

Fixed a malformed WoW colour escape in the shared item-name formatter. The quality helper previously returned six RGB digits for cached qualities but eight alpha+RGB digits for its neutral fallback, while the formatter prepended only `|c`. WoW requires eight digits after `|c`, so the malformed escape could consume the first two characters of an item name and display literal fragments or incorrect colours. All quality paths now normalize to eight alpha+RGB digits; unknown quality remains neutral, and no rarity-triggered item-data requests were reintroduced. See `MODULOMARKET-RUNTIME-AUDIT-0.12.1.md`.

## 0.11.9 — passive rarity lookup and active-view refresh

Removed render-triggered `C_Item.RequestLoadItemDataByID` calls for rarity colours. Quality is read opportunistically from the existing client item cache, with neutral white when unavailable. Item-data completion refreshes only the currently selected presentation. This targets the most suspicious new 0.11.7 event/render workload while preserving the requested visual feature wherever cached data exists. See `MODULOMARKET-RUNTIME-AUDIT-0.11.9.md`.


## 0.12.4 — post-scan snapshot auto-refresh

A completed Full Market Replicate scan now hands the exact committed snapshot to `MarketUI.OnMarketSnapshotCommitted`. An open Blizz-like or Modern presentation refreshes immediately; when the market is closed, refresh is deferred until the next `/mm` open so the addon does not build a large catalogue invisibly. Modern explicitly consumes deferred refreshes even if its transparent backend frame was already shown. Replacing a snapshot invalidates the Modern view revision and clears stale rendered rows while the incremental catalogue rebuild runs. No scan is initiated automatically, no auction data is synthesized, and no SavedVariables schema changes. See `MODULOMARKET-RUNTIME-AUDIT-0.12.4.md`. Forever runtime acceptance remains NOT RUN.

## 0.12.6 active Replicate cancellation

The Cancel control remains visible while a Replicate scan is awaiting confirmation or actively processing. Active cancellation stops addon-side processing and preserves the last-known-good Full Market snapshot; the already-sent client request cannot be retracted and the one-shot cooldown remains consumed. See `MODULOMARKET-RUNTIME-AUDIT-0.12.6.md`. Forever runtime acceptance of this new control is NOT RUN.


## 0.12.11 — Native settings appearance refinement

The Modulo Market settings category continues to use Blizzard's vertical Settings
layout, matching the native Settings approach used by Modulo ItemSlot 0.6.1.
The master **Market appearance** selector controls the two child selectors:
**Blizz-like style** and **Modern style**. Each child is parented to the master
initializer so Blizzard's Settings UI disables it when its window is not selected.
Each custom-colour action is in turn parented to its corresponding style selector
and is enabled only when that selector is set to **Custom colour**.

The visible labels and button text have been shortened to avoid clipping in the
Settings pane. Existing SavedVariables, colour-picker persistence/cancel behavior,
market data, scanner, Replicate and profession calculations are unchanged.

Source checks: seven focused Python tests passed; the native Settings Lua harness
passed 20 checks; all 14 addon Lua files passed syntax compilation. These checks
do not establish Forever or Retail in-client appearance/runtime acceptance.


## 0.12.12 — Diagnostic label and minimap settings shortcut

The Advanced tools action label is shortened to **Diagnostic window**. The
Modulo Market minimap launcher now accepts both left and right clicks:
left-click retains its existing open/toggle behavior; right-click opens the
Modulo Market native AddOn Settings category. The tooltip documents both
actions. Right-click is guarded during combat and reports clearly if the
settings category is not yet available. Drag-to-reposition behavior is unchanged.

Source checks: nine focused Python tests passed; the native settings harness
passed 20 checks; all addon Lua files pass syntax compilation. These checks do
not prove the live minimap button interaction or settings navigation on Forever.
