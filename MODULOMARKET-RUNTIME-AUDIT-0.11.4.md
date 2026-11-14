# Modulo Market 0.11.4 — runtime capability audit

## Release scope

0.11.4 adds movable/persisted Blizz-like and Modern window positions, settings-page scroll containment and position reset, uniform inspector value font sizing, visible checkbox state, correction of unknown Artisan crate reputation, and a 150-entry Craftsman's Writ Turn-Ins catalogue with recipe/buyout alternatives.

See `docs/MODULOMARKET-WINDOWS-AND-WRITS-0.11.4.md` for the player problem, exact evidence, source provenance, calculation contract, ownership, risks, gaps and acceptance criteria.

## Canonical source and integrity

- Child source bundle: `ModuloMarket-GitHub-Update-0.11.3.zip`.
- Child source SHA-256: `c3709e42015e1fdee4bd2518318aab29a9bc8136a611ae4ce961e7171c55fbd1`.
- Child source size: 2,449,592 bytes; 242 files; ZIP CRC test passed; child manifest declares 242 files and version 0.11.3.
- Parent project source: `MODULO-Project-Source-1.0.48.zip`.
- Parent source SHA-256: `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`.
- Parent source size: 41,236,015 bytes; 506 files; ZIP CRC test passed; `AddOns/Modulo/Modulo.toc` reports 1.0.48.
- Parent records identify Modulo Market as a separate optional addon with its own release lifecycle. No parent MODULO source or records were changed in this child slice.

## Source changes

- `AddOns/ModuloMarket/MarketUI.lua`: unbounded client-viewport movement, saved/reset position, consistent inspector metric font, visible Blizz-like check texture, crate/Writ type filter and inspector route presentation.
- `AddOns/ModuloMarket/ModernUI.lua`: unbounded client-viewport movement, saved/reset position, immediate checked-state refresh, Writ table/filter/inspector presentation and refreshed dynamic headers.
- `AddOns/ModuloMarket/Theme.lua`: scroll-contained settings page and reset-position control; Browse Scan remains available under Advanced Tools.
- `AddOns/ModuloMarket/TurnInData.lua`: eight Artisan crate reputation values are UNKNOWN (`nil`) rather than false zero; 22 other known zero-reputation crate records remain unchanged.
- `AddOns/ModuloMarket/WritData.lua`: 150 distinct Craftsman's Writ records across five professions, reported tier rewards, faction names and guide-listed NPC/zone details where available.
- `AddOns/ModuloMarket/TurnInEngine.lua`: exact-name Writ price matching, learned/ForeverDB recipe matching, buy/craft alternatives, depth-aware material cost and gross cost per reported reputation.
- `AddOns/ModuloMarket/Textures/refresh.tga`: refreshed 64×64 RGBA refresh arrow.
- TOC, Core, README, manifest, docs and focused tests updated to 0.11.4.

## Writ source and data limitations

