# Modulo Market Runtime Audit 0.0.13 — scan-age and shared-cooldown display

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.13  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release type:** separate optional child addon; player-visible status/UI improvement.

## 1. Player problem and observable result

The player wants Modulo Market to use the compact Auction House scan-status presentation seen in ProfessionMaster, and to make the shared `C_AuctionHouse.ReplicateItems()` cooldown explicit. ProfessionMaster's supplied screenshot showed `Auction House data from 9m ago` and `Scan in 4m`. The player had recently rescanned Auctionator and ProfessionMaster before a Market probe that timed out after 90 seconds.

0.0.13 adds:
- A persistent relative-age line: `Auction House data from Xm ago`, based only on Market's last completed Browse snapshot timestamp (`lastSnapshot.timestamp`). If no snapshot exists, it says so; invalid/future timestamps are reported as unknown.
- A live, once-per-second countdown on the Replicate probe button: `Scan in Xm` / `Scan in Xs`, based only on Market's own persisted `replicateProbeAttemptAt` timestamp.
- A visible warning that ReplicateItems has a shared account-wide 15-minute cooldown, and that Auctionator, ProfessionMaster and other addons can consume it.
- Explicit wording that Market cannot see external addon request timestamps; the countdown is only a local estimate and zero does not prove the shared server cooldown is clear.

The countdown belongs to the **Replicate probe button**, not the separate **Start Full Snapshot** Browse scanner. Browse snapshots use a different Auction House API path and are not gated by this Replicate timer.

## 2. Direction decision gate

### Player problem and observable result

The player cannot easily tell how old Market's saved data is or when Market's own Replicate attempt timer expires. Recent scans from other addons can consume the same server-side allowance, making a Market request time out even when Market's own timer appears clear. The result is a compact, always-visible data age, a familiar live countdown, and an explicit shared-cooldown warning without claiming access to other addons' private state.

### Evidence supporting the change

- Player screenshot of ProfessionMaster: `Auction House data from 9m ago`; button text `Scan in 4m`.
- Supplied `AddOns.zip` (143,179,120 bytes; SHA-256 `2b595d3de2d8a73b166a98535e4d843b939c7b7ad5afe51dd8f76a1369a4efb2`):
  - `AddOns/ProfessionMaster/views/auction-scan-button.lua`: `GetTooltipText()` formats last scan age; `UpdateState()` shows cooldown text; `StartTicker()` refreshes once per second.
  - `AddOns/ProfessionMaster/services/auction-scan-service.lua`: declares a 15-minute cooldown; modern clients use ProfessionMaster's own `PM_CharacterSettings.lastPriceScan` timestamp for the countdown and call `C_AuctionHouse.ReplicateItems()` at scan start.
  - `AddOns/ProfessionMaster/models/locales/enUS.lua`: `PriceScanButtonCooldown = "Scan in %s"`; `PriceScanLastScan = "Last scan: %s ago (%d prices)"`.
  - `AddOns/Auctionator/Source_ModernAH/AH/Wrappers.lua` and `AddOns/Auctionator/Source_ModernAH/FullScan/Mixins/Frame.lua`: both contain `C_AuctionHouse.ReplicateItems()` call sites.
- ProfessionMaster's modern-client implementation explicitly uses its own local timestamp. Its `CanSendAuctionQuery()` cross-check is only in the non-modern/legacy branch. Therefore its modern `Scan in Xm` display is not a global oracle for requests made by other addons.
- Modulo Market 0.0.12 source already persists its own Replicate request attempt timestamp in `ModuloMarketDB.replicateProbeAttemptAt` before the API call and blocks same-session retry.
- Player evidence from the preceding tests: one Market request returned 291,276 auctions in 17.0s; a later request received no response within 90 seconds. The player reports recent Auctionator and ProfessionMaster rescans. The ProfessionMaster scan screenshot shows a recent local scan age/countdown. External cooldown interference is plausible but not proven.
- Parent MODULO 1.0.48 decision/evidence 1.0.11 keeps MODULO passive in the shared Auction House request throttle; MODULO removes active owned-auction query retries. This child addon remains separate and does not change MODULO's request behavior.

### Counter-evidence and unknowns

