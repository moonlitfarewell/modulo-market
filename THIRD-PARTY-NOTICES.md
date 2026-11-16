# Third-party materials, data and provenance notices

This file records known non-project material in Modulo Market. It is not a
substitute for an upstream licence or permission, and it does not relicense
third-party material.

## ForeverDB.net-derived distribution projection

The current bundle includes `data/ForeverDB-Distribution-1.60.1.70938.json`
and its compiled runtime catalogue `AddOns/ModuloMarket/ForeverDBData.lua`.
The projection retains non-speculative recipe structures, outputs and reagent
quantities labelled `FOREVER_CLIENT`, plus acquisition rows explicitly labelled
`FOREVER_OBSERVED` or `FOREVER_CLIENT`.

The projection excludes all `CLASSIC_BORROWED` and `UNKNOWN` acquisition rows,
Classic comparison fields, non-observed trainer entities/locations, unobserved
trainer prices, skill thresholds without `FOREVER_CLIENT` evidence, and all
speculative recipes. The original mixed-provenance canonical captures are not
included in this release. See `MODULOMARKET-DATA-CLEANUP-0.12.8.md` for exact
source hashes, counts, and projection rules.

### Distribution basis and conditions (reviewed 16 November 2026)

ForeverDB's published developer page expressly instructs approved developers
to fetch data themselves and bundle it with their releases. It also states the
conditions relevant to this distribution: on the free tier, credit ForeverDB
with a visible link wherever its data is shown; do not resell the data or
present it as your own; and never ship an API key inside a distributed plugin
or app. Modulo Market follows that workflow: the addon displays `Data from
ForeverDB.net` with a link wherever the catalogue data is presented, the data
is bundled locally, no key is included, and the data is not sold or represented
as project-owned.

We rely on this published fetch-and-bundle workflow as the basis for including
the filtered provider-derived projection in this free addon release, subject to
those stated conditions. This is not a claim that ForeverDB has granted a
standalone open-data licence, transferred ownership, or authorised resale or
relicensing of the data. The root MIT licence does not apply to the projection.
Provider terms can change; the current instructions are at
https://foreverdb.net/developers.

ForeverDB separately states that data from the WoW Forever client is
Blizzard's and that ForeverDB is not affiliated with Blizzard Entertainment.
The provider's bundling workflow does not grant rights on Blizzard's behalf.
Modulo Market therefore makes no ownership or independent licensing claim over
client-derived data, game assets or trademarks. This is the remaining disclosed
third-party rights limitation; no false grant is made in the Modulo Market
licence. The project does not claim that this notice is legal advice or a
substitute for the rights holder's terms.

## CMaNGOS / Classic-derived material

The 0.12.8 distribution projection contains no acquisition rows labelled
`CLASSIC_BORROWED`, no Classic comparison metadata, no Classic-only trainer
records/locations, and no Classic trainer prices or Classic orange thresholds.
The upstream 70938 source capture did contain such fields; their original
unfiltered hashes and exclusion counts are recorded in the data-cleanup audit.
They are not included in the 0.12.8 distribution projection.

ForeverDB's addon credits identify CMaNGOS classic-db as GPL-3.0. CMaNGOS
Classic-DB separately warns that some World of Warcraft material is not covered
by its database licence. No CMaNGOS-derived data is intentionally retained in
the current projection. Historical source review documents may describe the
excluded source provenance, but the unfiltered data payloads are not shipped.

## Blizzard / World of Warcraft data

The retained recipe structures, output identifiers and reagent data are
labelled by ForeverDB as `FOREVER_CLIENT`. ForeverDB's developer information
identifies client data as Blizzard's. The provider's bundling workflow does not
itself establish a general Blizzard licence. Blizzard Entertainment is not
affiliated with Modulo Market. The project does not claim ownership of Blizzard
trademarks, game assets or proprietary client material. These retained fields
remain a residual third-party rights limitation and are not MIT-licensed.

## Other dependencies and assets

The addon declares `Modulo` as a required dependency and `LibProfessionDB` as
an optional dependency. These are dependencies, not relicensed components.
The six UI texture files under `AddOns/ModuloMarket/Textures/` in 0.12.7 and
later are newly rendered from the project-authored SVG masters listed in
`ASSET-PROVENANCE.md`; no third-party art source was used. These listed assets
are included in the root MIT scope, to the extent contributors hold those
rights. This does not change the status of any external dependency or dataset.

## Release rule

The root `LICENSE` applies only to original Modulo Market source code and the
project-authored UI assets listed in `ASSET-PROVENANCE.md`, to the extent
contributors have the rights to license them. It does not override any
third-party licence, provider condition, dependency licence, or data right.
Where provenance or permission is unknown, retain that status as UNKNOWN and
do not include the underlying record/field in the distributable projection.
