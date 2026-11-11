# Modulo Market Runtime Audit 0.3.0 — automatic profession-aware craft economics

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.3.0  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release class:** separate optional child addon; player-facing capability slice.  
**Runtime status:** source and offline harnesses and 67 Python tests PASS; Forever 0.3.0 runtime NOT RUN.

## 1. Player problem and observable result

The player rejected 0.2.0's manual cost-per-unit and target-sale-price inputs. Market's purpose is to determine the economics of what the character can craft from current market data, not ask the player to manually supply the cost and sale assumptions.

0.3.0 makes the first automatic end-to-end slice available:
- Market observes the character's profession window and captures known recipes.
- It reads client-provided recipe output and reagent slots.
- It looks up reagent and output prices in the saved item-ID market catalogue.
- It calculates total reagent cost, post-AH-cut sale proceeds and profit per craft.
- It displays known crafts and positive-profit crafts.
- Selecting a material shows recipes that consume it; selecting a crafted output shows recipes that create it.

The result is limited to known recipes in professions the player has opened. It does not yet show all unlearned recipes or skill-level unlock opportunities.

## 2. Source of truth and evidence actually available

### Canonical parent and child
- Parent: `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, 506 members, ZIP CRC PASS.
- Parent contains the current governance files: PROJECT-START-HERE, README, WORKFLOW, PROJECT-PROGRESS, PROJECT-DECISIONS, QA, SOURCE-REVIEW-LEDGER, MODULO-ARCHITECTURE and FOREVER-COMPATIBILITY-CONTRACT. Parent remains unchanged.
- Child baseline: `ModuloMarket-0.2.0.zip`, 116,512 bytes, SHA-256 `5db8a144dc765c1d9073608524164aad2bcb4637bba720bcc6881190b3af4b56`, 39 entries, ZIP CRC PASS.
- Previous 0.2.0 standalone audit: `MODULOMARKET-RUNTIME-AUDIT-0.2.0.md`, 15,905 bytes, SHA-256 `c264145d6156fc666fd89694b3993203a8221b83f33e8f7f6c13d87366cab5c8`.
- Supplied AddOns archive: `AddOns.zip`, 143,179,120 bytes, SHA-256 `2b595d3de2d8a73b166a98535e4d843b939c7b7ad5afe51dd8f76a1369a4efb2`, 5,375 entries, ZIP CRC PASS. It contains ProfessionMaster source and its Forever recipe model; it does not contain LibProfessionDB or ForeverDB credentials/data.
- Parent `MODULO-Project-Source-1.0.48.zip` and Market 0.2.0 package CRCs verified before work. This pass changes only the separate Market child.

### Prior player/runtime evidence preserved
- Browse snapshot: 16,574 variants, 34 pages, 21.1 seconds; FOREVER OBSERVED.
- Replicate initial response: 291,276 auctions in 17.0 seconds; three sampled records had `hasAllInfo=true`; this is initial-response evidence, not full traversal.
- 0.1.0 repeated UI hangs and duplicate-looking rows; FOREVER OBSERVED player report.
- 0.2.0 incremental grouped UI and history: source implemented; Forever runtime NOT RUN.
- No new 0.3.0 Forever runtime report was supplied.

### Source/API evidence
- Existing 0.2.0 `Diagnostics.lua` already probes `C_TradeSkillUI.GetBaseProfessionInfo`, `GetFilteredRecipeIDs`, `GetRecipeInfo`, `GetRecipeSchematic`, `GetRecipeOutputItemData`, `GetProfessionInfoByRecipeID`, `IsRecipeInSkillLine` and `OpenTradeSkill`. 0.3.0 adds `GetAllRecipeIDs` to the diagnostic inventory.
- Supplied ProfessionMaster `services/own-professions-service.lua` detects Forever's modern C_TradeSkillUI path and registers `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED`; it uses `GetChildProfessionInfo`, `GetBaseProfessionInfo`, `GetAllRecipeIDs` (fallback `GetFilteredRecipeIDs`) and `GetRecipeInfo(...).learned` to capture learned recipes. This is source observation of a specialist addon path, not proof that Market's new event/capture path works on the target client.
- ForeverDB developer documentation specifies `GET /api/v1/professions/{slug}` with recipe skill colours, reagent quantities, output counts/ranges and learning sources; source provenance distinguishes player-seen Forever records from Classic-derived records. The Cooking page lists 132 recipes, 44 new in Forever. The API requires an approved account key and visible credit to ForeverDB.net. No API key was available, and an addon cannot make arbitrary Internet requests; no ForeverDB data is included in this package. Sources: https://foreverdb.net/developers and https://foreverdb.net/profession/cooking
- LibProfessionDB 1.9.1 is MIT-licensed and documents a dedicated Forever data tree (2,511 recipes across 10 professions) derived from build 1.60.1.69977. Its own documentation says Forever borrows Vanilla learning-source and trainer-requirement values where no Forever evidence exists; 42 trainer requirements have been seen on real Forever trainers, while the rest remain borrowed or unknown. Borrowed values must not be presented as verified. The exact archive was not available in the working container, so it is not bundled and no runtime dependency was added. Source: https://www.curseforge.com/wow/addons/libprofessiondb
- The user authorized pursuing ForeverDB if useful. Decision: keep it as a possible build-time source after approval/key and attribution requirements are satisfied; prefer an offline Forever recipe database for in-game use. No key was requested or stored.

## 3. Player problem, scope and ownership

### Ownership
- ModuloMarket owns market snapshots, recipe capture, economics, the market UI and all derived profit values.
- MODULO parent 1.0.48 is unchanged.
- ProfessionMaster remains the profession-management specialist. Market borrows no private service or SavedVariables.
- Auctionator remains independent; Market reads neither its private data nor its API.
- The native client `C_TradeSkillUI` is the current 0.3.0 recipe observation surface.

### Scope implemented
- Add `RecipeEngine.lua` loaded before `MarketUI.lua`.
- Automatically observe `TRADE_SKILL_SHOW`, `TRADE_SKILL_LIST_UPDATE` and `TRADE_SKILL_DATA_SOURCE_CHANGED`.
- Capture one current profession in batches of 20 recipe IDs per frame.
- Keep only recipes for which `GetRecipeInfo(recipeID).learned == true`.
- Persist normalized recipe output/reagent data under `professionRecipesByCharacter[realm:character]`.
- Use the current saved market catalogue to calculate cost and sale economics.
- Replace manual cost/target UI with My crafts, Profitable, and material/recipe relationship details.
- Keep existing Browse, Replicate, low-supply, history and no-transaction boundaries.

### Explicitly out of scope / gaps
- All unlearned recipe catalogue and progression-to-next-skill unlocks.
- Trainer/vendor acquisition paths and required learning rank.
- Recursive make-versus-buy chains and intermediate recipe optimization.
- Gathering/farming valuation, disenchant expected value, and profession leveling recommendations.
- No manual cost input, no manual sale price, no manual cooldown/craft reporting.

## 4. Calculation contract and uncertainty handling

For recipe output item `O`, minimum output quantity `q`, required reagent slot `i` with quantity `n_i` and selected reagent price `p_i`, lowest output ask `s`, and AH cut `r`:

`materialCost = Σ(n_i × p_i)`

`netSale = floor(q × s × (1 − r/100))`

`profitPerCraft = netSale − materialCost`

Rules:
- Optional slots explicitly marked `required=false` are excluded.
- If a slot offers alternatives, Market chooses the lowest priced alternative only if every alternative has a known positive market price. Otherwise that slot is incomplete.
- Missing reagent price, reagent quantity, variable reagent quantity, output quantity or output sale price is never converted to zero.
- Variable output uses the minimum quantity, and the detail panel labels the conservative basis.
- The Profitable tab includes only crafts with a complete reagent cost, known output quantity and positive estimated profit.
- A lowest ask is not a guaranteed sale. AH deposit, unsold inventory, undercutting, price movement and sale probability are excluded.

## 5. Competing hypotheses / compatibility risks

### Profession event/capture risk
1. **Hypothesis A:** the target client fires `TRADE_SKILL_SHOW` / `TRADE_SKILL_LIST_UPDATE` and exposes the C_TradeSkillUI fields used by the capture engine. This is supported by ProfessionMaster's supplied Forever-oriented source using the same C_TradeSkillUI family, but Market's exact lifecycle remains untested.
2. **Hypothesis B:** the target client exposes only part of the modern API surface, or event order/list readiness differs; capture could return empty/filtered data or omit schematic fields.

**Discriminator:** run `/mmdebug` and open each profession once on Forever 1.60.1 build 70862; inspect profession API availability, active profession context and recipe count; verify Market's per-character capture summary and saved records. Compare a few known recipes against the native profession UI. No runtime claim is made before this test.

### Market-data completeness risk
1. **Hypothesis A:** the saved snapshot contains positive unit buyout prices for all required reagents and outputs; complete craft economics are available.
2. **Hypothesis B:** one or more required items have no buyout, no snapshot record or incomplete Browse depth; the craft cost/profit must remain unknown.

**Discriminator:** select a recipe with all reagent listings and output listing, compare every line against the saved snapshot and in-game Browse, then select one with a missing reagent price and verify it does not enter Profitable.

### Data-provider risk
- ForeverDB has useful profession/acquisition information but requires an approved API key and visible attribution. It cannot be queried directly by the addon.
- LibProfessionDB has an offline Forever data tree but its learning-source/trainer requirement fields may be borrowed from Vanilla. They must be flagged, not treated as confirmed Forever data.
- Current 0.3.0 avoids those unresolved sources and uses only learned recipe schematics from the client.

## 6. Tests and implementation evidence

### Changed files
- `AddOns/ModuloMarket/RecipeEngine.lua` — new bounded profession capture, per-character persistence and economics engine.
- `AddOns/ModuloMarket/MarketUI.lua` — automatic My crafts/Profitable tabs, market material relationship details, removal of manual cost and target sale inputs.
- `AddOns/ModuloMarket/Diagnostics.lua` — adds `GetAllRecipeIDs` API status and recipe capture summary.
- `AddOns/ModuloMarket/Core.lua` and `ModuloMarket.toc` — version 0.3.0 and load order.
- README, manifest, standalone audit and tests.

### Offline checks
- Recipe engine harness covers:
  - current profession identity and skill;
  - bounded capture completion;
  - learned-only recipe filtering;
  - character-scoped persistence;
  - required reagent quantities;
  - optional reagent slot exclusion;
  - cheapest fully-priced alternative;
  - 5% AH cut and positive/negative profit;
  - missing reagent price remains unknown.
- Responsive UI harness covers:
  - 16,574 source rows grouped to 4,002 item IDs over 84 simulated frames;
  - market item selection and material relationships;
  - My crafts listing and reagent details;
  - Profitable filter;
  - low-supply filter, price history and Browse-window handoff.
- Python regression suite and Lua syntax validation are required before package.

### Runtime acceptance
- Forever 1.60.1 build 70862 profession event capture: NOT RUN.
- Forever schematic/output/reagent API behavior: NOT RUN.
- Forever visual layout and responsive behavior: NOT RUN.
- `/reload` and full restart persistence of recipe capture: NOT RUN.
- Full Replicate traversal/history persistence: remains as 0.2.0 NOT RUN.

## 7. Player acceptance / install

1. Keep MODULO 1.0.48 unchanged.
2. Replace only `AddOns/ModuloMarket` with 0.3.0.
3. `/reload`.
4. Open each character profession window once; the addon should automatically capture known recipes.
5. Open Auction House and `/mm` using the existing saved snapshot; do not start a new Replicate scan for the first test.
6. Confirm My crafts shows learned recipes; select a craft and compare reagent quantities and output against the profession window.
7. Confirm each reagent/output price against the saved Market snapshot; profit should equal net output value minus reagent cost.
8. Select a material in All items and confirm its crafted-by/used-in relationships.
9. Confirm Profitable excludes unknown-cost crafts and includes only positive estimates.
10. `/reload`, reopen Market and verify captured recipes persist.

If no recipes are captured, provide `/mmdebug` report and the `ModuloMarket.lua` SavedVariables file. Do not infer success from the static harness.

## 8. Exit state

**SOURCE IMPLEMENTED:** automatic known-recipe capture, per-character persistence, reagent economics, sale-profit calculation, My crafts/Profitable UI, and material/recipe relationship display.

**OFFLINE VERIFIED:** syntax checks, dedicated recipe engine harness, responsive UI harness, Python regression suite, archive/manifest validation to be recorded in package handoff.

**FOREVER OBSERVED:** existing 0.2.0 Browse and initial Replicate evidence only; it does not cover 0.3.0.

**NOT RUN / UNKNOWN:** actual Forever 0.3.0 profession events, API field completeness, runtime persistence, UI acceptance, unlearned recipe catalogue and skill progression opportunities.

The next capability should be the full offline Forever recipe catalogue and trustworthy current-character recipe/learning-state reconciliation. ForeverDB is the strongest source for per-recipe Forever learning provenance, while LibProfessionDB is a useful MIT-licensed client-derived structural fallback; neither may silently promote borrowed/Classic trainer data to confirmed Forever requirements.
