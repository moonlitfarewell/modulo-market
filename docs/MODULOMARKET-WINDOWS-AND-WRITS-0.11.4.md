# Modulo Market 0.11.4 — movable windows, settings containment and Craftsman's Writs

## Player problem and observable result

The player reported that both market windows were clamped to the visible game viewport, making it difficult to move them partly off-screen while keeping the game usable. The Market Information / Craft Economics inspector values were still larger than the accepted Turn-In Economics size. The addon settings page allowed Advanced Tools content to overflow. Modern checkboxes functioned but did not visibly change when checked.

The Turn-Ins tab also treated Artisan Waylaid Crate reputation as a known zero even though its Favor and cash rewards were unknown, and it did not cover the daily Craftsman's Writ reputation route.

0.11.4 provides:

- Blizz-like and Modern windows can be dragged beyond the visible game viewport (they remain inside the WoW client, not the desktop). Their centre positions persist in `ModuloMarketDB`; the settings page has a reset-position action.
- Market Information and Craft Economics values use the same `GameFontHighlight` body size as Turn-In Economics.
- The Modulo Market settings page uses a contained scroll frame, including Advanced Tools and window-position controls.
- Modern checkbox state is updated before its check-mark is refreshed. Blizz-like checkboxes use the addon-owned check texture for a visible checked state.
- Waylaid Crate Artisan reputation is now `nil` / UNKNOWN rather than `0`; confirmed zero reputation remains explicit for the other crate tiers.
- The Turn-Ins tab includes 150 distinct Craftsman's Writs in addition to the 30 Waylaid Crates. A type filter separates All / Waylaid Crates / Craftsman's Writs; tier and category/profession filters remain available.
- Writ rows show the Writ purchase price, the required crafted output, available buy/craft routes, tier reputation, variable coin-pouch status and gross completion cost per reputation. A coin-pouch average is not treated as guaranteed cash and is not deducted from Cost / Rep.

## Exact evidence and counter-evidence

### Window and presentation

- 0.11.3 `MarketUI.lua` and `ModernUI.lua` explicitly called `SetClampedToScreen(true)`. The user screenshots show the market window occupying the visible client area and the requested use case is to let it extend past the client viewport edge.
- `SelectItem` used `GameFontHighlightLarge` for non-Turn-In selections, while Turn-In selection used `GameFontHighlight`. The same larger value font was restored on tab changes. 0.11.4 uses the accepted body font for all inspector metric values.
- `Theme.lua` placed the Browse Scan launcher at a fixed vertical offset and had no scroll child. The new settings page scroll frame contains the whole settings content.
- `ModernUI.MakeCheck` previously called `Refresh()` before the setter, so the getter returned the old value and the check mark stayed hidden until a later refresh. The setter now runs before `Refresh()`.
- The native Blizz-like checkbox template's checked texture is now set to the addon-owned `Textures/check.tga` and tinted with the active Blizz-like accent. Template click state and normal geometry remain native.

### Artisan Waylaid Crates

- The 0.11.3 source explicitly set `rewardFavor=nil`, `rewardCashCopper=nil`, but `reputation=0` for all eight Artisan crate records. The display correctly preferred Favor when present and otherwise displayed the explicit `0 Rep`; the incorrect zero was in the data, not the formatter.
- 0.11.4 changes only the Artisan `reputation` values to `nil`. The 22 Apprentice / Journeyman / Expert crate records retain their documented `reputation=0` because their known no-repeatable-reputation status is distinct from the still-unconfirmed Artisan reward.
- No current external evidence located in this pass establishes the Artisan crate Favor or cash payout. They remain UNKNOWN. No value is inferred from the fact that the player may have completed quests.

### Craftsman's Writs

- The supplied Wowhead Forever guide, updated 2026-11-13, lists the five profession families and 150 distinct Writ output names, and describes each Writ as a tradable world-drop quest item with a daily turn-in. It identifies Azeroth Commerce Authority (Alliance) and Durotar Supply & Logistics (Horde) as the reputation factions.
- The 60.tools Merchants' Favor guide reports 75 / 125 / 200 reputation by tier. Current Wowhead comments include 125-reputation Expert reports and a 200-reputation Mithril Spurs report, while other player reports disagree on some Expert rewards. The addon labels the tier schedule COMMUNITY_REPORTED_WITH_EXPERT_CONFLICT and marks the table values with an asterisk; the inspector asks the player to verify the actual quest text. This is not FOREVER OBSERVED or FOREVER VERIFIED.
- Writs reward a variable Coin Pouch. Current Wowhead item comments show different payouts across character levels (for example, reports in the low 20s through high 40s silver); the guide's averages are observations, not guaranteed tier values. The addon displays only `Variable pouch` and a note that payouts vary by character level/report. It does not subtract an assumed cash amount from Cost / Rep.
- The 150 Writ outputs are matched by exact output name and profession against the bundled ForeverDB 1.60.1.70938 recipe catalogue and the character/account learned-recipe snapshot. Offline cross-check found 145 matching recipe outputs with reagent groups. Five output names have no matching record in this bundle: Elixir of Ogre's Strength, Gnomish Alarm-O-Bot, Gyromatic Micro-Adjuster, Inlaid Mithril Cylinder and Potion of Demonslaying. Those remain listed, but their craft route is UNKNOWN/incomplete; an Auction House buy route may still appear if a current output listing exists.
- Recipe material prices require the existing compatible market snapshot and sufficient total quantity and cheapest-price depth. Alternative reagent choices are treated as choices, not summed together. Variable reagent quantities, absent prices and insufficient cheapest-price depth fail closed.
- The Writ item itself is matched by exact market-catalogue name. If its listing is absent or ambiguous, completion cost remains incomplete even when the requested crafted output is priceable.

