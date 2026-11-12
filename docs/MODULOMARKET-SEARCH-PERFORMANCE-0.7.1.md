# ModuloMarket 0.7.2 — tooltip search restart correction

## Player problem

Tooltip-description search on a large catalogue felt laggy and could leave the Crafts view showing progress for an extended period.

## Source diagnosis

The 0.7.0 implementation had three avoidable costs in the search path:

1. Every `OnTextChanged` event immediately discarded and restarted the full view build, including while the player was still typing.
2. Every individual successful item-data event could immediately restart that same full view build. A burst of item loads therefore caused repeated work over the same catalogue.
3. Cached tooltip text was normalized again on every lookup, despite being immutable after extraction.

The filtering loop also performs tooltip extraction in bounded batches (up to 60 inspections per frame) and can request item data (up to 20 requests per frame). Those bounds are retained.

## 0.7.1 runtime retest finding

The player's Forever build 70888 screenshot showed the result counter cycling through `Waiting…`, `Filtering 1500/2175…`, and `0-0/0`. Source review of 0.7.1 found that the coalesced tooltip refresh could still call `StartViewBuild()` while `UI.viewBuild` or `UI.rankSort` was active. A sustained stream of asynchronous item-data completions could therefore invalidate the current pass before it finished.

## Changes in 0.7.2

- Keep a tooltip refresh pending while a view build, rank sort, catalogue build or economics index build is active.
- Start at most one follow-up search after the active work completes and only when the search text is non-empty.
- Preserve typing debounce, asynchronous tooltip requests, normalized cache and bounded per-frame work.
- Render both `NOT LEARNABLE` and `UNKNOWN` status labels in red; their internal states and filters remain distinct.

## Changes

- Debounce search edits by 0.25 seconds; stale in-progress filter/sort work is cancelled while typing.
- Coalesce successful item-data completion notifications into one refresh after a 0.30-second quiet window.
- Normalize tooltip text once when it is extracted and cache the normalized result.
- Preserve the asynchronous item-data request path, description/effect matching, existing name/ID/reagent search, and bounded per-frame work.

## Ownership and compatibility

- ModuloMarket remains a separate optional addon depending on MODULO; MODULO has no dependency on ModuloMarket.
- No ForeverDB requests, credentials, data files, or profession logic changed.
- Parent MODULO 1.0.48 is unchanged.

## Verification

- Source regression tests cover debounce, stale-work cancellation, event coalescing, normalized cache reuse and preservation of tooltip search.
- Lua syntax and package checks are recorded in the runtime audit.
- Forever runtime performance remains NOT RUN until tested in the player's Forever client. Offline tests cannot establish frame-time improvement or confirm client event cadence.

## Acceptance

1. Typing a multi-character effect query produces one filter build after typing pauses, not one per character.
2. A burst of item-data events produces one coalesced refresh rather than one rebuild per event.
3. `healing` and `spell damage` still find matching tooltip descriptions/effects.
4. Search results update when previously unavailable item data arrives.
5. The UI remains responsive and no Lua errors occur on Forever build 70888.


## 0.7.2 verification and runtime status

- Regression tests cover the active-build deferral and red Unknown label.
- Forever runtime retest: NOT RUN. The player's screenshot is evidence that 0.7.1 failed runtime acceptance; it is not evidence that 0.7.2 succeeds.
