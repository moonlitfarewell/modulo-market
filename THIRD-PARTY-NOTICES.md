# Third-party materials, data and provenance notices

This file records known non-project material in Modulo Market. It is not a
substitute for an upstream licence or permission, and it does not relicense
third-party material.

## ForeverDB.net-derived data

The canonical recipe datasets under `data/ForeverDB-Canonical-*.json` and the
compiled runtime catalogue `AddOns/ModuloMarket/ForeverDBData.lua` contain
ForeverDB.net-derived data. ForeverDB's developer rules require visible credit
with a link wherever its data is shown, prohibit reselling the data or
presenting it as our own, and say not to ship API keys in distributed plugins
or apps. The developer page also says developers may fetch the data and bundle
it with releases. Modulo Market displays `Data from ForeverDB.net` and links to
https://foreverdb.net; no API key is included in the addon package.

These rules are usage conditions, not a general open-data licence. This notice
does not grant ownership or unrestricted redistribution rights over ForeverDB
data. Any distribution must remain within the provider's current rules and
any applicable developer-access conditions. Provider: https://foreverdb.net/developers

## CMaNGOS-derived facts represented in provider data

Some ForeverDB records explicitly label source facts as `Classic data
(CMaNGOS), not confirmed in Forever`. ForeverDB's own addon credits identify
CMaNGOS classic-db as GPL-3.0. The precise licence/provenance relationship for
the particular facts embedded in Modulo Market's provider datasets has not
been independently established. These records are therefore not represented
as MIT-licensed. Their inclusion and redistribution status remains subject to
upstream rights and review.

## Blizzard / World of Warcraft data

Some provider data describes the World of Warcraft client and game. Blizzard
Entertainment is not affiliated with Modulo Market. This project does not
claim ownership of Blizzard trademarks, game assets or proprietary client
material. Applicable rights remain with their respective owners.

## Other dependencies and assets

The addon declares `Modulo` as a required dependency and `LibProfessionDB` as
an optional dependency. These are dependencies, not relicensed components.
The six UI texture files under `AddOns/ModuloMarket/Textures/` in 0.12.7
are newly rendered from the project-authored SVG masters listed in
`ASSET-PROVENANCE.md`; no third-party art source was used. These listed assets
are included in the root MIT scope, to the extent contributors hold those
rights. This does not change the status of any external dependency or dataset.

## Release rule

The root `LICENSE` applies only to original Modulo Market source code and the
project-authored UI assets listed in `ASSET-PROVENANCE.md`, to the extent
contributors have the rights to license them. It does not override any
third-party licence, provider condition, dependency licence, or data right.
Where provenance or permission is unknown, retain that status as UNKNOWN and
resolve it before making a broader redistribution claim.
