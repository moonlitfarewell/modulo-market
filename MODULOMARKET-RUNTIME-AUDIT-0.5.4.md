# ModuloMarket Runtime Audit — 0.5.4

**Date:** 2026-11-11  
**Addon:** ModuloMarket 0.5.4  
**Parent:** MODULO 1.0.48 (unchanged)  
**Scope:** visible addon version reporting; investigate Forever client build 1.60.1.70888 and preserve recipe-data safety gates.

## 1. Player problem and observable result

The player could see MODULO's version in login chat but could not quickly identify the installed ModuloMarket version. The Market window also lacked a visible version/build marker. In addition, the player's Forever client updated from build 70862 to 70888 while the bundled ForeverDB dataset remained captured from 70862.

**Delivered observable capability:** login chat reports `ModuloMarket v0.5.4` and the client build; `/mmversion` reports addon version, client build and ForeverDB dataset/load state; the Market footer displays addon version and client build.

## 2. Evidence and counter-evidence

### Supplied runtime evidence

The user's in-game command returned:

```text
GetBuildInfo: 1.60.1 70888 Nov  9 2026 16001
```

The prior 0.5.3 screenshot displayed:

```text
ForeverDB data build mismatch (data 1.60.1.70862; client 1.60.1.70888); imported recipes are not loaded
```

This directly establishes that the client reports 70888 and that the addon's existing exact-build gate refused the 70862 dataset.

### External update research

- The Forever client build comparison for 70862 → 70888 reports no profession-table changes in the client data: https://theforeverera.com/en/builds/70862-70888/
- Separate November 10 server-hotfix reporting identifies profession-related changes, including Coarse Grinding Stone skill-up range (Blacksmithing), Journeyman Campfire Kit placement requirement (Cooking), Minor Arcane Elixir sell price (Alchemy), and Iron Grenade vendor price (Engineering): https://allthings.how/wow-forever-hotfixes-patch-notes/
- The build comparison covers client-file differences; it is not proof that server-side hotfixes leave profession behavior and economics unchanged.

### Counter-evidence / limits

The client build diff's lack of profession-table changes is encouraging for client recipe structure only. Server-side profession changes are independently reported. Neither source provides the complete ForeverDB API response for build 70888 or validates every row in the 70862 capture against live server behavior.

## 3. Data and compatibility decision

**Do not relax the exact-build gate.** The canonical ForeverDB capture and generated runtime data remain tied to `1.60.1.70862`. They are not relabelled as `70888`, and no compatibility exception is introduced.

A fresh API capture for 70888 is required. It must be complete, hash-verified, normalized with the reviewed adapter (or a revised adapter if the schema changed), validated, compiled and sampled against the live client/server. Server-side profession hotfix parity remains UNKNOWN until this is done.

No ForeverDB API key was supplied as part of this pass. The importer requires the user's approved key in the local `FOREVERDB_API_KEY` environment variable. The key must not be sent in chat, stored in the addon, or committed to the repository.

## 4. Ownership, scope and dependencies

- ModuloMarket owns version reporting, recipe data integration and compatibility safeguards.
- MODULO remains unchanged and does not depend on ModuloMarket.
- No new addon dependency or live network request was added.
- ForeverDB remains a build-time importer source only; no API credential is distributed.

## 5. Implementation

- `Core.lua`: addon version is 0.5.4; login announcement includes addon version and `GetBuildInfo()` version/build; `/mmversion` reports the addon version, current client build and ForeverDB data build/load state.
- `MarketUI.lua`: Market footer shows `ModuloMarket v0.5.4` and the detected client version/build.
- TOC, README and MANIFEST version metadata advanced to 0.5.4.
- Existing exact dataset/client build gate and saved auction snapshot/client build gate remain unchanged.
- Historical 0.5.3 runtime audit and data provenance are preserved.

## 6. Tests and package evidence

### Executed checks

- `python -m pytest -q -p no:cacheprovider tests`: **131 passed**.
- `texluac -p` on all 9 addon Lua files: **PASS**.
- `texlua tests/version_reporting_0_5_4_harness.lua AddOns/ModuloMarket/Core.lua`: **PASS**.
- `texlua tests/foreverdb_provider_0_5_3_harness.lua AddOns/ModuloMarket/ForeverDBData.lua AddOns/ModuloMarket/ProfessionData.lua`: **PASS**, including refusal to load the 70862 dataset on client build 70888.
- Existing Market UI 0.5.0 model harness: **PASS** through the Python regression suite.
- Manifest inventory/version consistency: **PASS**, 84/84 files.

A separate older market-engine model harness invocation exceeded the available execution window; it is not a changed-code acceptance test and is not counted as PASS. The changed UI and provider harnesses above passed.

### Package checks (after archive creation)

- GitHub source ZIP: ZIP CRC **PASS**; exact 84-file manifest inventory **PASS**; every entry is rooted under `modulo-market/`.
- Fresh extraction: Python regression suite **131 passed**; Lua syntax **PASS** for all 9 addon Lua files.
- SHA-256 values are provided in the delivery message; the audit does not embed its own hash or the archive hash to avoid circular packaging metadata.


## 7. Runtime status and acceptance

| Item | Status |
|---|---|
| 0.5.4 login version announcement | NOT RUN in Forever |
| `/mmversion` command | NOT RUN in Forever |
| Market footer version/build | NOT RUN in Forever |
| Client build 70888 confirmed via `GetBuildInfo()` | FOREVER OBSERVED from user screenshot/text |
| 70862 dataset on 70888 | Correctly blocked in user's 0.5.3 screenshot |
| Fresh ForeverDB capture for 70888 | NOT RUN; API key/capture unavailable in this pass |
| Server-side profession hotfix parity | UNKNOWN |
| 70888 recipe accuracy and economics | NOT RUN |
| MODULO parent changes | None; parent remains 1.0.48 |

**Exit criterion:** version UI is accepted by the player on Forever; fresh 70888 data is independently captured/reviewed before any recipe-data compatibility is enabled. Source tests and package integrity do not constitute Forever runtime acceptance.

## 8. Next action

Install 0.5.4 and verify the login announcement, `/mmversion`, and footer. Separately, run the importer capture locally with the approved ForeverDB API key, without sharing the key. Provide the resulting capture ZIP; the next data slice can then normalize and review it.
