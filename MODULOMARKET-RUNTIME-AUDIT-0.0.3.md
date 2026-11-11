# Modulo Market Runtime Audit 0.0.3 — separate addon grouping and diagnostics handoff

## Player problem and intended result
The user wants all MODULO suite addons visible together in the AddOns list while keeping each child independently packaged and versioned. Market should eventually provide Auction House snapshot collection and profession profitability calculations, but the current slice must not claim those unimplemented features.

## Adopted structure
`Modulo By Wells` is the collapsible Category; `Modulo` is the parent addon; `Modulo Market` is a Group child. This follows the supplied Forever Polestar TOC pattern (`Category`, `Group`, `Dependencies`). The client does not support nested groups. Market has its own `ModuloMarket` folder, TOC, version 0.0.3, SavedVariables `ModuloMarketDB`, source, audit and ZIP. It declares `Dependencies: Modulo`; MODULO never depends on Market.

## Current implementation
- `AddOns/ModuloMarket/ModuloMarket.toc`: suite category/group/dependency metadata and independent SavedVariables.
- `Core.lua`: registers `/mm` and `/mmdebug`, initializes `ModuloMarketDB`, and reports addon load.
- `Diagnostics.lua`: bounded, read-only profession/recipe and Auction House API-presence report.
- No active Auction House request APIs are called. The five observed browse/throttle API names are inspected by type only.

## Evidence and limits
Direct user evidence on Forever 1.60.1 build 70862/interface 16001 confirms the relevant Auction House browse/throttle API functions exist, and the profession APIs used by the diagnostic report exist. User observations include active profession recipe counts for Tailoring (31), Enchanting (5), Cooking (20) and Fishing (1). These are API-presence/context observations, not proof of full AH pagination, complete profession recipe coverage or accurate profitability.

Counter-evidence/gaps: no complete Auction House browse scan has been run; request signatures/filters, result completeness, pagination transitions, item pricing, stale/incomplete snapshots and interference with other AH addons are not yet accepted. `OpenTradeSkill()` returned false in prior tests, so the diagnostic only reports the currently open profession context.

## Ownership and dependencies
Market is a separate optional addon. Auctionator remains the specialist for auction search, buying, selling, posting and cancellation; Market's intended role is read-only market observation and analysis. ProfessionMaster remains the profession-management specialist; Market may calculate craft profitability without managing professions. Market depends on MODULO for suite grouping/load order; MODULO must never depend on Market. No Auctionator or ProfessionMaster dependency is added.

## Tests and runtime status
- Static TOC/version/Group/Dependencies/SavedVariables tests: run by `tests/test_modulomarket_addon_grouping_0_0_3.py`.
- Lua syntax: `texluac -p AddOns/ModuloMarket/Core.lua` and `texluac -p AddOns/ModuloMarket/Diagnostics.lua`.
- ZIP CRC, inventory and fresh extraction: recorded in the handoff.
- Forever AddOns-list rendering, addon load order, `/mmdebug` UI and copy workflow: NOT RUN.
- Complete AH scan, pagination/throttle safety, persisted snapshot, profession profitability, disenchant expected value and independent Fishing commodity valuation: NOT IMPLEMENTED / NOT RUN.
- Retail runtime: NOT RUN.

## Acceptance and next gate
1. Install MODULO 1.0.48 and this separate Market 0.0.3 ZIP.
2. Confirm the AddOns list shows Market as an indented child under Modulo in the `Modulo By Wells` category.
3. Confirm enabling Market loads without Lua errors and `/mmdebug` opens, refreshes, scrolls and copies a report.
4. Confirm MODULO loads with Market disabled.
5. Before implementing scan persistence, run one controlled, complete AH browse query with conservative pagination, inspect request throttling and verify no interference with Auctionator buying/selling/posting. Do not infer a complete scan from API presence.


## Package record
- ZIP: `ModuloMarket-0.0.3.zip`
- Files: 7 (exact inventory; no cache artifacts)
- ZIP CRC/integrity: PASS
- Fresh extraction: `/mnt/data/market003_final_fresh/ModuloMarket-0.0.3`; focused test 3 passed; Lua syntax PASS for Core.lua and Diagnostics.lua.
