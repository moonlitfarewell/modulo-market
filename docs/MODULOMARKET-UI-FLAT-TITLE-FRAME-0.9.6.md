# ModuloMarket Title Frame and Flat Visual System 0.9.6

## Design direction
Move closer to Blizzard's default large-frame language: a properly framed title region, dark restrained surfaces, simple one-pixel outlines and clear hierarchy. Avoid repeatedly simulating raised metal edges on every component.

## 0.9.6 changes
- Native title background height 56px with explicit anchors.
- Flat 1px outline around the title strip itself.
- Title centred at -33px.
- Main frame height 894px; content shift 28px for title clearance.
- Shared border helper now produces four flat 1px edges in restrained per-style colours.
- Remove simulated shadow/highlight/shade/corner bevel layers.
- Remove extra panel sheen/bottom shadow and header/inspector glow layers.
- Keep the 0.9.5 zero-gap tabs and their selected/hover states.
- Keep all inner panel/card/control borders as flat outlines.

## Scope
Presentation-only. No market data, recipes, gathering, auction scanning, formulas, SavedVariables, dependencies or parent MODULO changes.

## Validation
Focused tests 13 PASS; full suite 272 PASS / 61 unchanged historical failures versus 0.9.5; zero new failure IDs; Lua syntax 9/9 PASS. Forever runtime acceptance NOT RUN for 0.9.6.
