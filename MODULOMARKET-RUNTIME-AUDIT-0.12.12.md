# Modulo Market 0.12.12 — settings and minimap refinement audit

**Date:** 2026-11-15  
**Parent:** 0.12.11 settings refinement slice  
**Scope:** Settings label, minimap launcher click handling, version metadata, focused tests and docs. No market pricing, Replicate, scanner, profession or persistence logic changes.

## Player problem / result

The player identified one remaining truncated settings label and requested a right-click shortcut from the minimap button to the Modulo Market settings category.

- `Open Browse Scan / Snapshot` is now **Diagnostic window**.
- Minimap left-click continues to toggle/open Modulo Market.
- Minimap right-click opens the native Modulo Market Settings category.
- Tooltip now documents left-click, right-click and drag.
- Right-click refuses to open settings during combat and reports when the category is not yet registered.
- Drag-to-reposition and saved minimap angle are unchanged.

## Evidence and implementation

The minimap button is created in `MarketUI.lua`, registers click events, and previously only registered `LeftButtonUp`. It now registers both `LeftButtonUp` and `RightButtonUp`. The right-click handler obtains `MM.Theme.settingsCategory` and uses Blizzard's `Settings.OpenToCategory(category:GetID())`, matching the project-local pattern in Modulo ItemSlot 0.6.1 (`MIS.OpenSettings`). It does not require or depend on ItemSlot.

## Ownership / compatibility

Blizzard owns the Settings navigation API. Modulo Market owns the click routing and settings-category reference. This is optional-addon behavior; no dependency on Modulo ItemSlot is introduced.

## Tests and checks

- `python -m pytest -q --tb=short tests/test_modulomarket_0_12_12_settings.py`: **9 passed**.
- `texlua tests/settings_0_12_12_harness.lua AddOns/ModuloMarket/Theme.lua`: **20 checks passed**.
- Lua syntax compile-only `loadfile` check across all addon Lua files: pending final package verification.
- Patch ZIP CRC and fresh extraction: pending final package verification.

The Python tests assert both registered mouse buttons, the right-click Settings.OpenToCategory path, preservation of left-click toggle, tooltip text, combat guard and category-not-ready handling. The settings harness covers the native category and dependent appearance controls.

## Runtime evidence

**Forever runtime: NOT RUN. Retail/Mainline runtime: NOT RUN.** Source tests cannot confirm actual right-click dispatch, protected-action behavior, settings navigation, tooltip rendering or visual clipping on the target client. Player acceptance remains required.

## Risks / exit

- Blizzard client may differ in click dispatch or Settings navigation; test in the target Forever build.
- Verify right-click does not interfere with dragging and left-click still toggles the Market.
- Verify combat guard is silent/clear and no ADDON_ACTION_FORBIDDEN occurs.

This source slice is complete when the player confirms: the minimap button left-click still opens Market; right-click opens Modulo Market settings; dragging still repositions; and the settings page shows **Diagnostic window** without truncation.
