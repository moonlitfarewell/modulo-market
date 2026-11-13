# ModuloMarket Title Strip and Tab Join Correction 0.9.5

## Visual objective
Make the native title strip visibly taller and align the title within it, while eliminating the visible gaps between adjacent tabs.

## Changes
- Clear and reset native `TitleBg` anchors before setting a 44px height.
- Centre `Modulo Market` at -27px in a 320x28 text region.
- Increase main frame height to 882px to accommodate the layout.
- Shift addon-owned frame-anchored content down 16px; preserve the native close button and Blizzard chrome.
- Set adjacent tab spacing to zero (`tabX += width`) so tabs touch.
- Keep tab top/bottom strokes, backgrounds, selected marker, hover and click behavior.
- Preserve all internal panel/control borders and the dropdown lifecycle fix.

## Validation
Focused tests 8 PASS; full suite 267 PASS / 61 unchanged historical failures vs 0.9.4; zero new failing IDs; Lua syntax 9/9 PASS. Forever runtime acceptance NOT RUN for 0.9.5.
