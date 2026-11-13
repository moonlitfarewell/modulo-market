# ModuloMarket Title Strip and Tab Separation 0.9.4

## Intent
Match the proportions of Blizzard's default large-window title bars while keeping the ModuloMarket title centred. Remove the thin vertical separators between adjacent tabs without flattening the tabs or removing their top/bottom accents.

## Implementation
- Native `TitleBg` height: 38 px (when supported by the template region).
- Title anchor: centred at frame top -19 px.
- Title text region: 280x24 px.
- Remove tab `marketLeft` and `marketRight` one-pixel textures.
- Preserve tab background, top/bottom strokes, highlight and selected marker.
- Preserve tab strip perimeter and all content-panel borders.

## Scope
No data, scan, calculation, recipe, gathering, SavedVariables, dependency or non-UI behavior changes.

## Validation
Focused tests 4 PASS; full suite 263 PASS / 61 unchanged historical failures vs 0.9.3; zero new failing IDs; Lua syntax 9/9 PASS. Forever runtime acceptance NOT RUN for 0.9.4.
