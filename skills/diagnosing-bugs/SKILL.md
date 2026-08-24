---
name: diagnosing-bugs
description: Diagnosis loop for hard bugs and regressions. Use when the user says "diagnose" or "debug this", or reports something broken, throwing, failing, or slow. Routes UI symptoms to diagnosing-ui, perf and leaks to test-perf-leaks, corruption to composer-forensics, CI flakes to trunk-quarantine.
---

# Diagnosing Bugs

Forked from `mattpocock-skills:diagnosing-bugs` 1.2.3, with DXOS instruments swapped into Phase 1 and the repro contract pulled up from the dxos repo's `debugging-ui`. Diff against the upstream plugin skill when re-syncing.

A discipline for hard bugs. Skip phases only when explicitly justified.

## Route first

| Symptom | Also load |
| --- | --- |
| Rendering, layout, scroll, flicker, styling, interaction, focus, reactivity | `diagnosing-ui` |
| Slow suite, memory growth across a run | `test-perf-leaks` |
| Data loss, corruption, profile won't boot | `composer-forensics` |
| Red CI that might be flaky | `trunk-quarantine` |
| Live Composer session misbehaving, user at the keyboard | `composer-debug` |

The phases below still govern the routed work; the branch skill supplies instruments and domain gotchas, not a different process.

## The repro contract — first message, every bug

Your first message on any bug report MUST contain this block, slots filled:

```text
Repro contract
1. User repro: <steps / story / recording, or "not provided yet">
2. My candidate repro: <numbered steps + the measurement that detects the failure>
3. Acceptance criteria: <what observation, in which environment, counts as fixed>
```

Do not block on the answer. Send the block, keep working with your candidate repro, reconcile the moment they reply. Their repro encodes environment state (experiments enabled, profile data, scroll position) you would otherwise burn hours rediscovering, and a repro you invent alone may reproduce a bug that is not their bug. If your repro later turns out not to match their symptom, say so immediately; the contract is renegotiated, not silently swapped.

## Redact

This skill has you show commands, outputs and captured artifacts. Redact every secret first: write `<REDACTED>` in its place. Build loops against env vars so the credential stays in the environment. Captured artifacts carry auth headers: quote only the lines that carry the signal.

## Phase 1: Build a feedback loop

**This is the skill.** Everything else is mechanical. If you have a **tight** pass/fail signal that goes red on _this_ bug, you will find the cause; bisection, hypothesis-testing, and instrumentation all just consume it. Without one, no amount of staring at code will save you. Spend disproportionate effort here. Be aggressive. Refuse to give up.

### DXOS instruments, in cost order

1. **vitest test at the package seam** (`module.test.ts`; `test('…', ({ expect }) => …)`). Cheapest loop and already the repo's regression net.
2. **Browser-mode vitest** (`*.browser.test.ts`) when the path needs a real browser or the dedicated worker. Logs land in `<package>/test-browser.log` (see `instrumentation`).
3. **Storybook story + play script**, fixture-first, for component/container behavior.
4. **Playwright spec against composer-app** (`browser-e2e-tests` skill; target `data-testid` only).
5. **Browser MCP against a dev server**, for the bug as the user actually sees it.
6. **`composer-debug` loopback port** against the user's live session, when the bug lives in their profile.
7. **Bisection harness.** The bug appeared between two known states: automate "check at state X" and `git bisect run` it.
8. **Differential loop.** Same input through old vs new code (or two configs); diff outputs.
9. **The user.** Last resort; batched, precise, counted (see `diagnosing-ui` interaction budget).

Check what is already listening before starting servers (`lsof -nP -iTCP -sTCP:LISTEN`). A server you did not start is never yours to kill or restart, and `pkill` by pattern reaches across every worktree and session on the machine.

### Tighten the loop

Once you have _a_ loop, tighten it: faster (cache setup, narrow the scope), sharper (assert the specific symptom, not "didn't crash"), more deterministic (pin time, seed RNG — `TestClock`, never sleep/poll). A 30-second flaky loop is barely better than no loop; a 2-second deterministic one is a debugging superpower.

