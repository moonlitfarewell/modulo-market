# Modulo Market Runtime Audit 0.0.9 — scanner load failure correction

**Date:** 2026-11-10  
**Addon:** Modulo Market 0.0.9  
**Parent:** MODULO 1.0.48 (unchanged)  
**Release type:** focused runtime-defect fix; standalone optional child addon.

## Player problem and observable result

On 0.0.8, `/mm` produced: `ModuloMarket: Market scanner UI is not ready.` This is a player-visible failure of the core Market scanner UI and takes priority over throttle optimization and other features.

## Exact evidence

- Player supplied the exact in-game message.
- 0.0.8 `Core.lua` prints this message only when `/mm` executes and `MM.Scanner` or `MM.Scanner.Toggle` is absent.
- 0.0.8 TOC loads `Core.lua` before `Scanner.lua`.
- 0.0.8 `Scanner.lua` contained an `OnEvent` anonymous function whose event conditional was not closed before the function terminator. The source ended:
  ```
      elseif event == "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED" then
          if Scanner.active then Abort("Auction House throttle dropped a request") end
      end)
  ```
  The `end)` closes the event conditional but leaves the anonymous function unclosed. This is a Lua syntax error. The scanner chunk therefore cannot load and never reaches `MM.Scanner = Scanner`.
- The same area contained a literal escaped `\n` inside a comment, which commented out `scroll:SetScrollChild(edit)`. This secondary UI issue is corrected too.

## Competing hypotheses and distinguishing evidence

1. **Scanner.lua parse failure:** a syntax error prevents the file from executing, leaving `MM.Scanner` nil. The missing `end` is direct source evidence and is the leading/root-cause diagnosis.
2. **Scanner.lua runtime initialization failure or TOC/load-order issue:** the file parses but errors before assigning `MM.Scanner`, or slash command executes before the file is initialized. This would normally produce a runtime Lua error rather than the source-level missing-`end` syntax failure. The TOC order is Core, Scanner, Diagnostics; this is not the best-supported explanation.

A target-client Lua error capture would corroborate the parser line, but the source defect is sufficient to correct the obvious blocker. A real client retest remains required.

## 0.0.9 changes

- Added the missing `end` to close the `OnEvent` callback's event conditional and anonymous function correctly.
- Restored `scroll:SetScrollChild(edit)` as executable code rather than leaving it inside an escaped-newline comment.
- Bumped Market TOC, Core version and manifest together to 0.0.9.
- Added regression checks for event-handler closure, TOC file order, `MM.Scanner`/`Scanner.Toggle` wiring and scroll-child setup.
- Retained 0.0.8 throttle policy, timing instrumentation, SavedVariables last-known-good snapshot policy, JSON parts and Sell-tab safety gate without further changes.

## Ownership, compatibility and risk

- Market remains a separate optional addon with `Dependencies: Modulo`.
- MODULO 1.0.48 remains unchanged and does not depend on Market.
- No Auction House API behavior or throttle pacing is changed in this defect fix.
- No persistence semantics are changed.
- No Forever runtime result is inferred from source tests.

## Validation

- ZIP integrity and fresh extraction: see build output.
- Python source/regression tests: see build output.
- Lua parser/compiler: NOT RUN; no `lua`, `luac`, `luajit`, or Lua parser was available in the build environment.
- Forever runtime: NOT RUN for 0.0.9.
- Retail runtime: NOT RUN.
- Throttle speed improvement: NOT RUN / UNKNOWN.
- Full client restart persistence: NOT RUN / UNKNOWN.
- Scanner UI `/mm` acceptance: NOT RUN for 0.0.9.

## Acceptance / exit criteria

1. Install 0.0.9 over 0.0.8 and `/reload`.
2. Confirm the login chat reports Market loaded and `/mm` opens the scanner UI without the "UI is not ready" message or a Lua error.
3. Confirm a previously saved snapshot appears.
4. Confirm export UI opens and its scroll child behaves normally.
5. Start a full scan and confirm completion; inspect elapsed and throttle-wait measurements.
6. Confirm stopped scans preserve the previous snapshot.
7. Confirm full client restart restores the last completed snapshot.

**Status:** 0.0.8 scanner UI defect diagnosed from exact source and corrected in 0.0.9. Client acceptance remains required. The throttle optimization remains unverified.
