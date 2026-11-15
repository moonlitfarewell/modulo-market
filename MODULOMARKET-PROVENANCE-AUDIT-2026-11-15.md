# Modulo Market Provenance Audit — 15 November 2026

## Scope and method

Inspected the exact `ModuloMarket-GitHub-Update-0.12.5-LICENSING-CANDIDATE.zip` archive, its complete extracted file inventory, the addon source tree, the ForeverDB canonical JSON datasets and compiled runtime data, the six bundled TGA textures, the root licence/notices, and the live public GitHub `main` branch files named below. Public provider and upstream project documentation was also checked. This is a provenance/redistribution review, not legal advice or a legal clearance opinion.

Archive SHA-256 at inspection: `e1f2a212d2959608a1cb7d011f6f579f49bcbcc06659e37e4daca80477d060cb`. ZIP CRC test passed. The archive contains 275 files plus its root directory entry.

## Findings

| Material | Evidence in package | Current classification | Release consequence |
|---|---|---|---|
| Original Lua addon source | 14 Lua files under `AddOns/ModuloMarket/`; no separately vendored third-party Lua library found in the addon directory | Project-authored source is intended to be MIT-licensed, limited by contributor rights | Scoped `LICENSE` is appropriate for original code only; it does not clear data/assets/dependencies |
| ForeverDB canonical data | `data/ForeverDB-Canonical-1.60.1.70938.json` and prior canonical snapshots; compiled `AddOns/ModuloMarket/ForeverDBData.lua`; embedded provider/source metadata and visible UI credit/link | Third-party provider data; provider rules apply | Attribution is present. Provider's current developer rules say credit with visible link, no resale/passing off as own, do not ship API keys, and fetch/bundle data with releases. Those rules are not a general open-data licence. Do not describe data as MIT or unrestricted |
| CMaNGOS-derived facts | Provider dataset labels some source facts `Classic data (CMaNGOS), not confirmed in Forever`; records are mixed with Forever-observed and other evidence | Upstream-derived factual records; precise chain/rights unresolved | Do not claim all such records are cleared under MIT or by ForeverDB rules. Keep UNKNOWN pending provider/upstream clarification or remove the affected rows from redistributed package |
| UI textures | `cancel.tga`, `check.tga`, `chevron-down.tga`, `close.tga`, `refresh.tga`, `search.tga`; each is a 64×64 RGBA TGA. Visuals are simple glyphs. No author/licence metadata was found in the files or inspected source references | Authorship/licence UNKNOWN | No basis to assert they are original or MIT. Obtain source/permission evidence or replace with newly authored, documented assets before broad redistribution |
| Blizzard/WoW references | Provider records and UI describe game items/professions; notices disclaim affiliation; provider dataset distinguishes Forever/Classic/Blizzard-derived facts | Third-party game content/trademarks | No Blizzard ownership or permission claim is made. Avoid bundling Blizzard artwork/client assets; none was found among the six local texture files |
| External icon URLs | ForeverDB JSON contains provider-hosted `icon_url` references; no matching downloaded icon image files were found in the package | Remote provider assets/links, not locally bundled files | Keep attribution and links; remote hosting does not establish rights to copy those icons into the addon |
| Dependencies | TOC declares `Modulo` required and `LibProfessionDB` optional; neither is vendored as third-party source in the addon directory | External addon dependencies | Their own licences/terms govern their code; this package does not relicense them. MODULO dependency is intentional; no LibProfessionDB code is bundled |
| Writ/turn-in reference material | `WritData.lua` identifies Wowhead Forever Craftsman's Writs guide (2026-11-13), 60.tools Merchants' Favor guide (accessed 2026-11-14), and ForeverDB 1.60.1.70938 catalogue | Mixed factual/reference sources; specific rights not documented in source file | Preserve source attribution. The records are project-authored factual transformations, but do not assume that source attribution itself grants rights to copy protected text/images |

## External terms checked

- ForeverDB developer documentation currently requires visible credit with a link to `https://foreverdb.net`, prohibits resale or presenting data as one's own, and prohibits shipping API keys in distributed plugins/apps; it tells developers to fetch data and bundle it with releases. It does not present itself as a general open-data licence. Source: https://foreverdb.net/developers
- CMaNGOS Classic-DB documentation states that Classic-DB is released under GPL v3 and that its licence file must accompany redistributable packages; it separately states that some copyrighted materials are not part of GPL v3. The package's provider records do not establish that each embedded fact is copied from that database or that the database licence attaches to each fact. Source: https://github.com/cmangos/classic-db

## Repository reconciliation