- Writ catalogue: supplied [Wowhead Forever Craftsman's Writs guide](https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards) (updated 2026-11-13), covering 150 distinct output names across Alchemy, Blacksmithing, Engineering, Leatherworking and Tailoring.
- Faction/reputation reference: [60.tools Merchants' Favor guide](https://www.60.tools/guides/merchants-favor) (accessed 2026-11-14), which reports 75 / 125 / 200 reputation by Journeyman / Expert / Artisan tier. Current Wowhead player comments include 125 Expert and 200 Artisan reports, but other Expert reports conflict. UI values are marked with `*`; the inspector explicitly asks the player to verify the quest text. These are COMMUNITY_REPORTED, not FOREVER OBSERVED or FOREVER VERIFIED.
- Cash reward: Writs award a variable Coin Pouch. Current [Wowhead Coin Pouch comments](https://www.wowhead.com/forever/item=284584/coin-pouch) show payouts varying by character level/report. The addon shows `Variable pouch` and does not invent a fixed cash return or subtract one from Cost / Rep.
- Recipe matching: exact output name and profession against the bundled ForeverDB 1.60.1.70938 recipe catalogue plus learned-recipe snapshots. The Lua coverage harness found 145/150 Writ outputs with matching profession and complete reagent groups. Five remain unmatched and fail closed: Elixir of Ogre's Strength, Gnomish Alarm-O-Bot, Gyromatic Micro-Adjuster, Inlaid Mithril Cylinder and Potion of Demonslaying.
- Completion cost = one current Writ AH price + the cheapest fully priceable output route (buy one crafted output or craft through one recipe). Material choices are alternatives, not summed together. Insufficient depth, absent prices, ambiguous Writ names, missing recipe data or variable reagent quantity never produce an estimated total.
- Cost / Rep* is gross completion cost divided by the community-reported tier reputation. Variable Coin Pouch cash is not deducted. Writ AH names are matched by exact normalized item name; missing/ambiguous listings remain incomplete.
- Artisan Waylaid Crate Favor and cash remain UNKNOWN. Current community sources still do not establish their payouts; no zero or inferred reward is shown.

## Tests and validation

| Check | Result |
|---|---:|
| Focused 0.11.4 regression tests | **12 passed** |
| Writ Lua calculation/coverage harness | **11 checks passed**; 145/150 exact recipe coverage |
| Full historical regression suite | **335 passed / 87 failed / 422 total** |
| 0.11.3 baseline full suite | **323 passed / 87 failed / 410 total** |
| Failure ID comparison | **87 unchanged; 0 new failing IDs** |
| Addon Lua syntax (`texluac -p`) | **14/14 passed** |
| Modern utility TGA assets | **6/6 valid 64×64 RGBA TGA** |

The 87 historical failures are exactly the same test IDs as the 0.11.3 baseline. The 12 added focused tests pass. The Lua Writ harness verifies 150 entries, 75/125/200 reported tier rewards, the Artisan UNKNOWN correction, Writ AH + craft/buy calculation, variable Coin Pouch exclusion, insufficient-depth fail-closed behavior, stable row identity for unlisted Writs, and 145/150 embedded ForeverDB recipe matches.

Exact commands:

```text
pytest -q tests/test_modulomarket_0_11_4_runtime_slice.py --disable-warnings
texlua tests/turnin_writs_0_11_4_harness.lua AddOns/ModuloMarket
find AddOns/ModuloMarket -name '*.lua' -print0 | xargs -0 -n1 texluac -p
pytest -q --disable-warnings
```

## Runtime evidence and limitations

- User screenshots establish the target Forever 1.60.1 build 70938 and earlier 0.11.2 / 0.11.3 interface behavior. They do not establish acceptance of 0.11.4.
- Forever runtime acceptance for 0.11.4: **NOT RUN**. Required checks include moving both windows partly beyond each client edge, reload position persistence and reset, inspector font size, settings scrolling, visible checkbox states, Artisan UNKNOWN display, and Writ list/filter/economics behavior.
- Retail runtime: **NOT RUN**.
- GitHub push: **NOT RUN**; local bundle only.
- No FOREVER VERIFIED claim is made for the new Writ catalogue, reward schedule, NPC/zone data, or runtime behavior.

## Acceptance / exit criteria

1. Both windows can move beyond the visible game viewport without moving outside the WoW client; positions persist across reload.
2. Reset Window Position clears saved position and centres the selected window, including when the frame has not yet been created in the current session.
3. All inspector metric values use the Turn-In Economics body font size.
4. Settings content, including Advanced Tools, is reachable by scrolling and does not paint outside the settings panel.
5. Checked Modern and Blizz-like checkboxes visibly display the check mark immediately after clicking.
6. All eight Artisan crates display UNKNOWN reward state rather than `0 Rep`; the other crate rewards remain unchanged.
7. The Turn-Ins tab contains 30 crates and 150 distinct Writs; type/tier/category-profession filters work in both presentations.
8. Writ completion cost includes one Writ and exactly one complete buy/craft route. Incomplete routes never receive a fabricated total.
9. Reported reputation is marked with `*`; variable Coin Pouch observations are never treated as guaranteed cash or deducted from Cost / Rep*.
10. Five unmatched recipe outputs remain UNKNOWN until supported data is added.
11. Existing scan workflow and shared market data remain unchanged.
12. Player-visible acceptance is confirmed on the target Forever client before the runtime scope is closed.
