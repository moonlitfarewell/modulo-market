# ModuloMarket Outer Window Chrome Refinement 0.9.2

## Goal
Remove the decorative border treatment around the outside of the main ModuloMarket window while preserving the borders belonging to the content inside it.

## Implementation
- Hide the frame template's `NineSlice`, `Inset`, `TitleBg` and `TopTileStreaks` regions when available.
- Keep the `BasicFrameTemplateWithInset` frame, title text and functional close control.
- Remove the custom full-window `outer` bevel.
- Preserve the title plaque and all internal panels, tabs, table headers, filters, dropdowns, inspector cards and history borders.

## Scope
Visual-only main-window chrome change. No market logic, scanning, recipe/gathering data, SavedVariables, dependencies or parent MODULO changes. The 0.9.1 dropdown lifecycle fix is unchanged and player-confirmed working.

## Evidence and acceptance
The player screenshot and explicit confirmation establish that 0.9.1 dropdowns work on Forever 1.60.1 build 70938. Runtime acceptance of the 0.9.2 chrome change is NOT RUN. The next in-client check must confirm the outer border is gone while all inner borders and functional title/close controls remain.
