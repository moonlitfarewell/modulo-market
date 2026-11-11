# ModuloMarket Runtime Audit 0.5.1

**Date:** 2026-11-10  
**Addon:** ModuloMarket 0.5.1  
**Parent:** MODULO 1.0.48 — unchanged  
**Previous child:** ModuloMarket 0.5.0  
**Disposition:** source correction and offline acceptance complete; Forever runtime acceptance pending.

## 1. Player problem and observable result

The player supplied screenshots showing:

1. An item they already know how to craft (Savory Deviate Delight) displayed both `[C]` and `[F?]` markers and appeared under unlearned/future recipe detail.
2. Vendor sale detail repeatedly displayed `Item value not cached` for selected items.
3. The All Item Roles dropdown used long, overlapping, specialist terminology that did not explain the differences between known, unlearned, borrowed-source, unknown-source, gathering and reagent classifications.

The intended result is:
- A learned recipe is never represented as the same recipe being future/unlearned.
- Item-level craft states are unambiguous. If an item has a known learned recipe, its item-level state is Known Craft Output. A distinct additional unlearned recipe route may still be visible in All Crafts and in the detail panel, but does not make the item itself a future-only output.
- Selecting an uncached item triggers one bounded item-data request; the detail panel updates when the client supplies item data and distinguishes loading from unavailable data.
- Filter names are short enough to fit the dropdown and option tooltips explain the inclusion rule.

## 2. Canonical source and provenance

### Child baseline
- `ModuloMarket-0.5.0.zip`
- Bytes: 208,917
- SHA-256: `5c4f02a1a6b2cc64fb3b1e8bf292a3a7248e4e36a7c4ba4df3a609ea2283f8d7`
- ZIP integrity: PASS (`ZipFile.testzip()` returned `None`).
- Manifest, TOC and Core agreed on version 0.5.0 before this patch.

### Parent baseline
- `MODULO-Project-Source-1.0.48.zip`
- Bytes: 41,236,015
- SHA-256: `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`
- ZIP integrity: PASS.
- The parent archive hash and byte count agree with the 0.5.0 Market manifest.
- Parent TOC remains 1.0.48. The parent bundle was not changed.
- Parent ownership decision 1.0.48 keeps Market as a separate optional child addon with its own TOC, version, SavedVariables, QA, evidence and ZIP. Market depends on MODULO; MODULO does not depend on Market.

### Relevant project contracts consulted
- `PROJECT-START-HERE.txt`
- `WORKFLOW.txt`
- `PROJECT-DECISIONS.txt`
- `QA.txt`
- `PROJECT-PROGRESS.md`
- `SOURCE-REVIEW-LEDGER.md`
- `FOREVER-COMPATIBILITY-CONTRACT.md`

The parent project records are intentionally not rewritten by this child-only patch.

## 3. Evidence, competing hypotheses and diagnosis

### A. Known recipe also shown as future

**Evidence:** the screenshot shows `[C]` and `[F?]` on the same item, while its detail shows both a known crafting relationship and a borrowed-source unlearned candidate.

**Source finding:** `ProfessionData.lua` inserted each LibProfessionDB candidate into `entry.futureCrafts` / `entry.unknownFutureCrafts` before checking `isKnown`. The `isKnown` check only guarded insertion into `allFutureRecipes`. Consequently the item-level relationship index and tags could contain a future candidate even for a known recipe. The original identity test also relied only on profession + recipe ID.

**Competing hypotheses considered:**
1. The database's recipe ID differs from the client-captured recipe ID for the same named output recipe.
2. The same recipe ID is recognized, but the candidate is still inserted into the future item index because insertion occurs before the known check.

**Diagnostic that distinguishes them:** compare profession ID, recipe ID, output item ID and normalized recipe name across the known capture and library candidate; then inspect whether a candidate is appended to the item's future arrays after `isKnown` is true.

**Finding:** source inspection confirmed hypothesis 2 directly. A different recipe key for an otherwise matching recipe is also plausible and is now handled by a conservative fallback match on profession + output item ID + normalized recipe name.

**Change:** known identity is resolved before any future item relationship or future candidate list insertion. Exact profession/recipe ID wins; normalized name matching is only a fallback when profession and output item also agree. Known item-level craft state takes precedence over future, borrowed and unknown item-level tags/filters.

**Boundary:** a genuinely different unlearned route for an item with a known route can remain in All Crafts and in the detail panel as an additional unlearned route. It does not change the item's item-level category from Known.

### B. Vendor value remains uncached

**Evidence:** screenshots show `Item value not cached` in the selected-item detail for multiple market items.

**Source finding:** 0.5.0 only consumed the legacy `GetItemInfo` tuple and listened for `GET_ITEM_INFO_RECEIVED`. It did not read a table result from `C_Item.GetItemInfo` or listen for `ITEM_DATA_LOAD_RESULT`. This did not establish which exact path failed on the player's Forever build.

