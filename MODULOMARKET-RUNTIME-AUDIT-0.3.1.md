# Modulo Market Runtime Audit 0.3.1 — complete market search, sorting and presentation

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.3.1  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release class:** separate optional child addon; player-facing capability/fix slice.  
**Runtime status:** source implementation and offline tests PASS; Forever 0.3.1 runtime NOT RUN.

## 1. Player problem and observable result

The player supplied screenshots from 0.3.0 showing:
- All items contained 5,130 market items, but search did not provide the flexible item lookup the player expected.
- My crafts and Profitable showed the full stored recipe results available at that time, but the `Ranking 20 profitable crafts…` status was ambiguous and looked like a hard cap.
- The player wants sortable All items columns: Item, Cheapest, At price; and sortable craft columns: Item, Sale / unit, Profit.
- The opaque black frame background is too heavy. Gold, silver and copper values should use WoW's native coin textures and their familiar colours.

The 0.3.1 target result:
- retain every grouped market item and every captured known recipe;
- make search case-insensitive, punctuation-normalized and token-order independent;
- search item IDs and variant names as well as displayed item names; search crafts by output, recipe, profession, reagent names and IDs;
- click column headings to sort the complete result set, not only the 18 virtualized rows;
- keep sorting incremental to protect responsiveness on large catalogues;
- show gold/silver/copper coin icons with gold/silver/copper number colours;
- request a translucent dark backdrop without fading the text and controls.

## 2. Source of truth and evidence actually available

### Canonical parent
- `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, 506 members; ZIP CRC PASS.
- Required project guidance was read from this bundle: `PROJECT-START-HERE.txt`, `README.txt`, `WORKFLOW.txt`, `PROJECT-PROGRESS.md`, `PROJECT-DECISIONS.txt`, `QA.txt`, `SOURCE-REVIEW-LEDGER.md`, `MODULO-ARCHITECTURE.md`, `FOREVER-COMPATIBILITY-CONTRACT.md`.
- Parent remains unchanged. Market remains a separately packaged child depending on MODULO; MODULO does not depend on Market.

### Child baseline
- `ModuloMarket-0.3.0.zip`, 131,561 bytes, SHA-256 `6594807b530b5999059fd3bf97090aacfccae900a221c62e089543759df5eebb`, 43 entries; ZIP CRC PASS.
- 0.3.0 standalone audit and README were read.
- 0.3.0 README states 20 recipe IDs are processed per frame. `RecipeEngine.CaptureBatch` advances `state.index` by 20 and repeats while `state.index <= #state.recipeIDs`; there is no `MAX_RECIPES` or 20-recipe terminal cap in this capture loop.
- Player evidence in this turn: five screenshots and four chat lines:
  - `Captured known Tailoring recipes (20).`
  - `Captured known Enchanting recipes (5).`
  - `Captured known Fishing recipes (1).`
  - `Captured known Cooking recipes (23).`
  - The screenshot reports `49 known crafts`, consistent with 20 + 5 + 1 + 23.
  - The `Ranking 20 profitable crafts…` line is the count of positive-profit recipes that passed the current completeness/positive-profit filter at that time. It is not a hard 20-row cap. The 49 known crafts counter independently confirms the combined My crafts list exceeded 20.
- Screenshots also show the 5,130-item All items count and selected item details. They do not prove that every market item had a populated localized name, nor do they measure frame time.

## 3. Competing explanations and diagnosis of the apparent 20 limit

**Hypothesis A — a hard capture/display cap.** If true, the engine would stop after 20 IDs or the UI would truncate the returned catalogue. Source inspection contradicts this: capture batches 20 per frame and continues until the recipe-ID list is exhausted; `GetAllRecipes` walks the saved recipe maps; view building appends each matching item and does not slice to 20.

**Hypothesis B — 20 is the actual positive-profit result count.** Source and player evidence support this: `opportunities` filters to recipes with known complete economics and `profitCopper > 0`; the status prints `#build.rows`. The separate My crafts view reports 49 known crafts. This is the best-supported explanation.

The 0.3.1 status now says `Sorting all <count> ...` so the count is explicitly a total result count, not a batch size. The 20-per-frame recipe capture budget remains intentional and bounded.

## 4. Ownership and scope

- ModuloMarket owns its grouped item catalogue, search, sorting, automatic recipe economics and UI.
- MODULO 1.0.48 is unchanged.
- ProfessionMaster remains the profession-management specialist; Market does not read its SavedVariables/private API.
- Auctionator remains independent; Market does not read its private data/API.
- No dependency on ForeverDB, LibProfessionDB or another optional addon was added.
- No AH transaction action, buying, bidding, posting, cancellation, manual cooldown reporting or manual crafting-cost entry was added.

## 5. 0.3.1 implementation