Non-deterministic bugs: the goal is a higher reproduction rate, not a clean repro. Loop the trigger 100×, parallelise, add stress, narrow timing windows. A 50% flake is debuggable; 1% is not.

### Completion criterion: a tight loop that goes red

Phase 1 is done when you can name **one command** you have **already run at least once** (show the invocation and its output, redacted) that is:

- [ ] **Red-capable**: drives the actual bug path and asserts the user's exact symptom, so it can go red on this bug and green once fixed. Not "runs without erroring".
- [ ] **Deterministic**: same verdict every run (flaky bugs: a pinned, high reproduction rate).
- [ ] **Fast**: seconds, not minutes.
- [ ] **Agent-runnable**: you can run it unattended.

If you catch yourself reading code to build a theory before this command exists, stop: jumping straight to a hypothesis is the exact failure this skill prevents. No red-capable command, no Phase 2.

### When you genuinely cannot build a loop

Stop and say so explicitly. List what you tried. Ask the user for environment access, a redacted captured artifact, or permission to add temporary instrumentation. Do not proceed to hypothesise without a loop.

## Phase 2: Reproduce + minimise

Run the loop; watch it go red. Confirm it produces the failure the **user** described (wrong bug = wrong fix), reproducibly, with the exact symptom captured.

Then shrink to the smallest scenario that still goes red: cut inputs, callers, config, data, and steps one at a time, re-running after each cut. Done when every remaining element is **load-bearing**: removing any one makes the loop go green. The minimal repro shrinks Phase 3's hypothesis space and becomes Phase 5's regression test.

## Phase 3: Hypothesise

Generate **3–5 ranked, falsifiable hypotheses** before testing any of them. Single-hypothesis generation anchors on the first plausible idea. Each must state its prediction:

> "If <X> is the cause, then <changing Y> will make the bug disappear / <changing Z> will make it worse."

If you cannot state the prediction, the hypothesis is a vibe: discard or sharpen it. Show the ranked list to the user before testing — domain knowledge re-ranks instantly ("we just deployed #3") — but do not block; proceed with your ranking if they are AFK.

## Phase 4: Instrument

Each probe maps to one specific prediction. Change one variable at a time. Use the `instrumentation` skill: `@dxos/log` lines tagged `[DEBUG H<n>]` (n = hypothesis number) inside `#region DEBUG` blocks, queried from `app.log` / `test.log` / `test-browser.log`. Never `console.log`, never "log everything and grep". Prefer a breakpoint or REPL where the environment supports one: one breakpoint beats ten logs.

Perf regressions: logs are usually wrong. Establish a baseline measurement first (`test-perf-leaks` profile, timing harness), then bisect. Measure first, fix second.

## Phase 5: Fix + regression test

Write the regression test **before** the fix, at a **correct seam**: one where the test exercises the real bug pattern as it occurs at the call site. Follow `code-style` § Testing: extend an existing suite over creating a new one, test at the natural public API level, events over polling.

If the only available seam is too shallow to replicate the trigger chain, a test there gives false confidence. **No correct seam is itself the finding**: note it and flag it — the architecture is preventing the bug from being locked down.

With a seam: turn the minimised repro into a failing test → watch it fail → fix → watch it pass → re-run the Phase 1 loop against the original, un-minimised scenario.

## Phase 6: The golden rule + cleanup

After **every** code change, not just the last, state in your report:

1. **Outcome** — what did this change do, and can we measure it? An intervention whose outcome you cannot observe taught nothing; revert it rather than stacking the next one on top.
2. **Quality** — does every change currently in the tree improve the system? Instrumentation is exempt (marked and removed); guards, workarounds, and "temporary" patches are not.
3. **Complexity** — added complexity is evidence you are patching a symptom at the wrong level; prefer the change that deletes the defective coupling.

Before declaring done:

- [ ] Original repro no longer reproduces (re-run the Phase 1 loop)
- [ ] Regression test passes (or the absence of a seam is documented)
- [ ] All `#region DEBUG` blocks removed (grep the marker across touched files)
- [ ] Throwaway harnesses deleted
- [ ] The winning hypothesis stated in the commit / PR message, so the next debugger learns
