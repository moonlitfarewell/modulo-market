# Modulo Market 0.11.0 — Themes capability audit

**Status:** SOURCE IMPLEMENTED · FOCUSED TESTS PASS · FULL SUITE HAS ZERO NEW FAILING TEST IDS VS 0.10.4 · RETAIL RUNTIME NOT RUN · FOREVER RUNTIME NOT RUN

## Canonical baseline and provenance

- Sole baseline: user-provided `ModuloMarket-GitHub-Update-0.10.4.zip`.
- Baseline SHA-256: `6187dedd7294eb73c6492d20acdbde71f1350487d9c62cb0afee7a695e5b0781`.
- Baseline size: 2,415,820 bytes.
- ZIP CRC check: PASS (`testzip() == None`).
- Baseline archive file count: 220.
- No other ModuloMarket source version was mixed into this slice.
- Parent MODULO package metadata remains the 1.0.48 source recorded by the child manifest; parent addon is not modified.

## Player problem and observable result

Players want a modern visual option while retaining the established Modulo Market appearance. 0.11.0 adds Blizz-like and Modern theme selection through an addon settings category. Modern adds Dark, Class and Custom accent palettes. `/mm` remains the main window command and a settings-page button provides the same action.

## Evidence and counter-evidence

- Baseline source confirms `/mm` already toggles `MM.MarketUI` and was not replaced.
- Baseline TOC targets Interface 16001, depends on MODULO and optionally LibProfessionDB.
- Baseline MarketUI builds a single long-lived main frame with hand-authored colour textures and font strings.
- Supplied AddOns.zip was inspected for established settings and picker patterns: EllesmereUI colour widgets, Polestar colour picker callback/cancel pattern, and MODULO native settings category registration with compatibility fallback.
- Counter-evidence/limit: source patterns and mocked/offline tests do not prove that the exact Forever client exposes the same settings registration or colour picker behavior at runtime.

## Competing implementation risks and diagnostics

1. Theme persistence and palette resolution may be correct in source but fail during addon load order/settings-page registration. Distinguishing diagnostic: install on Forever, open Blizzard AddOns settings, verify the Modulo Market category and controls, select each mode, `/reload`, and verify persistence.
2. Theme registry may repaint existing textures but miss a visual element created outside the registered helpers. Distinguishing diagnostic: compare all six tabs before and after theme changes, including Turn-Ins, dropdown popups, selected rows and inspector panels; report any surface that retains the old palette.

The source uses the existing addon load sequence: Core initializes SavedVariables on ADDON_LOADED; Theme.lua is loaded after Core and before MarketUI; settings category registration occurs on PLAYER_LOGIN.

## Implementation scope

- Added `Theme.lua` with theme/palette defaults, class-colour resolution, custom RGB storage, semantic palette roles, registered texture/font recolouring and settings category.
- Added settings-page Open Modulo Market (/mm) button, Blizz-like/Modern dropdown, and Modern-only Dark/Class/Custom palette selector.
- Added a client colour picker with cancel restoration and guarded legacy fallback.
- Integrated theme-aware texture/font helpers into major addon-owned surfaces: buttons/dropdowns, tabs, panel surfaces/headers, row shading/selection, inspector headers/dividers and history baseline/bars.
- Blizz-like colour fallbacks are the existing source literals.
- Version advanced together to 0.11.0 in addon code, TOC, TurnInData, README and JSON manifest.
- Market calculations, scans, filters, item/recipe/turn-in data and parent MODULO remain unchanged.

## Ownership and dependencies

- Owner: ModuloMarket.
- No required or optional addon dependency added.
- EllesmereUI/Polestar/Modulo settings and picker implementations were references only; their code was not copied as a dependency.
- Parent MODULO remains unchanged.

## Risks and gaps

- Exact Forever settings-page registration and ColorPickerFrame callback behavior remain unverified.
- Native Blizzard frame chrome is retained; Modern is a first complete addon-owned visual pass, not a replacement of every Blizzard template texture.
- The theme registry and custom colour persistence are source/offline tested, not client runtime verified.

## Tests and runtime evidence

- Focused theme + current Turn-In UI regressions: **30 passed**.
- Theme state/palette Lua harness: **12 checks passed** (Blizz-like fallback, Modern mode, Dark/Class/Custom palette resolution, RGB persistence model, registered texture/font repaint).
- Existing Turn-In Lua harness: **9 checks passed**.
- Lua syntax compilation: **12/12 addon Lua files passed** using `texluac -p`.
- Full Python suite: **306 passed / 87 failed / 393 total**.
- 0.10.4 baseline full suite: **294 passed / 87 failed / 381 total**. Exact failing test IDs: **87 unchanged; zero new failing IDs; 12 additional tests pass**.
- Regression assertions for the existing Blizz-like palette were updated to verify their exact original fallback colours through the theme-aware rendering helper.
- Final archive CRC, fresh extraction, manifest inventory, version agreement and SHA-256: see final handoff.
- Retail runtime: NOT RUN.
- Forever runtime: NOT RUN. No FOREVER OBSERVED or FOREVER VERIFIED claim is made for 0.11.0.
- GitHub remote: NOT UPDATED by this pass.

## Exit criteria

1. New install defaults to Blizz-like.
2. Blizz-like retains existing market presentation.
3. Modern Dark/Class/Custom palette changes apply to existing and newly-created addon surfaces.
4. Custom RGB persists across reload; picker cancel restores prior value.
5. Settings-page Open button and `/mm` both open the same main window.
6. No new addon dependency and no market/data behavior changes.
7. Forever runtime acceptance is recorded before runtime closure.