### Search
- Normalizes text to lowercase, strips apostrophes and turns punctuation runs into spaces.
- Treats query words as AND terms, independent of order.
- Market item search includes item name, item ID, and saved variant names/IDs.
- Craft search includes output name, recipe name, profession, output/recipe IDs and reagent names/IDs.
- A digits-only query matches an exact item ID or recipe ID, avoiding accidental matches against every ID containing the same substring.
- Filtering remains incremental in batches of 250 source rows per frame.

### Sorting
- Header buttons sort the complete filtered result array; they do not sort only the 18 visible row widgets.
- All items: Item (ascending default), Cheapest, At price, Total.
- My crafts: Item (ascending default), Sale / unit, Materials, Profit / craft.
- Profitable: Profit / craft (descending default), with other sortable columns.
- Low supply: Item, Cheapest, At price / supply, Total.
- Reuses the existing bottom-up merge sort with a 500-output-operation frame budget. No synchronous full-list `table.sort` was introduced.
- Missing numeric values are placed consistently by the comparator; item name and ID provide deterministic tie-breaking.

### Money formatting
- Formats values with the native `Interface\\MoneyFrame\\UI-GoldIcon`, `UI-SilverIcon` and `UI-CopperIcon` textures.
- Applies gold `ffffd700`, silver `ffc7c7cf` and copper `ffeda55f` number colours.
- Existing red/green profit status colouring is retained.

### Background transparency
- Requests `SetBackdropColor(0.015, 0.012, 0.01, 0.76)` where the frame template exposes it.
- Also applies alpha 0.76 to known `Bg` and inset `Bg` regions when exposed.
- Does not apply alpha to the whole frame, so text and controls are not intentionally faded.
- Actual Forever template region names/backdrop behavior remain runtime UNKNOWN. A harness stub proves the intended setter value only, not the target client's rendered transparency.

## 6. Tests and results

### Offline
- `python -m pytest -q -p no:cacheprovider tests` — **73 passed**.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/RecipeEngine.lua AddOns/ModuloMarket/MarketUI.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/market_engine_0_1_0_harness.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Replicate.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**.
- `texlua tests/recipe_engine_0_3_0_harness.lua AddOns/ModuloMarket/RecipeEngine.lua` — **PASS**.
- `texlua tests/market_ui_0_2_0_harness.lua AddOns/ModuloMarket/MarketUI.lua` — **PASS**, 16,574 source variants grouped into 4,002 item IDs; search word-order normalization, punctuation and exact numeric ID; craft reagent-name search; incremental full-catalogue ascending/descending Cheapest sort; My crafts Sale / unit and Profit / craft sorting; coin textures; backdrop alpha; craft/market tabs and relationship details. Simulated UI work completed over 181 frames.
- The harness is offline simulation and does not prove Forever UI template or visual behavior.

### Forever runtime
- 0.3.1 UI/search/sorting runtime: NOT RUN.
- Actual translucent backdrop rendering: NOT RUN.
- Coin texture availability/rendering on Forever: NOT RUN.
- Full character profession catalogue completeness: NOT RUN beyond the supplied player capture counts.
- 0.3.0 prior runtime state remains unchanged; no new 0.3.1 runtime observation is claimed.

## 7. Player acceptance plan

1. Install 0.3.1 over only `AddOns/ModuloMarket`; leave MODULO 1.0.48 unchanged.
2. `/reload`, open Auction House and `/mm`.
3. All items should still show the full grouped count (the supplied 5,130-item snapshot should remain 5,130 unique item IDs).
4. Search by a distinctive multiword name with punctuation/apostrophes; search by item ID; confirm results are not order-sensitive.
5. Click Item, Cheapest and At price headers. Confirm the entire list reorders, not just visible rows; click the same header again to reverse direction.
6. Open My crafts. Confirm all 49 currently captured known crafts remain; click Item, Sale / unit and Profit / craft headers and confirm full-list sorting.
7. Open Profitable. Confirm every currently positive and fully priced craft is listed; 20 is a valid count if only 20 recipes currently pass the positive-profit filter.
8. Confirm gold/silver/copper coin icons and number colours render correctly.
9. Confirm the background shows some world scene through the dark panel while text remains clear.
10. If the backdrop remains opaque or coin icons fail, capture a screenshot and `/mmdebug` output; do not infer the template API from offline tests.

## 8. Exit state

**SOURCE IMPLEMENTED:** normalized multi-field search; sortable full result sets; bounded merge sorting; native coin markup; partial backdrop alpha request; explicit all-results status.

**FOREVER OBSERVED:** only the supplied 0.3.0 screenshot and recipe-capture chat lines. They establish 49 known captured recipes and a 20-profitable-craft count for that session.

**NOT RUN / UNKNOWN:** all 0.3.1 runtime acceptance, actual Forever backdrop region behavior, localized coin rendering, visual layout after the new headers, and whether additional unlearned recipes should be catalogued from an offline ForeverDB import.

This slice closes source implementation and offline checks only. It does not close Forever runtime acceptance.
