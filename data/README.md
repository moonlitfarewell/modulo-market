# ForeverDB capture and canonical data

## Active dataset

- Provider: [ForeverDB.net](https://foreverdb.net)
- Active canonical source: `ForeverDB-Canonical-1.60.1.70938.json`
- Client build: `1.60.1.70938`
- Capture: 2026-11-13T10:55:21Z through 10:56:31Z
- Captured profession records: 12 professions, 2,493 recipes
- Runtime output: `AddOns/ModuloMarket/ForeverDBData.lua`
- Runtime attribution: `Data from ForeverDB.net` with a visible provider link in the addon UI

The 70938 canonical capture was normalized and validated from the user-supplied raw capture. Its 2,493 recipe records are identical to the 70888 capture: zero recipe additions, removals or changed recipe records. The 70938 provider metadata and capture provenance advance; this is not a claim that the profession facts changed. See `docs/FOREVERDB-DATA-REVIEW-2026-11-13.md`.

## Historical canonical files

- `ForeverDB-Canonical-1.60.1.70862.json` — 11 November baseline.
- `ForeverDB-Canonical-1.60.1.70888.json` — 12 November baseline.
- `ForeverDB-Canonical-1.60.1.70938.json` — active 13 November capture.

The raw capture archives are retained outside the public repository. Their hashes, response inventories and validation results are recorded in the dated data-review documents. The standalone importer and the embedded repository compiler have separate version lifecycles; the active runtime payload was generated with the embedded repository compiler, not the standalone compact compiler.

## Attribution and distribution status

ForeverDB attribution is required wherever the data is displayed. The existing addon UI shows `Data from ForeverDB.net` and links to the provider. The [ForeverDB developer documentation](https://foreverdb.net/developers) describes this attribution requirement for API use. However, attribution is not assumed to grant a general right to redistribute a bundled copy of the normalized dataset. Redistribution permission for this bundled dataset remains **UNCONFIRMED** and is a 1.0 distribution gate. Do not remove attribution, represent the dataset as original Modulo Market data, or claim a redistribution licence without written/provider terms that support it.

No API key, account credential or raw capture archive is included in the addon package.
