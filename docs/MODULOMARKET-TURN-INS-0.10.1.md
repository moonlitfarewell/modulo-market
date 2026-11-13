# Turn-Ins — 0.10.1 UX refinement contract

## Player problem

The 0.10.0 comparison spends two columns on Favor and Reputation even though repeatable crates report both as a single hand-in outcome (including a known zero reputation value). The selected inspector does not identify which accepted material option drives the displayed completion cost. The generic Turn-In Notes paragraph does not communicate the selected crate's actual hand-in outcome, and the Turn-In Economics values are visually larger than the surrounding UI.

## Observable result

- Five comparison columns: Waylaid Crate, Completion Cost, Cash Return, Favor / Rep, Net Cost / Favor.
- Favor and reputation remain separately visible in one compact cell. Unknown values remain `?`; reported zero reputation remains `0 Rep`.
- Selecting a crate explicitly identifies the cheapest fully priceable accepted material option as **BEST VALUE**, with each required ingredient and cost listed.
- Hovering Completion Cost reveals the crate price, chosen best material option, ingredient quantities and line costs, and the total completion cost. Missing crate price or material depth is explicitly incomplete.
- Turn-In Notes describe the selected crate's known cash / Favor / reputation outcome.
- Turn-In Economics values use normal body text sizing. Switching tabs immediately restores the other tabs' existing larger inspector typography, even before another row is selected.

## Calculation and evidence

The 0.10.0 `TurnInEngine.BuildRows` logic is unchanged. It selects the lowest-cost alternative for which every required ingredient quantity is priceable at the known cheapest price, then adds the labelled crate's own one-unit price. The market snapshot does not expose deeper price tiers, so this remains a conservative comparison, not a guarantee of the absolute cheapest full-quantity market price.

The selected BEST VALUE marker refers only to the cheapest fully priceable material alternative. It does not imply a complete crate cost when the crate's own AH price is unavailable.

## Scope and ownership

- Owner: ModuloMarket.
- Changes: `MarketUI.lua`, release version metadata in Core / TOC / TurnInData, README, focused tests, this design record and the standalone runtime audit.
- No changes to the pricing engine, market snapshot, scanner, SavedVariables schema, parent MODULO or optional-addon dependencies.

## Validation contract

- Focused Python source regression tests and existing Turn-In Python tests.
- Existing Lua Turn-In harness and Lua syntax/load checks when `texlua` is available.
- Full historical suite compared with the recorded 0.10.0 baseline.
- Forever client runtime: NOT RUN until the exact target client is available; screenshots or source checks do not substitute for in-game acceptance.
