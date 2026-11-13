# ModuloMarket 0.8.4 — consolidated Dark Foundry visual redesign

## Decision and player outcome

**Adopted direction:** The user approved a consolidated redesign of the first five visual areas in one 0.8.4 pass, followed by a later 0.8.5 refinement pass if needed. The approved proof-of-concept remains guidance, not a pixel-perfect rule. The existing six-tab product and its useful controls remain the design baseline.

**Player problem:** The 0.8.3 All Items screen renders on Forever 1.60.1 build 70888, but it still looks flatter and less deliberately framed than the approved Dark Foundry proof of concept. Its title plaque is a thin-lined rectangle, outer/panel borders have little depth, navigation tabs are flat, dropdowns inherit generic button skins, the table header has weak separation, and the inspector cards lack a consistent layered frame treatment.

**Observable result:** One coherent dark/bronze/gold visual language across the header and outer window, six navigation tabs, left filter panel, centre market table and right inspector. Existing controls and data remain where they are; this is a presentation pass, not a market feature or data correction.

## Evidence basis and counter-evidence

- The current child repository `moonlitfarewell/modulo-market` `main` identifies version 0.8.3. The 0.8.3 GitHub `MANIFEST.json`, README, `MarketUI.lua`, `Core.lua`, TOC and audit were fetched and checked against the supplied 0.8.3 source extraction; Git blob SHA values match for the four compared text files.
- The 0.8.3 bundle contains 154 manifest-listed files and its parent provenance points to MODULO 1.0.48 (`MODULO-Project-Source-1.0.48.zip`, project file ID `file_000000001a2482128af00913b054f6f9`, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`).
- The 0.8.3 source already owns all relevant presentation in `AddOns/ModuloMarket/MarketUI.lua`: `CreateUI`, `CreateDropdown`, `AddButton`, panel/card construction, row virtualization, selected-item inspector and `SetTab` styling.
- The supplied 0.8.3 Forever screenshot confirms the All Items window rendered on WoW Forever 1.60.1 build 70888. It does not establish the 0.8.4 visual result or every control/tab behavior.
- The supplied mockup demonstrates richer frame depth, a plaque title, stronger tab selection, framed filter/table/inspector surfaces and clearer table hierarchy. The user explicitly said the mockup is guidance, not a mandatory pixel copy. The existing Data card placement and six-tab structure are therefore retained rather than moving data status into the header or inventing a new tab.
- Existing UI notes 0.5.6–0.6.2 establish the three-column workspace, Dark Foundry intent, panel separation, tooltips/opacity/scrolling behavior and the need to preserve tab-specific layouts. They do not require the mockup's exact geometry.

## Scope and implementation

### 1. Header and outer frame

- Widen and layer the existing title plaque with a dark inset surface, bronze/gold bevel and restrained corner accents.
- Add a dark/gold header rail behind the existing market metadata, scan state, actions, status line and opacity control.
- Add a layered outer frame edge inside the existing 1460 × 850 logical frame.
- Keep scan status tied to `Replicate.GetState()` and the existing `UI.RefreshActions()` state logic. No percentage/progress value is fabricated; the current exposed scan state does not provide a stable progress percentage.

### 2. Navigation

- Keep exactly six tabs: All Items, Economics, Crafts, Materials, Low Supply and History.
- Add state-aware bevel edges and more deliberate selected/unselected fills. Preserve click handlers, tooltips, per-tab filters, selection memory and active-tab semantics.
- Do not reintroduce My Crafts.

### 3. Left filter panel

- Add shared dark/gold bevel treatment to existing action buttons and custom dropdown controls; recolor dropdown arrows and improve control label contrast.
- Strengthen the Options divider/heading and Data card surface/frame.
- Preserve search, profession, Item role, Item Types, quick-filter controls, Crafting Scope and all existing coordinates/semantics.

### 4. Centre market table

- Add a distinct column-heading band and clearer gold rule.
- Increase alternating row contrast and add a restrained gold selected-row wash/accent.
- Increase item icon size from 18 to 20 logical pixels.
- Preserve the six existing tab-specific column models, sort behavior, 24px row height, 25-row virtual pool, scroll frame and market calculations.

### 5. Right inspector

- Add inset card surfaces, layered bronze/gold bevels and stronger card-heading treatment.
- Add a dark/gold mount around the existing 48px selected-item icon.
- Preserve selected item details, recipe/gathering relationships, scroll behavior, history points/graph and all source/evidence semantics.

## Ownership and boundaries

- Owner: optional child addon ModuloMarket; `MarketUI.lua` owns its presentation.
- Parent MODULO 1.0.48 remains unchanged. ModuloMarket continues to depend on MODULO; MODULO does not depend on ModuloMarket.
- No Auctionator, ProfessionMaster, Polestar, or other specialist addon dependency is added.
- No new Blizzard APIs, item data, recipe data, market calculations, scan semantics, SavedVariables keys or external assets are introduced. Visual surfaces use the existing frame/texture API and existing client-side font/button templates.

## Risks and unknowns

- The exact layered texture draw order and bevel appearance must be confirmed on Forever; source tests cannot prove the in-client rendering result.
- Frame-level overlay borders must not obscure close/drag controls, text, dropdowns, scrollbars or tooltips.
- Increased row icon size and selected-row accents must remain within the existing row height and not interfere with click/hover targets.
- Font and frame geometry may render differently at other UI scales/resolutions; the existing scale-fit behavior is retained.
- No claim is made that the approved mockup is matched pixel-for-pixel.

## Acceptance

1. Open 0.8.4 on Forever 1.60.1 build 70888 at the user's normal resolution/UI scale; confirm the title plaque and outer frame are visible and correctly layered.
2. Confirm metadata, scan state, action buttons, status and opacity are legible and do not overlap.
3. Confirm all six tabs render with a clear active state and remain clickable; no extra tab appears.
4. Confirm filter controls, dropdown menus, checkboxes, Data card and Crafting Scope are legible, clickable and non-overlapping.
5. Confirm table heading band, row shading, selected-row accent, item icons and scroll behavior remain aligned; verify 24px rows and 25-row pool remain intact.
6. Confirm inspector cards, item icon mount, relationships scrolling and history graph remain inside the right panel.
7. Spot-check tooltips, dropdown popup strata, close button, dragging and whole-window opacity.
8. Switch through all six tabs; verify each tab's own filters, columns, sort and selected-item detail still work.
9. Check for Lua errors, missing controls, taint warnings, clipping, z-order defects or performance regressions.

**Forever runtime status for 0.8.4:** NOT RUN. The supplied 0.8.3 screenshot is retained as prior visual runtime evidence only.
