# Turn-Ins — 0.10.0 design and calculation contract

## Player problem

The former Low Supply view duplicated a filtered auction-item list. Players need a comparison of repeatable hand-ins: which Waylaid Crate can be completed for the lowest actual Auction House outlay, and what cash/token/reputation return does that hand-in provide?

## Scope

- Replace the Low Supply tab with **Turn-Ins**.
- Include all 30 labelled Waylaid Crate types (Apprentice, Journeyman, Expert and Artisan).
- Treat each material bullet on a crate tooltip as an alternative bundle. A crate is completed with one accepted alternative, not all alternatives.
- Include the labelled crate item itself as a one-unit Auction House purchase requirement.
- Include every material quantity in each accepted alternative.
- Use the current full-market snapshot only when its build matches the current Forever client.
- Show cash return, Merchant's Favor and reputation as income, separately from gross expenditure.
- Exclude the one-time Shipping Label quest bonus and any character-specific Performance Bonus from repeatable per-crate economics.
- Keep the All Items, Economics, Crafts, Materials and History tabs and their calculations/layouts unchanged.

## Economics

For each alternative bundle:

`bundle cost = sum(required quantity × current cheapest unit price)`

The current replicate snapshot exposes the cheapest unit price, quantity available at that cheapest price, and total listed quantity; it does not expose every deeper price level. Therefore a bundle line is priceable only if the full required quantity is available at the cheapest known price. If total supply is below the requirement, the line is unavailable. If total supply is sufficient but cheapest-price depth is insufficient, the line is UNKNOWN because the next price tier is not present in the snapshot. The engine does not multiply the cheapest price across unpriced deeper units.

`gross completion cost = labelled crate price + cheapest fully priceable alternative bundle cost`

`net cash cost = gross completion cost − reported cash return`

`net cash cost per Favor = net cash cost ÷ reported Merchant's Favor`

A completion cost is unavailable if the crate itself has no current buyout or no accepted bundle can be fully priced. Every crate remains in the table in that state. Artisan Favor and cash returns are UNKNOWN and are not treated as zero.

## Reward handling

Community references report the following repeatable crate returns:

| Tier / crate category | Merchant's Favor | Cash return |
|---|---:|---:|
| Apprentice herbs / ore / textiles / curiosities | 5 | 2s 50c |
| Apprentice fabrics / ingots / parts | 10 | 5s |
| Journeyman herbs / ore / textiles / curiosities | 10 | 5s |
| Journeyman fabrics / ingots / parts | 20 | 10s |
| Expert herbs / ore / textiles / curiosities | 15 | 7s 50c |
| Expert fabrics / ingots / parts | 30 | 15s |
| Artisan (all categories) | UNKNOWN | UNKNOWN |

Community references report no repeatable reputation from Waylaid Crates. The first Shipping Label quest is a separate one-time reward of 50 Favor and 2,000 reputation; it is shown as a note and excluded from the crate comparison. Performance Bonus can change Favor income based on character progression and is not assumed by the addon.

These reward figures are external community-reported data, not project FOREVER OBSERVED or FOREVER VERIFIED runtime evidence. Artisan rewards remain explicitly unknown.

## Item identity and price lookup

- Labelled crate item IDs: 248682–248699 and 248702–248713, cross-checked against the user-supplied `AddOns/Polestar_Codex/Items4.lua` item index.
- The generic unlabelled `Waylaid Crate` item is the label-reveal container. The row's labelled crate item is the crate required for that specific comparison; it is the item whose AH price is included.
- Ingredient names are matched against the current market catalogue's item names. No external addon is loaded or called at runtime; Polestar is not a dependency.

## UI

- Left: search across crate names and accepted ingredient names; tier and category filters default to All; all 30 crates are shown by default.
- Middle: Waylaid Crate, Completion Cost, Cash Return, Favor, Reputation, Net Cost / Favor. Numeric columns are measured and anchored from the right; the crate name takes remaining width.
- Right: selected crate's own AH price, each alternative bundle and its per-item price/depth status, gross completion cost, cash/Favor/reputation return and net cash cost per Favor.
- The lower inspector card explains the one-time Shipping Label reward and that Artisan rewards / Performance Bonus are not included.

## Ownership and compatibility

This is ModuloMarket-owned auction comparison and UI. It does not add a dependency on Polestar, Wowhead, Forever Hub or any other optional addon. It does not change parent MODULO, scanner acquisition, SavedVariables schema, recipe calculations or the market snapshot format. Price inputs obey the existing exact-client-build market snapshot compatibility gate.

## Acceptance criteria

- All 30 labelled crates appear by default, even without AH prices.
- All 96 listed material choices are separate alternatives; selecting one bundle never sums sibling alternatives.
- Every completion cost includes one labelled crate and one complete alternative bundle.
- Cash return is subtracted only after being shown separately as income; Favor and reputation are shown separately as token/standing returns.
- Artisan reward values, missing AH listings and unavailable deeper price levels remain UNKNOWN/incomplete.
- One-time Shipping Label reward is never multiplied into every crate.
- Existing tabs and calculations remain unchanged.
- Offline Lua harness, syntax checks, Python regressions, ZIP CRC and fresh extraction pass.
- Forever runtime verification remains NOT RUN until the client is available and the user accepts the new tab in-game.