- Neither Market nor the supplied ProfessionMaster modern-client code can inspect a reliable global history of other addons' Replicate calls.
- The 90-second timeout does not prove a cooldown rejection. A missing event, another request's event attribution, server/client failure, or other Auction House activity remain possible explanations.
- Market's saved snapshot age is from the last completed Browse scan. It is not a timestamp for the diagnostic Replicate probe and is not proof that every auction-level record is current.
- Market's local countdown cannot know whether another addon has consumed the shared cooldown since Market's last request.

### Adopted decision

**ADOPTED for this child-addon UI slice:** reproduce ProfessionMaster's compact relative-age and live countdown pattern, but label the Market countdown as local and keep the shared account-wide cooldown warning visible. Do not add inter-addon hooks, read another addon's SavedVariables, add automatic Replicate attempts, or claim a global cooldown-ready signal.

### Alternatives rejected for this slice

- Do not read `PM_CharacterSettings` or Auctionator private state. Those are private addon implementation details, may change, and would create optional-addon coupling.
- Do not infer external scan times from the player report or ProfessionMaster screenshot.
- Do not change the Browse scanner's Start button cooldown: Browse pagination and `ReplicateItems()` are separate request paths.
- Do not auto-run or auto-retry a Replicate request when the countdown reaches zero.

## 3. Ownership, dependencies and Forever contract

- Owner: separate optional child addon `ModuloMarket`.
- MODULO 1.0.48 remains unchanged; dependency remains one-way (Market depends on MODULO; MODULO does not depend on Market).
- Auctionator remains owner of auction economy workflows; ProfessionMaster remains owner of profession management. Their source is inspected only as a UX/API behavior reference; Market has no dependency on either addon.
- The change uses WoW frame/font-string UI, `time()`, existing SavedVariables, and the existing Market probe state. No new Auction House API is called by the display ticker.
- Forever client runtime remains the target, but UI/ticker behavior is **NOT RUN** on Forever for 0.0.13.
- The account-wide cooldown is server/API behavior; the UI only displays Market's own local timestamp. External-addon cooldown status remains **UNKNOWN**.

## 4. Implementation details

### Data age

- Reads `Scanner.completedSnapshot` or `ModuloMarketDB.lastSnapshot`.
- Uses only `lastSnapshot.timestamp`, which is recorded when a full Browse snapshot completes.
- Displays minutes, hours or days using a compact relative-age label, e.g. `Auction House data from 9m ago`.
- No saved snapshot -> `No saved Auction House data yet`.
- Invalid/future timestamp -> `Auction House data age unknown`.
- A diagnostic Replicate response or timeout does not refresh this data-age timestamp.

### Replicate countdown

- Reads `ModuloMarketDB.replicateProbeAttemptAt`, falling back to the in-memory timestamp for the current session.
- Counts down from 900 seconds, rounding up to whole minutes and then seconds.
- Refreshes once per second while the Market window is shown; refreshes immediately on opening and on probe state changes.
- A backwards wall-clock jump fails closed for a full 15-minute local interval; it does not incorrectly show ready.
- During a live request, the button reports `Waiting for response`; after an attempt it shows the remaining local cooldown. The existing one-attempt-per-session guard remains intact.
- The button remains a prepare action. A separate explicit confirmation is still required to send one request.
- The warning explicitly says the countdown tracks only Market's requests, cannot see Auctionator/ProfessionMaster/other-addon request timestamps, and reaching zero does not prove the shared cooldown is clear. It instructs the player to wait 15 minutes after any other addon's Replicate scan before confirming.

### No changes to data collection

- No new `ReplicateItems()` call is added.
- No additional Browse request is added.
- No SavedVariables schema for snapshot rows changes.
- `lastSnapshot` remains last-known-good and is not modified by the display ticker.
- No hooks, imports or dependencies on Auctionator or ProfessionMaster are added.

## 5. Source review and scope

Reviewed and changed:
- `AddOns/ModuloMarket/Scanner.lua`: data-age display, cooldown calculation, ticker lifecycle, status text, prepare/confirm paths, scan completion refresh and UI layout.
- `AddOns/ModuloMarket/Core.lua`: addon version only.
- `AddOns/ModuloMarket/ModuloMarket.toc`: addon version only.
- `README.md`, `MANIFEST.json`, current tests and Lua model harness.