Read-only inspection of `moonlitfarewell/modulo-market` default branch `main` on 15 November 2026 confirmed: `AddOns/ModuloMarket/ModuloMarket.toc` reports 0.12.5; `AddOns/ModuloMarket/Core.lua` reports `MM.version = "0.12.5"`; root `LICENSE` and `THIRD-PARTY-NOTICES.md` exist. The live `README.md` still said main was 0.12.4 and no remote update had been made; the live `MODULOMARKET-RUNTIME-AUDIT-0.12.5.md` also contained that pre-push claim and outdated statements about no licence file. The live `MANIFEST.json` version/file count and complete source inventory were not yet independently byte-compared against this archive. Do not treat TOC/Core agreement alone as proof of full branch/archive equivalence. No remote writes were made during this audit.

## Release decision

**NOT CLEARED for unrestricted redistribution or 1.0.0.** The scoped MIT grant can cover original source only. ForeverDB's published developer rules support the current visible attribution and bundling pattern but are not an open-data licence; exact permission for this particular dataset is not independently established. CMaNGOS-derived record provenance/rights and all six texture origins remain UNKNOWN.

### Required closure actions

1. Ask ForeverDB for written confirmation that this specific derived/bundled dataset, including provider-labelled Classic/CMaNGOS records, may be redistributed in a public addon under the documented developer rules, and whether any additional notice is required.
2. Identify the origin of the six TGA files from source history/design records, or replace them with freshly authored assets and record authorship/licence.
3. Clarify whether the CMaNGOS-labelled facts in the provider feed are transformed factual observations or database-derived material subject to upstream terms; if unresolved, exclude those records from a distributable data build.
4. Verify each non-provider reference source in `WritData.lua` and document the factual basis/attribution; do not copy protected prose/artwork.
5. Compare the complete GitHub tree/file hashes to the final release archive after documentation is synchronized.

## Evidence limitations

- This review does not establish copyright ownership from visual appearance or factual nature alone.
- The provider terms are subject to change; re-check at release time.
- No author/permission correspondence from ForeverDB, CMaNGOS, Blizzard, Wowhead or 60.tools was supplied.
- No legal opinion was obtained.


## 15 November 2026 follow-up — current provider source labels

A further review of the current ForeverDB developer, About and addon pages confirms the distinction between Forever-observed data and Classic fallback material. The developer rules now explicitly state that answers carry invisible marks identifying the key they were served to, that Classic data and player-observed data are labelled, and that plugin developers must fetch and bundle data with releases rather than ship API keys. The About page says quest, drop, vendor and creature details may use labelled Classic Era data where Forever observations are missing. The ForeverDB addon page explicitly credits CMaNGOS classic-db (GPL-3.0) for its Classic fallback data. These statements strengthen provenance attribution but still do not provide a standalone sublicence for Modulo Market's redistribution of this exact mixed dataset.

The 1.60.1.70938 canonical JSON was recursively inspected. It contains 2,296 `acquisition_sources[].source_text` entries labelled `Classic data (CMaNGOS), not confirmed in Forever`; 2,292 corresponding `CLASSIC_BORROWED` acquisition evidence fields; 2,050 `CLASSIC_BORROWED` acquisition entity evidence fields; 404 `CLASSIC_BORROWED` orange-skill threshold evidence fields; 196 trainer-summary source labels; 196 trainer-cost evidence/source fields; and trainer records with 95 Classic-borrowed place-evidence fields and 93 Classic-borrowed entity-evidence fields. These are field/record counts, not a count of unique copyrighted works or a legal conclusion. The data is mixed: recipe structures can be marked `FOREVER_CLIENT` while one or more acquisition/trainer details are Classic-borrowed. Removing whole recipes based only on one Classic fallback field would therefore discard independently Forever-observed recipe facts; any sanitization must be field-level and tested against the importer and runtime consumers.

Sources: https://foreverdb.net/developers ; https://foreverdb.net/about ; https://foreverdb.net/addon ; https://github.com/cmangos/classic-db ; https://github.com/cmangos/classic-db/blob/master/COPYRIGHT.md


## 0.12.8 supersession note — 15 November 2026

The 0.12.5/0.12.7 provenance review above records the original mixed-provenance 70938 canonical payload. In 0.12.8, the unfiltered 70862, 70888 and 70938 canonical JSON files were removed from the public bundle and replaced by `data/ForeverDB-Distribution-1.60.1.70938.json`. The new projection excludes speculative recipes, Classic-borrowed/unknown acquisition rows, Classic comparison metadata, non-observed trainer entities/locations/prices, and skill thresholds without Forever-client evidence. Exact counts and original source hashes are in `MODULOMARKET-DATA-CLEANUP-0.12.8.md`. This preserves the earlier audit history without implying the old unfiltered files remain in the 0.12.8 package.
