# ModuloMarket 0.10.0 — Turn-Ins runtime/capability audit

**Status:** SOURCE IMPLEMENTED · OFFLINE TESTED · FOREVER RUNTIME NOT RUN

## Player problem and observable result

The Low Supply tab duplicated an item browser rather than answering a distinct player question. 0.10.0 replaces it with Turn-Ins: a comparison of all 30 labelled WoW: Forever Waylaid Crates by full completion cost and return.

Observable in-game result after installation: six tabs remain; Low Supply is replaced by Turn-Ins. The new tab lists every crate, filters by tier/category, searches crate and ingredient names, and shows crate + material completion expenditure, cash return, Merchant's Favor, reputation and net cash cost per Favor. Selecting a crate shows its own market price and all accepted alternative material bundles.

## Canonical baseline and provenance

- Baseline: `ModuloMarket-GitHub-Update-0.9.9.zip`, user-visible local release archive (2,376,383 bytes; SHA-256 `5a06dcdb0574897815b8576498a786e924256bb12890a12ecd9eaf8d79fe9eb2`).
- Baseline ZIP integrity: checked before extraction; see release validation record.
- Source of crate item identities: user-supplied `AddOns.zip`, specifically `AddOns/Polestar_Codex/Items4.lua`; the 30 labelled crate item IDs were cross-checked there. This is evidence only; Polestar is not a dependency.
- Material bundle requirements and reported reward values: external WoW: Forever community item/database references listed below. They are not project FOREVER OBSERVED/VERIFIED evidence.
- No API key, private credential or external addon dependency was introduced.

## Implementation

- Added `TurnInData.lua`: 30 labelled crate definitions, 96 alternative material choices, tier/category metadata, reported Apprentice/Journeyman/Expert Favor and cash returns, Artisan reward values UNKNOWN, repeatable reputation 0, and the separate one-time Shipping Label bonus.
- Added `TurnInEngine.lua`: matches ingredient names against the market catalogue, reads the labelled crate's own market row, prices one selected alternative, chooses the cheapest fully priceable alternative, computes gross completion cost, cash net and net cash per Favor.
- Updated `MarketUI.lua`: replaced Low Supply with Turn-Ins; added tier/category filters and material search; added six comparison columns and selected-crate breakdown; retained existing tab-specific layouts and the exact-build snapshot gate.
- Updated TOC load order, version and project documentation.

## Calculation safety / known market-depth limit

The existing saved market snapshot exposes cheapest unit price, quantity at that cheapest price and total listed quantity, but not every deeper price tier. If a required material quantity is larger than the amount available at the cheapest known price, the engine does not extrapolate the cheapest price over the rest. It marks that bundle line and the crate completion cost incomplete/unknown. If total supply is below the required quantity, it marks the item unavailable. The crate's own AH price is mandatory. All crates remain visible in either state.

This is deliberately conservative. A future capability could acquire exact per-item price depth, but 0.10.0 does not invent it or add a burst of per-item browse queries.

## Rewards and return semantics

- Apprentice/Journeyman/Expert returns are community-reported and shown as separate cash and Favor income.
- Artisan Favor/cash return is UNKNOWN; it is not treated as zero.
- Repeatable crate reputation is reported as 0. The first Shipping Label quest's +50 Favor / +2,000 reputation is one-time and excluded from repeatable economics.
- Performance Bonus is not included because it depends on character progression and is not known to ModuloMarket.
- Net cash cost = gross completion cost − reported cash return. Favor and reputation are shown as separate non-cash returns; Favor is used as the denominator for net cash cost per Favor. No arbitrary gold conversion is assigned to Favor or reputation.

## Ownership / boundaries

ModuloMarket owns this Auction House comparison and presentation. It consumes its own saved Full Market catalogue. It does not depend on Polestar, Wowhead, WowSeer or Forever Hub. No parent MODULO code, scanner behavior, snapshot schema, SavedVariables schema, recipe engine, profession data or other tabs' calculations were intentionally changed.

## Tests and validation

- Lua syntax: TurnInData.lua, TurnInEngine.lua and MarketUI.lua loadfile syntax PASS.
- Lua engine harness: 30 crate definitions, 96 alternatives, crate+bundle price, cash/Favor/reputation arithmetic, Artisan UNKNOWN, insufficient cheapest-price depth fail-closed, missing crate price fail-closed, one-time bonus separation — PASS.
- Python focused Turn-Ins tests: 7 PASS.
- Full historical suite baseline (0.9.9): 275 PASS / 81 failures.
- Full suite after 0.10.0 source changes: 276 PASS / 87 failures (363 tests total). Against the 0.9.9 baseline, the six additional failure IDs are superseded assertions that specifically require the former Low Supply tab set or 0.9.8/0.9.9 version metadata. No unrelated new failure category was observed. The new focused Turn-Ins tests are independent and pass.
- Forever client runtime: NOT RUN. The client was in scheduled maintenance when this slice was requested. UI geometry, dropdown interaction, actual tooltip content, live AH depth and actual per-crate reward values remain to be verified in the client.

## Acceptance / exit criteria

The source slice is ready for in-game acceptance when Forever returns:
1. Confirm the Turn-Ins tab opens and all 30 crates appear.
2. Verify tier/category filters and ingredient search.
3. Select crates from all four tiers; check crate price and accepted material alternatives.
4. Confirm completion cost includes the labelled crate plus exactly one chosen alternative.
5. Verify rows with insufficient cheapest-price depth remain incomplete rather than overstated.
6. Check cash/Favor/reputation display and Artisan UNKNOWN state.
7. Switch away from and back to the tab; confirm dropdowns close with the parent window and other tabs remain unchanged.

Release readiness does not mean Forever runtime verified.

## External references reviewed (2026-11-13)

- Forever Hub, “Merchant's Favor in WoW: Forever”: tier reward table, no repeatable crate reputation, one-time Shipping Label reward, Artisan rewards unknown: https://forever-hub.com/en/guides/merchants-favor
- WowSeer, “WoW Forever Merchant's Favor: Supply Crates and Rewards”: crate categories and listed material choices: https://wowseer.gg/professions?p=merchants-favor
- Wowhead Forever, “Waylaid Crate: Journeyman Herbs”: example tooltip requirements and comment reporting 10 Favor / 5 silver / no reputation: https://www.wowhead.com/forever/item=248686/waylaid-crate-journeyman-herbs
- Wowhead Forever, “Waylaid Crate: Journeyman Textiles”: example textiles bundle and reported return: https://www.wowhead.com/forever/item=248688/waylaid-crate-journeyman-textiles
- Wowhead Forever reputation guides: first-turn-in Shipping Label and writ reputation are separate from repeatable crate rewards: https://www.wowhead.com/forever/it/guide/azeroth-commerce-authority-reputation-professions
