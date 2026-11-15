# Modulo Market 0.12.5 — release hardening (in progress)

**Current source milestone:** a complete Full Market snapshot is now authoritative over Browse snapshots, even when Browse has a newer timestamp. Browse is used only as a fallback when no complete Full Market snapshot exists. A completed Replicate scan still hands its exact committed snapshot to the presentation refresh path; closed presentations defer catalogue work until the next explicit open. Aborted/incomplete scans cannot replace the last-known-good Full Market snapshot or trigger the commit refresh. This is source/offline-tested; Forever client acceptance is NOT RUN. See `MODULOMARKET-RUNTIME-AUDIT-0.12.5.md`.

**0.12.5 release status:** release hardening remains in progress. The root `LICENSE` applies MIT terms only to original Modulo Market source code, to the extent contributors have the rights to license it; it expressly excludes third-party code, datasets, assets and trademarks. See `THIRD-PARTY-NOTICES.md` for known provenance and unresolved rights. Current active regression gate: 136 passed. Pre-0.10 milestone-era source-shape tests are retained under `tests/historical/` and excluded from the current gate because they assert superseded layouts and implementation details. The public GitHub `main` branch remains at 0.12.4; no remote update has been made. Distribution licensing and Forever runtime acceptance remain unresolved release gates.

## 1.0 scope and known limitations

Modulo Market is an Auction House snapshot and profession-information companion. Full Market auction prices and depth come only from a completed client Replicate snapshot; ForeverDB supplies profession/catalogue metadata, not live auction prices. Browse captures are narrower and never supersede a complete Full Market snapshot. Craft economics fails closed when the saved Full Market snapshot is incompatible with the running client build or does not contain sufficient price depth.

Known limitations for the 1.0 candidate:
- Forever runtime acceptance of the current 0.12.5 build is NOT RUN.
- Public redistribution rights for the bundled ForeverDB-derived canonical/runtime data have not yet been independently confirmed. Attribution is present; attribution alone is not treated as a data redistribution licence.
- A scoped MIT `LICENSE` has been added for original project source code only. Third-party datasets, assets and dependencies are excluded; see `THIRD-PARTY-NOTICES.md`. Texture provenance and the precise status of CMaNGOS-derived facts remain UNKNOWN and block an unrestricted distribution claim.
- The public GitHub `main` branch is still 0.12.4 and does not yet match this 0.12.5 working source.
- Fishing commodity valuation, disenchant expected-value calculations and skill-progression opportunity ranking are outside the current 1.0 scope unless separately accepted and implemented.

## Installation and upgrade

1. Install the required MODULO addon first.
2. Copy the `AddOns/ModuloMarket` folder into the same WoW Forever client `Interface/AddOns` directory as MODULO.
3. Enable Modulo Market in the AddOns list and log in. The addon declares MODULO as required and LibProfessionDB as optional.
4. For upgrades, exit the client or reload the UI before replacing the addon folder. Replace only `AddOns/ModuloMarket`; do not delete `WTF` or `ModuloMarketDB` SavedVariables. Existing market snapshots, history and window settings are intended to persist across upgrades.
5. After upgrading, verify the addon version in `/mmversion` and confirm the expected presentation opens before performing a Full Market scan.

The 0.12.4 post-scan refresh implementation remains documented in `MODULOMARKET-RUNTIME-AUDIT-0.12.4.md`.

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
