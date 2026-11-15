# Original UI Asset Provenance

## Scope

The six 64×64 RGBA TGA glyphs in `AddOns/ModuloMarket/Textures/` were regenerated for Modulo Market 0.12.7 from the editable SVG masters in `assets/ui-icons/`. The geometry is original project artwork drawn from simple geometric paths; no third-party icon font, downloaded image, game texture, or upstream raster asset was used as an input.

The raster outputs are reproducible with `tools/assets/render_modulomarket_icons.py` (Python 3 and Pillow required). The source SVGs and renderer are included in this repository.

## Asset register

| Runtime asset | Editable source | Purpose |
|---|---|---|
| `check.tga` | `assets/ui-icons/check.svg` | Confirmation/check glyph |
| `close.tga` | `assets/ui-icons/close.svg` | Neutral close glyph |
| `cancel.tga` | `assets/ui-icons/cancel.svg` | Cancel glyph |
| `refresh.tga` | `assets/ui-icons/refresh.svg` | Refresh glyph |
| `chevron-down.tga` | `assets/ui-icons/chevron-down.svg` | Dropdown indicator |
| `search.tga` | `assets/ui-icons/search.svg` | Search glyph |

## Licence and limits

These project-authored assets are included within the scope of the root MIT licence, to the extent the project contributors hold the rights to license them. This statement applies only to the listed UI glyphs and their editable masters. It does not grant rights to ForeverDB data, CMaNGOS-derived material, Blizzard content/trademarks, dependencies, or other third-party material.

The earlier undocumented TGA files have been replaced. The old files' provenance remains unknown; they are not included in this release.