Reference review:
- ProfessionMaster scan button/service/locales noted above.
- Auctionator Replicate call sites noted above.
- Parent MODULO 1.0.48 `PROJECT-START-HERE.txt`, `README.txt`, `WORKFLOW.txt`, `PROJECT-PROGRESS.md`, `PROJECT-DECISIONS.txt`, `QA.txt`, `SOURCE-REVIEW-LEDGER.md`, `MODULO-ARCHITECTURE.md`, `MODULO-PRODUCT-DIRECTION.md`, `FOREVER-COMPATIBILITY-CONTRACT.md`, `REFERENCE-ENVIRONMENT.md`, and bundle manifests. Parent source unchanged.
- Relevant parent decision: `Evidence/MODULO-AUCTION-HOUSE-REQUEST-THROTTLE-ISOLATION-1.0.11.md` (MODULO remains passive in shared AH request throttle).
- The current canonical parent archive is `MODULO-Project-Source-1.0.48.zip`, 41,236,015 bytes, SHA-256 `8d6e037f3bb9c535690a148b68ce992e4d3dd92bfcd008402f88cde2203997da`, ZIP CRC PASS, 506 members. `PROJECT-SOURCE-BUNDLE.json` reports `snapshotType=COMPLETE`, `bundleVersion=1.0.48`, `addonVersion=1.0.48`; parent TOC is 1.0.48 and README/human manifest identify 1.0.48. Project file ID `file_000000001a2482128af00913b054f6f9`, source_kind `project`, uploader `developer`.
- Previous child `ModuloMarket-0.0.12.zip`, 68,093 bytes, SHA-256 `839773cfc0d028ce705e8ee042c317c4fe3462e43b5b624d650f33d5946827ba`, ZIP CRC PASS, 28 members. Supplied as Project file ID `file_00000000606c82119e05958fb8925178`.

Not reviewed line-by-line: unrelated MODULO modules, unrelated Market diagnostics/profession views, and unrelated ProfessionMaster/Auctionator files. Their code is not changed or called.

## 6. Tests and package validation

- `python -m pytest -q tests` — **PASS, 41 passed**.
- `texluac -p AddOns/ModuloMarket/Core.lua AddOns/ModuloMarket/Scanner.lua AddOns/ModuloMarket/Diagnostics.lua` — **PASS**.
- `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**.
- `texlua tests/replicate_probe_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**; exercises relative-age text, initial ready label, waiting state, 15m countdown, 14m after a minute, probe one-shot, bounded inspection and snapshot preservation.
- ZIP CRC, exact manifest inventory, fresh extraction, version agreement and SHA-256 — to be recorded in final package handoff.
- Forever runtime display acceptance — **NOT RUN**; requires player to install 0.0.13 and inspect the live window.
- Retail runtime — **NOT RUN**.
- Shared server cooldown detection / attribution of other addon's requests — **UNKNOWN / NOT IMPLEMENTED**.

## 7. Player acceptance / exit criteria

1. Install Modulo Market 0.0.13 beside MODULO 1.0.48.
2. Open the Auction House and `/mm`.
3. Confirm the separate age line reflects the saved Browse snapshot age, e.g. `Auction House data from 9m ago` (or the appropriate no-data/unknown message).
4. If a Market Replicate attempt is still inside its local 15-minute interval, confirm the probe button displays a live `Scan in Xm` countdown and updates once per second.
5. Confirm the introductory warning names the shared account-wide 15-minute Replicate cooldown and Auctionator/ProfessionMaster/other addons, and says Market's countdown only tracks Market's own attempts.
6. Confirm the Browse **Start Full Snapshot** button remains independent of the Replicate countdown.
7. Do not send a new Replicate request merely to test the label; the existing one-request-per-session and explicit-confirmation safeguards remain.

Acceptance requires no Lua errors, no control overlap, correct age/countdown, no automatic request, no change to `lastSnapshot`, and truthful wording about unknown external cooldown state.

## 8. Exit state

0.0.13 delivers the ProfessionMaster-style relative-age/countdown presentation and explicit shared-cooldown warning. It does **not** detect other addons' scan timestamps, prove the shared cooldown is clear, or change the scanner architecture.

**FOREVER status:** 0.0.11 initial Replicate response remains **FOREVER OBSERVED** (291,276 auctions in 17.0s; three samples `hasAllInfo=true`). 0.0.12 bounded inspection and 0.0.13 UI presentation remain **SOURCE IMPLEMENTED; FOREVER RUNTIME NOT RUN**.
