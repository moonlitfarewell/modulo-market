# ForeverDB integration plan

**Status:** proposed; not implemented in ModuloMarket 0.5.1.

## Purpose

Use ForeverDB's read-only API as a source for a reviewed, offline-imported Forever-specific profession and item dataset. The addon itself will not make live Internet requests.

## Intended data

Subject to API access, endpoint availability and field-level validation:

- profession and recipe identities;
- reagent item IDs and quantities;
- output item IDs and output quantities, including ranges where supplied;
- skill requirements and difficulty metadata;
- trainers, vendors, quests, drops and other acquisition sources;
- gathering relationships and relevant item properties.

## Evidence rules

Every imported fact must retain its source and evidence status. In particular:

- Forever client-derived structure is not automatically proof that a recipe is currently obtainable;
- observed Forever acquisition data must remain distinct from client-derived data;
- Vanilla/Classic-derived learning sources must remain labelled borrowed or unconfirmed;
- unknown quantities, sources and availability must remain unknown;
- no profit calculation may invent missing output or reagent quantities.

## Import and distribution

The intended workflow is an offline importer that validates IDs, quantities, provenance and source/build metadata, then emits versioned Lua data for inclusion in a later addon release. The addon will not contain an API key and will not contact ForeverDB at runtime.

No ForeverDB API key or API response data is included in this repository. Integration requires approved developer access and review of the current API terms, rate limits and attribution requirements.

## Attribution

If ForeverDB data is incorporated, provide visible credit and a link to [ForeverDB.net](https://foreverdb.net) wherever the data is displayed, in accordance with the API's requirements. The precise in-game attribution placement will be implemented before distributing any build containing ForeverDB data.

## Current limitation

ModuloMarket 0.5.1 does not import or bundle ForeverDB data. This document records intended future work, not an implemented capability or a claim of Forever runtime verification.
