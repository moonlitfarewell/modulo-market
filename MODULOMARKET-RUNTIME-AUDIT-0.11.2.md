# Modulo Market 0.11.2 — Modern visual defect correction audit

## Result

**FIVE REPORTED PRESENTATION DEFECTS CORRECTED IN SOURCE · OFFLINE TESTS PASS · RETAIL RUNTIME NOT RUN · FOREVER RUNTIME NOT RUN**

This is a focused visual-fix release on top of 0.11.1. The separate Modern window and existing Blizz-like window remain. Market data, calculations and scan behavior are not intentionally changed.

## Canonical baseline and provenance

- Sole baseline: `ModuloMarket-GitHub-Update-0.11.1.zip`.
- Baseline SHA-256: `ca13de95a3e54ce376ee228b567c1d6b0dccb47be50fa26bf11b56ea8e660fd5`.
- Baseline bytes: 2,425,279.
- Baseline ZIP CRC: PASS.
- Baseline archive inventory and `MANIFEST.json` agree: 229 files.
- Baseline `Core.lua`, TOC, `TurnInData.lua`, README and manifest: 0.11.1.
- Parent MODULO provenance remains 1.0.48; no parent MODULO source is changed.
- The 0.11.1 bundle is the only source baseline used for this slice.

## Player problem and observable result

The player supplied Forever-client screenshots and reported:

1. Modern toolbar/dropdown icons render as empty boxes.
2. Checkboxes are difficult to distinguish in dark palettes in both Blizz-like and Modern.
3. Modern rows lost the learned / learnable / unlearnable colour strips.
4. Materials tab helper text overflows the bottom-left panel.
5. Modern Turn-In Required Bundles content is crowded and poorly formatted.

## Root-cause diagnosis and corrections

### 1. Placeholder icon glyphs

- Competing hypotheses: (a) missing/invalid client texture assets; (b) unsupported Unicode symbols in game font strings.
- Diagnostic: inspect the authored UI. Item artwork is supplied through actual textures and appears in the screenshots; toolbar and dropdown affordances are literal Unicode `↻`, `⌕`, `▾` characters. This distinguishes the visible placeholder boxes as unsupported font glyphs, not a missing item-icon pipeline.
- Correction: replace those glyphs with client textures for refresh, search and dropdown arrow. Button text remains visible and actionable.

### 2. Checkbox contrast

- Modern root cause: custom checkbox fill used the dark control surface without a contrasting outline. Added explicit four-edge outlines, accent-aware checked state and hover treatment.
- Blizz-like root cause: native `UICheckButtonTemplate` texture colours were left at their default values in Dark/Class/Custom palettes. The existing native checkbox geometry is retained; normal, pushed, checked, highlight and disabled-check textures are vertex-tinted using the active Blizz-like accent/contrast values. Classic gold is left unchanged.

### 3. Missing profession status identifiers

- Competing hypotheses: (a) profession learning state is no longer calculated; (b) Modern simply does not render the existing status result.
- Diagnostic: `MarketUI.lua` still contains `GetItemCraftMarker`, returning the established green known, yellow learnable and red unavailable/unknown colours. The legacy row renderer calls it; Modern's row renderer did not. This identifies a presentation omission, not a data/calculation regression.
- Correction: expose the same marker function through `UI.GetModernCraftMarker` and render a dedicated 3px Modern row strip on non-Crafts tabs. Selected-row focus remains a separate edge. Crafts tab behavior matches the existing legacy renderer and hides this item marker.

### 4. Materials panel overflow

- Root cause: a 70px helper label started at local y=-652 inside a 660px-tall panel, so its lower 62px extended beyond the panel. The helper duplicated the Data/market context and was removed. Data status remains.

### 5. Required Bundles formatting

- Competing hypotheses: (a) bundle data is incomplete or lost in the Modern adapter; (b) the adapter flattens correctly available data into an unsuitable single text block.
- Diagnostic: `UI.GetModernState().selected` retains the Turn-In row, including `cratePriceCopper`, `bundleAlternatives`, `bestBundle`, reagent quantities, unit prices, line costs and reasons. The old Modern renderer concatenated legacy FontString text into one relationship block. The source proves the structured data is available; the presentation discarded its hierarchy.
- Correction: render the selected crate's data in an independent scrollable Required Bundles panel: crate purchase; each alternative; BEST VALUE; ingredient quantity/name; unit and line costs; explicit missing-price reasons; material subtotal. The Blizz-like inspector is unchanged. Missing prices and insufficient depth remain incomplete, never estimated.

## Scope and ownership

- Owner: standalone ModuloMarket addon.
- Changed runtime files: `MarketUI.lua`, `ModernUI.lua`, `Theme.lua`.
- Version metadata: Core, TOC, TurnInData, README and manifest.
- Added/updated focused tests and harnesses; added implementation documentation.
- Required dependency remains `Modulo`; optional dependency remains `LibProfessionDB`.
- No new addon dependency; no parent MODULO source change.
- No intended changes to auction scanning, pricing calculations, market snapshot, recipe/profession data, Turn-In engine/data, history storage or SavedVariables schema.

## Verification

- Focused regression selection (0.11.2 theme/visual tests plus Turn-In regression tests): **47 passed**.
- Theme checkbox/palette harness: **19 checks passed**.
- Modern UI visual harness: **24 checks passed**.
- Existing Turn-In Lua harness: **9 checks passed**.
- Lua syntax: **13/13 addon Lua files passed** with `texluac -p`.
- Full source suite: **316 passed / 87 failed / 403 total**.
- 0.11.1 baseline run in the same environment: **309 passed / 87 failed / 396 total**.
- Exact failing test IDs: **87 unchanged; zero new failing IDs; seven additional tests pass**.
- Release package contains **232 files**. ZIP CRC, exact manifest inventory, version agreement and fresh extraction are verified in the package handoff.

## Runtime evidence and acceptance

- Forever client (user screenshots indicate build 1.60.1 build 70938): this report supplies the defect evidence; the 0.11.2 fixes have not yet been tested in the client. **FIX ACCEPTANCE NOT RUN**.
- Retail runtime: **NOT RUN**.
- Actual texture asset resolution, native checkbox tinting, Modern scrolling and clipping, all palette states and all tab interactions require user retest.
- No `FOREVER VERIFIED` claim is made. The defects remain pending player-visible acceptance until the user installs 0.11.2 and confirms them.
- GitHub remote write/push: **NOT RUN**; package is delivered locally.

## Acceptance checklist

1. Modern Update Full Market, Browse Scan and dropdown arrows show proper icons, not square glyph placeholders.
2. Checkboxes are legible unchecked/checked in Blizz-like Dark/Class/Custom and Modern Dark/Class/Custom; Classic gold remains intact.
3. Known/learnable/unavailable item status strips are visible in Modern market/economics/materials/history rows and retain selected-row emphasis.
4. Materials and History filter panels no longer have text extending below their borders.
5. Turn-In Required Bundles has readable, scrollable crate/option/ingredient/price/subtotal sections, including BEST VALUE and incomplete states.
6. Search, filters, selection, scrolling, sorting, six tabs, scanner, `/mm`, theme switching and shared data remain functional.
7. No Lua errors or protected-action errors.
