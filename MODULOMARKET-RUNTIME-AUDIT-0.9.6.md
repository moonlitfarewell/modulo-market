# MODULOMARKET RUNTIME AUDIT 0.9.6

## Result
A coordinated visual correction addressing the failed 0.9.5 title-bar result and the user's objection to the repeated embossed treatment. Source implementation and offline validation are complete. Forever runtime acceptance is NOT RUN.

## Player problem and observable result
The 0.9.5 screenshot showed the dark background/content region enlarged, but the actual framed title strip remained visually shallow. The user also found the repeated embossed/bevel styling undesirable. The 0.9.5 edge-to-edge tab spacing was accepted as improved and must be preserved.

Expected player-visible result:
- A clearly taller, separately framed title strip, with “Modulo Market” centred inside it.
- Content begins below the taller title strip without overlap.
- Borders across panels, cards, controls and buttons become flat, single-pixel outlines rather than multi-layer simulated metal bevels.
- Tab buttons remain edge-to-edge with existing selected/hover treatment.
- Internal panel boundaries remain visible.

## Canonical baseline and evidence
- Parent bundle: `ModuloMarket-GitHub-Update-0.9.5.zip`.
- Parent archive SHA-256: `3e521bea3ae4475aea0facd1b5de6407fef85605c311ce412aabbac26673c4e6` (2351061 bytes).
- Parent ZIP CRC: PASS; 191 entries.
- Parent TOC/Core/manifest versions agree at 0.9.5; manifest lists 191/191 files.
- User-provided screenshot is FOREVER OBSERVED evidence for the 0.9.5 layout only. It demonstrates the enlarged content/background, shallow-looking title frame and accepted zero-gap tab row. It is not evidence for 0.9.6.
- 0.9.5 source evidence: `TitleBg` was 44px, the title text anchored at -27px, and a 16px generic content shift was applied. No separate flat outline was drawn around the title region.
- 0.9.5 source evidence: `AddBevelBorder` drew eight edge textures, including dark shadow edges, gold/bright edges, shaded edges and special corner highlights. It was used across panels, cards, controls and buttons.
- 0.9.5 source evidence: major panel edges added extra top sheen and bottom shadow; panel headers and inspector headers added highlight/glow layers.
- Child-specific PROJECT-START-HERE, WORKFLOW, PROJECT-DECISIONS, PROJECT-PROGRESS, QA and SOURCE-REVIEW-LEDGER are absent from the supplied child bundle. Missing project history has not been reconstructed.

## Changes in 0.9.6

### Actual title frame
- Increase native `TitleBg` height from 44px to 56px and explicitly retain its top-left/top-right anchors.
- Add a visible, flat, single-pixel outline around the 1444x56 title region. This frames the title area itself rather than only enlarging a dark background surface.
- Centre the title at -33px within the taller region.
- Increase main frame height from 882px to 894px and shift addon-owned content down from 16px to 28px, preserving footer clearance and avoiding overlap.
- Keep native Blizzard frame chrome and close button in place.

### Flatter visual system
- Replace the shared multi-layer bevel helper with four one-pixel edges using one restrained style colour per border.
- Remove simulated dark shadow, bright highlight, shade and corner emboss layers from all surfaces using the helper.
- Major panel outlines remain; remove extra panel top-sheen and bottom-shadow textures.
- Remove extra header upper-glow and inspector header-glow layers; retain the muted header fills and single separator rules.
- Button/control borders now use the same flat-outline system. Existing fills, text, hover and click behavior are preserved.

### Preserved
- Zero-gap tabs, their top/bottom strokes, backgrounds, hover treatment and selected marker.
- All internal panel/card/control boundaries, now flat rather than embossed.
- Six tabs; My Crafts remains absent.
- 0.9.1 dropdown popup lifecycle correction.
- Market data, recipe/gathering data, calculations, auction scan, SavedVariables, dependencies and parent MODULO are unchanged.

## Ownership, dependencies and risk
- ModuloMarket owns all changed presentation.
- No new API, dependency or client behavior assumption.
- Main risk is visual: target-client texture layering/anchor behavior may differ from offline source assertions. Runtime screenshot acceptance is required.
- No market or data risk is expected because only `MarketUI.lua`, release metadata, tests and documentation changed.

## Validation
- Focused 0.9.6 visual regression tests: 13 PASS.
- Full suite: 272 PASS / 61 historical failures.
- Direct comparison against exact 0.9.5 parent bundle: same 61 failing test IDs; zero new failures.
- Lua syntax: 9/9 PASS.
- Fresh extraction, manifest inventory, ZIP CRC and fresh-extraction suite: PASS (final measured values below).
- Forever runtime acceptance for 0.9.6: NOT RUN.
- 0.9.5 screenshot is FOREVER OBSERVED for 0.9.5 only.

## Acceptance and exit criteria
On WoW Forever 1.60.1 build 70938:
1. Confirm the title bar's actual frame outline is taller, not merely a larger dark background.
2. Confirm title text is centred vertically and horizontally in that outlined title area.
3. Confirm content/status area begins below the title bar without overlap or clipping.
4. Confirm panel/card/control/button borders are visually flat and restrained, without the former stacked bright/dark bevel effect.
5. Confirm the six tabs remain flush, with no vertical gap/separator.
6. Confirm dropdowns still close with the main window and remain usable after reopening.
7. Confirm buttons, filters, sorting and selection remain functional.

Until those checks pass in the target client, 0.9.6 is source-implemented and offline-tested, not FOREVER VERIFIED.

- Focused tests: 13 PASS.
- Full suite: 272 PASS / 61 historical failures. The 61 failing test IDs exactly match the 0.9.5 parent baseline; zero new failing IDs.
- Lua syntax: `texluac -p` on all 9 addon Lua files — 9/9 PASS.
