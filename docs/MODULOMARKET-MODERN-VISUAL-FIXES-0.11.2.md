# Modulo Market 0.11.2 — Modern and Blizz-like visual corrections

## Player-visible scope

This slice addresses five Forever-client presentation defects reported against the separate Modern window in 0.11.1:

1. Unsupported toolbar/dropdown Unicode glyphs rendered as square placeholders.
2. Low-contrast unchecked checkbox states in Modern and non-classic Blizz-like palettes.
3. Missing learned / learnable / unavailable craft status strips in Modern item rows.
4. Filter-panel helper text extended below the Materials panel boundary.
5. Turn-In Required Bundles content was flattened into one dense text block.

## Root causes and corrections

- Toolbar and dropdown affordances used the Unicode characters `↻`, `⌕`, and `▾` in game font strings. The Forever client rendered these glyphs as empty boxes. They are replaced with client texture assets (`UI-RefreshButton`, `UI-Searchbox-Icon`, and the scrollbar down-arrow texture); text remains the fallback label.
- Modern's custom checkboxes had a dark fill but no contrasting outline. They now have explicit four-edge outlines, accent-aware checked states and hover states. Existing Blizz-like `UICheckButtonTemplate` controls retain their Blizzard geometry, but the existing normal/pushed/checked/highlight/disabled textures are vertex-tinted for Dark, Class and Custom Blizz-like styles. Classic gold remains unchanged.
- `MarketUI.lua` already had `GetItemCraftMarker`, returning the existing green (known), yellow (learnable) and red (unlearnable/unknown) signals. Modern did not call it. A narrow accessor exposes the same function, and Modern rows now render the 3px marker except on the Crafts tab, matching the legacy UI behavior. Selected-row focus remains a separate edge.
- The Materials/History helper hint began at local y=-652 with a 70px height in a 660px panel, extending 62px beyond the panel. It was redundant with the Data status and is removed rather than squeezed into the footer.
- Required Bundles previously concatenated the legacy FontString left/right text into one relationship block. Modern now renders crate purchase, each material option, BEST VALUE, ingredient quantity/name, unit price, line cost, incomplete price reasons and subtotal as individual rows in a dedicated scrollable panel. The legacy Blizz-like bundle inspector is unchanged.

## Ownership and scope boundaries

- Owner: standalone ModuloMarket addon.
- Changed presentation files: `MarketUI.lua`, `ModernUI.lua`, `Theme.lua`.
- Version metadata: Core, TOC, TurnInData, README and manifest.
- Added focused regression tests and this documentation/audit.
- No parent MODULO source changed. No new addon dependencies.
- No pricing engine, auction snapshot, scanner, recipe/profession data, Turn-In source data, calculation or SavedVariables schema changes.

## Acceptance criteria

- No toolbar/dropdown placeholder glyph boxes; real client textures render in Forever.
- Unchecked and checked checkboxes are visibly distinguishable in Modern Dark/Class/Custom and Blizz-like Dark/Class/Custom; Classic gold remains visually unchanged.
- Modern item rows show the same known/learnable/unlearnable colour semantics as Blizz-like, without replacing selection highlight.
- All Materials/History filter-panel content stays within the panel.
- Required Bundles is independently scrollable and presents each alternative in readable sections; missing prices and insufficient depth remain explicitly incomplete.
- All six tabs and shared market state remain unchanged.

## Verification and limits

Offline tests and Lua harnesses verify source paths, row-marker calls, palette refresh hooks, texture-based controls, bundle rendering and scroll behavior. They do not prove the exact Forever UI texture assets, native checkbox texture tinting, or live clipping/scroll behavior. Forever runtime acceptance remains required. Retail runtime was not run.