**Competing hypotheses:**
1. The client populates item information through the `C_Item.GetItemInfo` table path or signals completion through `ITEM_DATA_LOAD_RESULT`, while Market only observes the legacy tuple/event.
2. The item data request completes unsuccessfully or the client exposes no sell price for that item; the detail must report that limitation rather than loop requests or pretend a value exists.

**Diagnostic that distinguishes them:** select one uncached item, observe which load event arrives, and inspect both `C_Item.GetItemInfo(itemID)` and legacy `GetItemInfo(itemID)` after that event. A returned sell price proves the cache path; an unsuccessful event or nil sell price through both paths establishes that the client did not provide the value.

**Change:** support the optional table-return API and legacy tuple; request item data once for the selected item; listen for both `GET_ITEM_INFO_RECEIVED` and defensively registered `ITEM_DATA_LOAD_RESULT`; refresh selected detail after completion. The detail reports `Loading item data…`, `Unavailable from client data`, or the actual vendor value. Failed/unavailable results do not cause repeated request loops.

**Runtime status:** the exact event/API behavior on the player's Forever build remains UNKNOWN until live retest.

### C. Item-role dropdown semantics

**Evidence:** screenshot shows long menu labels wrapping/overlapping and unclear distinctions between future, borrowed and unknown sources.

**Change:** rename the selected default to `All item types`; use concise choices for known craft outputs, unlearned confirmed, unlearned borrowed, unlearned unknown, gathering resources and crafting reagents. Each choice has an explanatory tooltip. All Crafts uses explicit unlearned/source wording as a recipe-source filter. Item-level known/future states are exclusive; All Crafts remains recipe-level and may show a genuinely different unlearned route.

## 4. Files changed

- `AddOns/ModuloMarket/ProfessionData.lua`
  - Known recipe identity matching.
  - Future candidate insertion occurs only after known exclusion.
  - Known item-level role precedence for future/borrowed/unknown tags and filters.
- `AddOns/ModuloMarket/MarketUI.lua`
  - Vendor item-info table and legacy tuple support.
  - Dual item-data completion events.
  - Bounded per-item loading state and detail refresh.
  - Clearer role labels and option tooltips.
  - Detail heading distinguishes other unlearned routes when a known route exists.
- `AddOns/ModuloMarket/Core.lua` — version 0.5.1.
- `AddOns/ModuloMarket/ModuloMarket.toc` — version 0.5.1.
- `README.md` — current handoff and 0.5.1 change record.
- `MANIFEST.json` — version, inventory, capability states and previous-child provenance.
- Regression tests updated for current child version and new patch-specific tests added.

No MODULO parent source, Auctionator, ProfessionMaster, GatherLite or optional addon source was changed. No purchase, bid, post, cancel or automatic auction request behavior was added.

## 5. Acceptance evidence

### Offline tests
- `pytest -q`: **109 passed**.
- Lua UI integration harness: PASS; includes:
  - known recipe with a different library recipe key is not inserted as future;
  - known item-level role precedence;
  - uncached selected item requests item data;
  - item-info completion refreshes selected detail and populates vendor price;
  - role filter menu uses the revised labels.
- `texluac -p AddOns/ModuloMarket/*.lua`: PASS.
- Python source/manifest/TOC checks: PASS.

Offline harness evidence is not Forever runtime acceptance.

### Package checks
- Final ZIP: `ModuloMarket-0.5.1.zip`; 61 entries; 217,308 bytes (final package).
- ZIP CRC: PASS (`ZipFile.testzip()` returned `None`).
- Manifest file inventory: exact (61/61).
- TOC / Core / manifest version agreement: 0.5.1.
- Fresh extraction: PASS; 109 tests passed from the extracted package; `texluac -p AddOns/ModuloMarket/*.lua` passed from the extracted package.
- Parent MODULO 1.0.48 hash and byte count unchanged.
- Final archive SHA-256 is recorded in the delivery handoff; it is not embedded into its own archive because that would make the checksum self-referential.

## 6. Runtime acceptance and exit criteria

**FOREVER runtime:** NOT RUN / UNKNOWN.

Required player checks:
1. Select Savory Deviate Delight and confirm it is `[C]` only for the known recipe, with no duplicate future marker for that same recipe.
2. If a distinct unlearned route genuinely creates the same item, confirm it appears only as an additional unlearned recipe route in detail/All Crafts, not as a second item-level future classification.
3. Select several items that previously showed `Item value not cached`. Confirm the detail transitions from loading to a coin value. If it becomes unavailable, provide the exact selected item and resulting status; that distinguishes client API/event behavior from the source-level cache handling.
4. Open the role dropdown and confirm labels fit, tooltips explain each category, and known/future/borrowed/unknown filters produce expected rows.

Do not mark the runtime defect closed until these player-visible checks pass on the relevant Forever client.

## 7. Exit disposition

- Known/future source defect: source corrected; offline acceptance PASS; Forever runtime confirmation pending.
- Vendor value loading: source broadened and offline event path PASS; actual Forever API/event behavior UNKNOWN pending player test.
- Item-role dropdown: wording and tooltips corrected; offline harness PASS; visual Forever acceptance pending.
- MODULO parent: unchanged at 1.0.48.