## Calculation contract

For a Writ:

`completion cost = current Writ AH price + cheapest complete requested-item route`

A requested-item route is either:

- Buy one requested crafted output from the AH, if one unit is available at the exposed cheapest price; or
- Craft the output using one complete recipe route, with one cheapest fully priceable choice per required reagent slot.

`gross cost per reported reputation = completion cost / reported tier reputation`

Coin Pouch rewards are variable and appear only as `Variable pouch`. They are not included in gross cost per reported reputation and are not converted into a guaranteed cash return. Reputation figures are marked as community-reported where the sources conflict. No market price, recipe, reagent quantity, coin payout or reputation value is invented when missing.

## Ownership, dependencies and compatibility

- Owner: standalone Modulo Market addon.
- New data file: `AddOns/ModuloMarket/WritData.lua`.
- Writ recipe matching uses the already-bundled ForeverDB data and existing learned-recipe snapshots. No new addon dependency is added.
- No parent MODULO source changed. No optional addon is loaded or called.
- Market scanning, Replicate request semantics, cooldown, one-request-per-session gate, Sell-tab safety, market snapshot format, recipe capture schema, market pricing and crate bundle calculations remain unchanged.
- New persistent fields are limited to `ModuloMarketDB.windowPositions.blizzlike` and `.modern`; no existing SavedVariables fields are removed or reinterpreted.

## Risks and gaps

- A window can be moved entirely off-screen by design. The addon settings page provides a reset-position action; settings remains accessible through the normal WoW options panel.
- Saved centre coordinates may not be ideal after a resolution or UI-scale change. Reset position is the recovery path; no automatic clamp is applied because that would contradict the requested behavior.
- Writ item AH names and output names may be absent from the current snapshot. Such rows remain visible with incomplete pricing.
- Five Writ outputs do not currently match the bundled recipe baseline. They are not silently assigned Classic recipes or guessed reagent lists.
- Coin-pouch values are variable community observations, not guaranteed rewards. Exact payouts are not used in calculations.
- Writ reward values and hand-in NPC/zone metadata are external community evidence, not FOREVER OBSERVED or FOREVER VERIFIED runtime evidence.

## Tests and runtime evidence

See `MODULOMARKET-RUNTIME-AUDIT-0.11.4.md` for exact commands, counts, baseline comparison, ZIP integrity and SHA-256.

- Static/offline tests can establish source paths, data coverage, calculation fail-closed behavior, TGA validity and package consistency.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN for 0.11.4. The player's screenshots establish the earlier 0.11.3 client behavior, not acceptance of these fixes.
- Required in-game acceptance: drag both windows partly beyond each client edge; reload and confirm positions persist; reset each position; inspect Market Information and Craft Economics fonts; scroll the settings page to Advanced Tools; test Modern and Blizz-like checkbox checked states; inspect an Artisan crate; inspect Writs from all three tiers; test Writ and output AH pricing, craft alternatives, NPC/zone notes and missing-price behavior.
- GitHub push: NOT RUN; local bundle only.

## Acceptance / exit criteria

1. Both windows can move beyond the visible game viewport without moving outside the WoW client, and persist their centre positions across reload.
2. Reset Window Position restores the currently selected window to centre.
3. All inspector metric values use the Turn-In Economics body font size.
4. Settings content, including Advanced Tools, is reachable by scrolling and does not paint outside the settings panel.
5. Checked Modern and Blizz-like checkboxes visibly display the check mark immediately after clicking.
6. All 8 Artisan crates display UNKNOWN reward state rather than `0 Rep`; the other crate rewards remain unchanged.
7. The Turn-Ins tab contains 30 crates and 150 distinct Writs, and its type/tier/category filters work in both presentations.
8. Writ completion cost includes one Writ and exactly one complete buy/craft route. Incomplete routes never receive a fabricated total.
9. Reported reputation is separated from variable coin-pouch observations; the latter are not deducted from Cost / Rep.
10. Five unmatched recipe outputs remain UNKNOWN until supported data is added.
11. Existing scan controls, market tabs, market data and calculations remain unchanged.
12. Player-visible acceptance is confirmed on Forever before closing the runtime scope. Until then, Forever runtime remains NOT RUN.
