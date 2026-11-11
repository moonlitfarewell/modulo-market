# Modulo Market Runtime Audit 0.0.8 — throttle pacing and one-file handoff

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.8  
**Parent:** MODULO 1.0.48 (unchanged)  
**Package:** standalone optional child addon.

## Player problem and observable result

The player demonstrated the 0.0.7 last-known-good snapshot lifecycle on the target client: an initial complete snapshot survived `/reload`; a later scan was stopped and the previous snapshot remained; a subsequent full scan completed and the new snapshot survived `/reload`. The latest displayed snapshot was 16,521 item variants across 34 pages. Full client restart has not yet been demonstrated.

The scan remains slower than Auctionator. The player reports that most elapsed time appears to be throttle waiting, but did not provide a measured elapsed duration. 0.0.7 added a fixed two-second quiet interval on top of Blizzard's `IsThrottledMessageSystemReady()` readiness check.

The player also wants to avoid copying nine JSON parts. Since Market already persists the complete table in SavedVariables, the intended handoff is the single `ModuloMarket.lua` SavedVariables file.

## Exact evidence and counter-evidence

### Live target-client evidence supplied by player

- Initial `/mm` view reported no saved snapshot before the first scan.
- Full scan completed and displayed 16,520 item variants across 34 pages.
- After `/reload`, UI reported: `Saved snapshot: 16520 variants ... Available across reloads.`
- A subsequent scan was stopped; UI reported no partial data saved and previous completed snapshot unchanged.
- After `/reload`, the 16,520-row saved snapshot remained available.
- A later full scan completed and displayed 16,521 item variants across 34 pages.
- After another `/reload`, UI reported the 16,521-row snapshot available across reloads.
- Export still displayed `JSON part 1/9 ready (2000 rows)` and the user showed the copied text. This confirms the multipart clipboard path remains present; it does not mean the SavedVariables handoff requires those parts.

### What remains unknown

- Full client restart restore (as distinct from `/reload`) has not been demonstrated.
- SavedVariables disk file size, load time and logout serialization time have not been measured.
- Scan elapsed time and true throttle-wait time were not measured in 0.0.7.
- Concurrent Auction House use and Sell-tab safety remain unverified.
- No evidence establishes that 0.0.8 is 50% faster; its purpose is to remove an avoidable delay and measure actual throttle waiting.

## Source diagnosis

0.0.7 gated each request on both:
1. `C_AuctionHouse.IsThrottledMessageSystemReady()`;
2. an additional `QUIET_SECONDS = 2.0` interval since the last recorded Auction House activity/page response.

The second condition is addon-imposed and can delay a request even after the client reports the throttle channel ready. This is the leading avoidable source-level delay. Counterpoint: the client readiness API may itself remain false for most of the interval; the previous build did not record readiness wait time, so the fraction of total scan time attributable to the extra quiet interval is unknown.

## Change in 0.0.8

- Removed the additional two-second quiet interval.
- Retained the mandatory `IsThrottledMessageSystemReady()` check before initial and subsequent browse requests.
- The scanner sends the next request as soon as the client reports the shared throttle ready.
- Added measurement of total scan duration and actual time spent with the throttle API reporting not-ready.
- Completion and abort status now report elapsed and throttle-wait seconds.
- Snapshot metadata records `scanDurationSeconds` and `throttleWaitSeconds`.
- Corrected JSON serialization to use actual newline separators rather than literal backslash-n characters.
- Documented the single-file SavedVariables handoff: upload `WTF/Account/<account>/SavedVariables/ModuloMarket.lua`; no nine-part copy/paste is needed for analysis.
- Preserved last-known-good persistence, incomplete-scan discard, Sell-tab gate, page/result/time limits, and read-only behavior.

## Competing performance hypotheses

1. **Addon-imposed quiet interval was a major contributor.** Supported by the fixed two-second wait after every throttle activity/page response. Removing it should materially reduce idle time when the client reports ready sooner.
2. **The client throttle itself dominates.** If `IsThrottledMessageSystemReady()` remains false for most of each interval, removing the quiet delay will have little effect. The new timing fields distinguish this: compare total elapsed time with `throttleWaitSeconds`.

## Ownership, dependencies and Forever constraints

- Market remains a separate optional child addon depending on MODULO.
- MODULO 1.0.48 remains unchanged; MODULO has no dependency on Market.
- No Auctionator private API/queue/database is accessed.
- The only request gate remains the public client readiness API already used in 0.0.7.
- No new client API or write/buy/sell/post behavior is introduced.
- The SavedVariables file is the supported data handoff; the addon does not attempt arbitrary filesystem writes.

## Risks and scope

- Removing the extra quiet interval increases request cadence up to the pace permitted by the client's own readiness API. This is intended to avoid double-throttling but must be tested on the target Forever client.
- A target client may expose different throttle semantics than assumed; any dropped request, browse failure, or Sell-tab interference is a release blocker.
- A 16k+ row SavedVariables table may increase load/logout time; not yet measured.
- `throttleWaitSeconds` measures intervals observed with readiness false. It is not a server-side throttle metric and may not include every queueing/response delay.
- No guarantee of 50% improvement is made until a before/after timed scan is compared at similar page/result volume.

## Validation

- Python source tests: recorded with package build.
- Lua syntax: NOT RUN if no Lua compiler/interpreter is available.
- Lua scanner model harness: NOT RUN if no Lua interpreter is available.
- Forever runtime for 0.0.8: NOT RUN.
- Retail runtime: NOT RUN.
- Full client restart: NOT RUN.
- Actual scan timing comparison: NOT RUN.
- Sell-tab safety/concurrent Auction House behavior: NOT RUN.

## Acceptance / exit criteria

1. On the same target client, run a scan with roughly comparable result/page volume and record elapsed duration and throttle-wait duration shown by 0.0.8.
2. Confirm each page is still received and scan reaches the complete-results gate.
3. Compare total elapsed time with the 0.0.7 baseline if a reliable baseline is available; target is at least 50% faster, not assumed.
4. Confirm the readiness gate is respected and no dropped throttle message or browse failure occurs.
5. Confirm the 16k+ snapshot survives `/reload` and full client restart.
6. Confirm a stopped/failed new scan preserves the previous saved snapshot.
7. After a normal `/reload` or logout, upload the single `ModuloMarket.lua` SavedVariables file and verify the snapshot can be extracted; no JSON clipboard parts required.
8. Confirm ordinary browsing and Sell-tab posting remain functional after the scan.

**Status:** 0.0.7 persistence is demonstrated across `/reload` based on user screenshots. 0.0.8 throttle change and timing instrumentation are source-implemented; target-client acceptance remains NOT RUN / UNKNOWN.
