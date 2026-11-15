# Modulo Market 0.12.10 — Native Blizzard Settings Appearance Slice

**Date:** 2026-11-15  
**Parent source:** `moonlitfarewell/modulo-market` `main`, commit `e34bbc26bee6185ccd806f8c580b54aba717c33a`  
**Parent bundle:** `modulo-market-0.12.9-docs-reconciled.zip`  
**Reference:** supplied `Modulo-ItemSlot-0.6.1.zip`

## Player problem and result

Modulo Market's settings page was a manually positioned canvas with custom buttons/dropdowns and custom scroll behavior. Modulo ItemSlot 0.6.1 uses Blizzard's native vertical AddOn Settings layout, which the user identified as the preferred visual style.

Version 0.12.10 moves Market's settings to the same native vertical-layout pattern. Controls are stacked and styled by Blizzard, use native searchable settings controls, and no longer draw a custom scrollable panel.

## Evidence inspected

- ItemSlot `AddOns/ModuloItemSlot/Settings.lua`: `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterProxySetting`, `Settings.CreateCheckbox`, `Settings.CreateSlider`, `Settings.CreateDropdown`, `Settings.CreateControlTextContainer`, and section headers through `CreateSettingsListSectionHeaderInitializer`.
- Market 0.12.9 `AddOns/ModuloMarket/Theme.lua`: existing canvas settings panel and appearance/theme setters.
- Market `Core.lua`, TOC, `TurnInData.lua`, README, current theme harness/tests and 0.12.9 manifest.
- Blizzard Settings API reference: vertical layout categories auto-stack supported controls and provide native AddOn Settings integration/search; current proxy-setting signatures are supported from 11.0.2 onward. See cited sources below.

## Implementation

- Replaced the Market canvas panel with `Settings.RegisterVerticalLayoutCategory("Modulo Market")`.
- Registered appearance/style/palette dropdowns with `Settings.RegisterProxySetting` and `Settings.CreateDropdown`.
- Preserved the Blizzard colour picker and exposed it through native Settings button initializers for both independent custom accents. The existing cancel/restore behavior and SavedVariables tables remain intact.
- Added native section headers and native Settings action-button initializers for opening Market, Browse Scan/debug, and resetting the selected window position.
- Kept the existing theme setter functions and migration behavior. Theme changes still call the same presentation/theme refresh functions.
- Fails visibly with a player-facing message if the native vertical-layout API is unavailable; no legacy canvas panel or silent fallback is registered.
- No new addon dependencies. No Market data, scan, Replicate, persistence, profession, or calculation code changed.
- Version synchronized to 0.12.10 in Core, TOC and TurnInData; manifest updated.

## Acceptance evidence

- Command: `python -m pytest -q --tb=short tests/test_modulomarket_0_12_10_settings.py tests/test_modulomarket_0_11_2_themes.py` — **20 passed** (5 new settings tests plus 15 current theme/version/UI tests).
- Command: `texlua tests/settings_0_12_10_harness.lua AddOns/ModuloMarket/Theme.lua` — **17 checks passed**.
- The existing theme and Modern UI Lua harnesses also ran through the targeted pytest invocation.
- Lua syntax: `texlua` compile-only `loadfile` check across all 14 addon Lua files — **14/14 passed**.
- Patch ZIP CRC test: **PASS**; fresh extraction: **PASS** (13 ZIP entries including patch manifest).
- Release manifest: **296 paths**, **295 declared Git blob hashes**, 0 missing paths and 0 hash mismatches.
- In-client Settings appearance and control interaction: **NOT RUN**.
- Forever runtime: **NOT RUN**.
- Retail/Mainline runtime: **NOT RUN**.

## Compatibility and risk

- Uses the same vertical-layout API family as the supplied ItemSlot settings implementation. ItemSlot's code is a source reference, not proof of Market's runtime behavior.
- Settings proxy values use string dropdowns. The existing Blizzard colour picker edits only the stored custom accent, not the currently active class/classic palette.
- Native Settings button initializers are added when `CreateSettingsButtonInitializer` is exposed by the client. Slash commands remain available if a client does not expose the button initializer.
- The custom colour picker remains a Blizzard-owned dialog launched from native Settings buttons; the custom panel buttons/dropdowns are gone.
- The legacy fallback is intentionally minimal and is not a substitute for validating the target client API.

## Ownership and dependencies

- Modulo Market owns its Settings category and its theme preferences.
- Blizzard owns the Settings UI controls/layout API.
- Modulo ItemSlot is a separate optional sibling addon and is only the visual/API reference; Market does not depend on ItemSlot.
- No optional addon dependency was added.

## Exit criteria

- [x] Native vertical-layout category registered.
- [x] Appearance and theme selectors use native dropdown controls.
- [x] Both custom accents remain independently editable/persistent.
- [x] Existing Market/Browse/reset actions are represented as native Settings buttons where supported.
- [x] No data/scanner/Replicate logic changed.
- [x] Focused tests and mock Settings harness pass.
- [ ] Player confirms Settings page appearance and tests controls in the target Forever client.
- [ ] Retail/Mainline compatibility is not claimed.

**Status:** source slice PASS; player-visible runtime acceptance remains NOT RUN. This is not a 1.0.0 approval.

## External API reference

Blizzard Settings API documentation (Warcraft Wiki):
- Settings API: https://warcraft.wiki.gg/wiki/Settings_API
- Creating a settings menu: https://warcraft.wiki.gg/wiki/Creating_a_settings_menu

The vertical layout API automatically stacks supported controls in a Blizzard-style list. The ItemSlot code supplied by the user demonstrates the same vertical-layout/proxy-setting approach in this project.
