# Modulo Market Runtime Audit 0.0.6 — bounded JSON export

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.6  
**Parent:** MODULO 1.0.48 (unchanged)  
**Package:** standalone optional child addon.

## Player problem and observable result

The user's first live snapshot completed with **16,403 item variants across 33 pages**. The scan took considerably longer than Auctionator, and pressing Export JSON caused severe UI lag that had not recovered at the time of the report.

## Evidence and diagnosis

### Direct runtime evidence

- Screenshot shows the UI reporting: `Complete snapshot captured: 16403 item variants across 33 pages.`
- The screenshot shows the export operation being used and the user reports that the UI became very laggy and did not recover promptly.
- The screenshot does not establish the elapsed scan time, export duration, exact client error state, or whether the client eventually recovered.

### Source-confirmed export defect

In 0.0.5, `BuildJSON()` synchronously formatted every row into one large string. The Export button then called `EditBox:SetText()` with that complete string. More importantly, the EditBox `OnTextChanged` handler counted every newline, expanded the EditBox height to `(lineCount + 2) * 14`, and reset the ScrollFrame child. For 16,403 rows this created an extremely tall UI child. This is a concrete, avoidable UI-layout cost and a strong explanation for the reported freeze.

### Competing hypotheses

1. **EditBox layout/reflow dominates:** supported by the explicit per-line height expansion and giant scroll child. Distinguish by exporting bounded chunks into a fixed-height widget.
2. **Synchronous JSON serialization dominates:** `BuildJSON()` formats all rows in one click handler. Distinguish by comparing bounded-chunk export responsiveness and, if needed, separately instrumenting serialization and `SetText()` timings.

0.0.6 addresses both exposure points by serializing and displaying at most 2,000 rows per action. No runtime timing instrumentation was added, so the relative contribution of serialization versus UI layout remains unmeasured.

## Scan duration

The 0.0.5 scanner deliberately waits for Auction House throttle readiness and a two-second quiet interval after activity/page responses. This can make a 33-page scan materially slower than Auctionator. The screenshot confirms completion but does not provide elapsed time or page timings. This pass preserves the conservative pacing; it does not claim the scan is optimally fast or safe during concurrent Auction House activity.

## Ownership and scope

- Market remains a separate optional child addon depending on `Modulo`.
- MODULO core remains 1.0.48 and is unchanged.
- Auctionator remains independent; no Auctionator private queue or database is accessed.
- Market remains read-only and in-memory; persistence and recipe profitability remain gated.
- Sell-tab safety checks, throttle pacing, page limits and incomplete-scan discard behavior are preserved.

## Change in 0.0.6

- Export is split into independently valid JSON parts of at most 2,000 rows.
- Each part records `chunkIndex`, `chunkCount`, `rowStart`, `rowEnd`, total `resultCount`, timestamp and client metadata.
- Previous Part / Next Part navigation selects the current export part.
- The output EditBox remains fixed at its designed height; the line-count-driven `SetHeight()` handler is removed.
- The snapshot remains in memory and is not modified by exporting.

Each part is valid JSON, but no individual part is the complete snapshot. Reconstruct the full snapshot by concatenating the `rows` arrays in chunk order. This is an explicit export format change to schemaVersion 2.

## Validation

- Fresh-extraction source tests: `python -m pytest -q tests` — **10 passed**.
- Lua syntax: `texluac -p` on `Core.lua`, `Scanner.lua`, and `Diagnostics.lua` — **PASS**.
- Scanner model harness: `texlua tests/scanner_model_harness.lua AddOns/ModuloMarket/Scanner.lua` — **PASS**, including 2,001-row two-part boundary checks.
- ZIP integrity: **PASS**; 13 files.
- Fresh extraction: **PASS**; all tests and syntax checks run against the extracted package.
- Live Forever export responsiveness: **NOT RUN**.
- Live Retail export responsiveness: **NOT RUN**.
- Actual serialization/layout timing split: **UNKNOWN / NOT INSTRUMENTED**.
- Auction House elapsed-time comparison with Auctionator: **NOT MEASURED**.

## Acceptance / next runtime test

1. Install Market 0.0.6 beside MODULO 1.0.48.
2. Capture a fresh complete scan and note total elapsed time and page count.
3. Export part 1, then navigate through every part.
4. Confirm the UI remains responsive and each part can be selected/copied.
5. Parse each part externally as JSON; verify contiguous row ranges, consistent chunk count and metadata.
6. Confirm the sum of part row counts equals `resultCount`, with no duplicate or missing row ranges.
7. Verify normal Auction House browsing and Sell-tab posting after the scan.
8. If export still stalls, collect the exact delay and any Lua errors before further changes.

The 0.0.6 source change is not runtime acceptance. Market's Forever runtime status remains **NOT RUN / UNKNOWN**.
