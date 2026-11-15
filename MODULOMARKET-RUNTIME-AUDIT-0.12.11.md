# Modulo Market 0.12.11 — Settings appearance refinement audit

**Date:** 2026-11-15  
**Parent source:** 0.12.10 settings appearance slice, itself based on 0.12.9 commit `e34bbc26bee6185ccd806f8c580b54aba717c33a`  
**Scope:** `AddOns/ModuloMarket/Theme.lua`, version metadata, focused settings tests/harness, README and manifest. No market/scanner/Replicate/profession behavior changes.

## Player problem and result

The first native Settings conversion still produced clipped labels and left inactive appearance controls looking available. This slice shortens the visible labels and action text, makes the Blizz-like and Modern child selectors use parallel names, and parents each child selector to the master Market appearance selector. Custom-colour buttons are parented to their respective child style selector and enabled only for the Custom colour selection.

## Ownership and design

Blizzard owns the native Settings presentation. Modulo Market supplies proxy settings and parent predicates through the Blizzard Settings initializer API. Modulo ItemSlot 0.6.1 was inspected as the project-local reference for `Settings.RegisterVerticalLayoutCategory`, `Settings.RegisterProxySetting`, and native controls. Market remains independent of ItemSlot.

The implementation uses `SetParentInitializer` for native dependent-control state. The master selector is `Market appearance`; child selectors are `Blizz-like style` and `Modern style`. Custom colour buttons use the same child-parent pattern.

## Changes

- Version advanced to 0.12.11 in TOC, Core and TurnInData.
- Shortened action text to `Open Market (/mm)`, `Open Browse Scan / Snapshot`, and `Reset window position`.
- Both child selectors now use parallel `... style` naming.
- Blizz-like style is disabled unless Market appearance is Blizz-like.
- Modern style is disabled unless Market appearance is Modern.
- Each custom-colour button is disabled unless its own style is Custom colour.
- Preserved colour picker and SavedVariables behavior.

## Verification

- `python -m pytest -q --tb=short tests/test_modulomarket_0_12_11_settings.py`: **7 passed**.
- `texlua tests/settings_0_12_11_harness.lua AddOns/ModuloMarket/Theme.lua`: **20 checks passed**.
- `texlua` compile-only `loadfile` check across all addon Lua files: **14/14 passed**.
- Manifest inventory and Git-blob hashes are refreshed for the new 0.12.11 source tree.
- Full ZIP CRC/fresh extraction and changed-file equality checks are recorded in the handoff validation.

## Compatibility and runtime evidence

The Blizzard Settings API source documents `SetParentInitializer` as the native parent/child mechanism. The local harness verifies the expected parent relationships and predicates, but cannot render Blizzard's disabled styling or prove the live settings pane layout.

**Forever runtime: NOT RUN. Retail/Mainline runtime: NOT RUN.** Player acceptance remains required for visual clipping, disabled appearance, search, dropdown operation, colour picker interaction and settings persistence.

## Risks / open checks

- Client-specific Settings implementation differences may affect `SetParentInitializer` behavior or visual disabled state; validate on the target Forever client.
- The screenshot is one client presentation/scale; the shortened labels should still be checked at the user's UI scale.
- The source harness proves predicates and registration, not actual UI rendering.

## Exit

The source slice is complete and statically tested. Keep runtime acceptance open until the player confirms that inactive child controls visibly grey out, active controls remain usable, and no labels or buttons truncate in the target client.
