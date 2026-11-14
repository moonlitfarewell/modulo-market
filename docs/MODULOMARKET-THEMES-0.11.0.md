# Modulo Market themes — 0.11.0

## Player problem and observable result

Modulo Market had one established visual presentation. Players requested an optional modern dashboard appearance inspired by contemporary gaming interfaces, without removing or renaming the existing presentation.

0.11.0 adds two selectable themes:

- **Blizz-like** — the existing Modulo Market appearance and original colour values.
- **Modern** — dark charcoal surfaces, restrained accent-coloured borders and highlights, and configurable accent palettes.

The addon settings page includes an Open Modulo Market (/mm) button, a theme selector, and Modern-only palette controls for Dark (grey tone), Class (the logged-in character's WoW class colour), and Custom (an arbitrary RGB accent chosen through the client colour picker).

## Source evidence and design references

- Baseline: user-provided `ModuloMarket-GitHub-Update-0.10.4.zip`; ZIP CRC passed and the archive contained 220 files.
- `Core.lua` already registered `/mm` as the main market toggle. The command remains unchanged.
- `ModuloMarket.toc` targets Interface 16001 and declares only the existing required MODULO dependency and optional LibProfessionDB dependency.
- `MarketUI.lua` uses a single UI frame and local texture/font construction helpers; the theme implementation registers theme-sensitive textures and font strings so a theme change can repaint already-created interface elements.
- The supplied `AddOns.zip` was inspected. `EllesmereUIOptions/EllesmereUI_Widgets_Color.lua` contains reusable colour-swatch/picker patterns; `Polestar/Theme/Widgets.lua` uses `ColorPickerFrame:SetupColorPickerAndShow` with RGB callbacks and cancel restoration; `Modulo/Settings.lua` and `EllesmereUI.lua` show native `Settings.RegisterCanvasLayoutCategory` registration with compatibility branches. No code or runtime dependency on those addons was added.

## Implementation

- Added `AddOns/ModuloMarket/Theme.lua`, loaded immediately after `Core.lua` and before `MarketUI.lua`.
- Added `ModuloMarketDB.theme`, `ModuloMarketDB.modernPalette` and `ModuloMarketDB.customAccent` defaults and validation. Existing SavedVariables are retained; no schema migration or destructive reset is performed.
- Added the addon settings category with an Open Modulo Market button, Blizz-like/Modern selector, Modern palette selector and custom RGB colour swatch/picker.
- Uses `Settings.RegisterCanvasLayoutCategory` / `Settings.RegisterAddOnCategory` when available, with `InterfaceOptions_AddCategory` fallback.
- The custom picker supports the target client's `SetupColorPickerAndShow` API and a guarded legacy callback fallback. Cancel restores the previous persisted accent.
- Modern Dark uses a neutral grey accent; Class resolves the current character token against `CUSTOM_CLASS_COLORS` or `RAID_CLASS_COLORS`; Custom uses the saved RGB value.
- The theme layer re-paints registered textures and font strings immediately when a setting changes. Newly-created market surfaces use the current palette.
- Blizz-like resolves each registered surface to its original literal colour, preserving the existing visual treatment.
- The product remains named **Modulo Market**. “Blizz-like” and “Modern” are theme labels only.

## Ownership, dependencies and non-goals

- Owner: standalone optional ModuloMarket addon.
- No changes to parent MODULO source or version.
- No dependency on EllesmereUI, Polestar, Auctionator or any addon in `AddOns.zip`.
- No changes to pricing, auction acquisition, scanning, market snapshots, item/recipe/turn-in data, sorting, filters, history calculations, or profession capture.
- `/mm` continues to open/toggle the main market window. Existing `/mmscan`, `/mmcompat`, diagnostics and version commands remain.
- No new protected actions or automated market scans.

## Risks and limits

- The settings category and client colour-picker callback lifecycle have not been exercised in the Forever client.
- Modern styling covers the addon-owned primary panels, tabs, table selection, dropdown surfaces, inspector surfaces and key headings. Blizzard's native BasicFrameTemplateWithInset chrome and a few semantic status colours remain native/semantic; the first pass is not a total replacement of every Blizzard texture.
- Class accent is resolved when the palette is applied. If the player changes class during the same session (normally by relogging), the Class palette is refreshed when settings are reapplied or the UI is loaded again.
- A colour picker may be unavailable on an unusual client build; the control fails closed with a chat message and does not overwrite the stored colour.

## Acceptance and exit criteria

1. Existing users with no theme fields default to Blizz-like.
2. Blizz-like preserves the prior visual colours and layout.
3. Modern switches the addon-owned presentation to charcoal surfaces and accent-coloured borders/highlights.
4. Dark, Class and Custom palettes change the Modern accent without changing the selected theme.
5. Custom RGB values persist across `/reload`; cancelling the picker restores the previous colour.
6. Settings page button opens the main Modulo Market window; `/mm` remains functional.
7. Market calculations, scanner, saved market data and all tab behavior remain unchanged.
8. No new dependency on other addons.
9. Forever runtime acceptance captures settings registration, all theme choices, persistence, and representative tabs before marking the feature runtime verified.
