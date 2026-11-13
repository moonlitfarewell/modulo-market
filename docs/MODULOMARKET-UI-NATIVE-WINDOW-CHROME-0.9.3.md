# ModuloMarket Native Window Chrome 0.9.3

## Design intent
Use the Blizzard default-frame visual language shown in the user's Map & Quest Log, Talents and Progress Track references: textured frame background, continuous native title strip, centered title text in the title region, native close control, and clearly framed internal content panels.

## Corrections from 0.9.2
- Restore native `BasicFrameTemplateWithInset` chrome by no longer hiding NineSlice, Inset, TitleBg or TopTileStreaks.
- Remove the separate custom title plaque, inner tint, side accents and plaque bevel.
- Anchor title text to the frame's native top title region.
- Keep the extra custom thin-gold full-window perimeter bevel removed.
- Keep all internal ModuloMarket panel/control borders.

## Scope
No tab, filter, table, dropdown, inspector, history, data, recipe, gathering, market calculation or scan behavior changes. The 0.9.1 dropdown lifecycle fix is retained.

## Validation
Focused tests 4 PASS; full suite 259 PASS / 61 unchanged historical failures vs 0.9.2; Lua syntax 9/9 PASS. Forever runtime acceptance NOT RUN for 0.9.3.
