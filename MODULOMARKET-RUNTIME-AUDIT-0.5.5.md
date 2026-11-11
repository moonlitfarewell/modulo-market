# ModuloMarket Runtime Audit — 0.5.5

**Date:** 2026-11-11  
**Addon:** ModuloMarket 0.5.5  
**Parent:** MODULO 1.0.48 (unchanged)  
**Scope:** replace all-or-nothing ForeverDB recipe build rejection with a provenance-preserving baseline-plus-delta model; retain exact current-client auction snapshot gating.

## 1. Player problem and observable result

On Forever client build `1.60.1.70888`, ModuloMarket 0.5.4 refused to load the complete ForeverDB recipe catalogue captured from `1.60.1.70862`. A build-number difference therefore hid the whole unlearned recipe catalogue even though the available evidence identified only a small number of specific hotfix-linked fields.

**Delivered source behavior:** the 70862 catalogue loads on an identifiable newer client as a clearly labelled baseline. Its source build is preserved. Four specifically identified recipe records carry field-level `REVIEW` flags. Unrelated records remain baseline rather than being globally classified as unknown. Auction prices still require a saved market snapshot from the exact current client build.

## 2. Evidence and counter-evidence

### Supplied runtime evidence

The user's in-game `GetBuildInfo()` output reported:

```text
1.60.1 70888 Nov  9 2026 16001
```

The 0.5.4 audit recorded the canonical ForeverDB dataset as `1.60.1.70862` and the 0.5.3 screenshot showed the exact-build gate refusing to load it on 70888.

### Dataset evidence

The bundled canonical file remains `data/ForeverDB-Canonical-1.60.1.70862.json`, with 12 professions and 2,493 recipe records. The 0.5.3 handoff records 2,310 item-output records, 183 non-item/no-item-output records, 143 speculative records excluded from the runtime craft catalogue, and 8,416 reagent rows. This pass does not rewrite or relabel that dataset.

A later user-supplied capture from 2026-11-11 16:45 UTC also reports build 70862. It is not substituted into this compatibility-only slice; its acquisition-source differences remain a separate same-build data-refresh review.

### Hotfix-linked review evidence

The 0.5.4 research record cites:
- Forever client-file comparison for builds 70862 → 70888: https://theforeverera.com/en/builds/70862-70888/
- November 10 Forever hotfix reporting: https://allthings.how/wow-forever-hotfixes-patch-notes/

The comparison reports no profession-table changes in the client-file diff, while the separate hotfix report identifies profession-related changes. These are not equivalent evidence sets: unchanged client files do not prove unchanged server-side behavior or economics.

The runtime review watch maps the reported changes to these ForeverDB recipe IDs:

| Recipe ID | Recipe | Review field | Interpretation |
|---:|---|---|---|
| 3326 | Coarse Grinding Stone | Skill-up range | Reported Blacksmithing range change; thresholds need targeted verification |
| 1283400 | Journeyman Campfire | Placement requirement | Reported Cooking placement change; verify requirement behavior |
| 1245246 | Minor Arcane Elixir | Sell price | Reported item-price change; use current live market pricing, not a stale imported price |
| 3962 | Iron Grenade | Vendor price | Reported vendor-price change; verify before using vendor economics |

These are **review flags**, not assertions that all four complete recipes are confirmed stale. The addon currently does not use imported sell prices or vendor costs to replace live auction prices.

### Counter-evidence and limits

No complete ForeverDB 70888 capture or recipe-by-recipe live-client comparison is available. No claim is made that the remaining records have been individually verified against build 70888. They remain a usable 70862 baseline with preserved provenance, not a newly verified 70888 dataset.

## 3. Compatibility decision

The exact-build gate is removed **only for recipe-catalogue availability**:
- A dataset with missing build provenance is still rejected.
- A client whose build cannot be identified is still rejected.
- A known older dataset may load as a labelled baseline on a newer identifiable client.
- `sourceBuild` remains the actual dataset build; it is never rewritten to the current client build.
- Only the four named hotfix-linked recipe records receive `freshnessStatus = "review"`; other imported records receive `freshnessStatus = "baseline"`.
- Existing recipe evidence categories (Forever client, Forever observed, Classic borrowed, unknown) remain independent of freshness status.

**Auction-price safety is unchanged.** `IsMarketSnapshotCompatible()` still requires the saved Browse/Replicate snapshot's client version and build to match the running client exactly. A 70862 auction snapshot cannot provide recipe economics on 70888.

## 4. Ownership, scope and dependencies

- ModuloMarket owns the importer-data presentation, recipe freshness labels and market snapshot join.
- MODULO remains unchanged at 1.0.48 and does not depend on ModuloMarket.
- ModuloMarket remains a separate optional child addon depending on MODULO.
- No new dependency, live network request or credential handling was added.
- ForeverDB remains a build-time data source with visible in-game attribution.

## 5. Implementation

- `ProfessionData.lua`: validates that both dataset and client build can be identified; no longer rejects a dataset solely because its build differs; preserves `datasetBuild` and `sourceBuild`; adds the four-entry review watch; exposes baseline/match and review counts.
- `MarketUI.lua`: reports baseline build and review count; shows field-scoped review notes in recipe context; continues to withhold craft profitability when the saved market snapshot does not match the current client build.
- `Core.lua`: `/mmversion` reports when older ForeverDB data is loaded as a baseline and how many records are flagged for review.
- `README.md`, `MANIFEST.json`, and `docs/FOREVERDB-INTEGRATION-PLAN.md`: document 0.5.5 behavior and explicitly supersede the historical 0.5.4 all-or-nothing recipe gate.
- Addon and bundle version advanced together to 0.5.5. The 70862 canonical JSON and generated runtime data were not modified.

## 6. Verification

### Executed checks

- `python -m pytest -q -p no:cacheprovider tests`: **131 passed**.
- `texluac -p` on all 9 addon Lua files: **PASS**.
- Version reporting harness: **PASS**, including `/mmversion` baseline state and review count.
- ForeverDB provider harness: **PASS**, including loading 70862 baseline on 70888, preserving build provenance, flagging only the four hotfix-linked records, leaving other records baseline, and rejecting a 70862 auction snapshot for 70888 economics.
- Existing importer, canonical data and runtime compiler regression coverage: included in the 131-test suite.

### Package checks

- GitHub update ZIP: ZIP CRC **PASS**; exact 85/85 manifest inventory **PASS**; every entry is rooted under `modulo-market/`.
- Fresh extraction: full Python suite **131 passed**; all 9 addon Lua files pass `texluac -p`.
- TOC, `Core.lua`, README and JSON manifest version agreement: **0.5.5**.
- Parent `MODULO-Project-Source-1.0.48.zip`: ZIP CRC **PASS**; 506 entries; 41,236,015 bytes; SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`; unchanged.
- The raw API capture and API credential are not included in the public GitHub update.

## 7. Runtime status and acceptance

| Item | Status |
|---|---|
| Client build 70888 reported by user's `GetBuildInfo()` | FOREVER OBSERVED |
| 70862 canonical dataset provenance | Retained; source build unchanged |
| Baseline-plus-delta loader | SOURCE/OFFLINE VERIFIED |
| Four targeted review flags | SOURCE/OFFLINE VERIFIED; field-level advisory only |
| Exact current-client auction snapshot gate | SOURCE/OFFLINE VERIFIED |
| Login announcement / `/mmversion` / Market footer on 0.5.5 | NOT RUN in Forever |
| 70862 baseline behavior on live 70888 client | NOT RUN in Forever |
| Four hotfix-linked fields against live server | NOT RUN / UNKNOWN |
| Full 70888 ForeverDB capture | NOT RUN / unavailable in supplied evidence |
| Full 70888 recipe accuracy and economics | NOT RUN |
| MODULO parent changes | None; 1.0.48 unchanged |

**Acceptance remains open** until the player installs 0.5.5 on Forever 1.60.1.70888, confirms the recipe catalogue loads with its baseline notice, confirms the four review flags are scoped correctly, confirms no Lua errors, and verifies craft profitability remains unavailable until a current-build market snapshot exists. Offline tests are not runtime acceptance.

## 8. Next action

Install the 0.5.5 GitHub update over the existing repository, commit/push through GitHub Desktop, then test on Forever. Capture `/mmversion`, the Market status line, one ordinary unflagged recipe, and one flagged recipe's detail. Also confirm that craft profitability remains blocked until a 70888 market scan is saved.
