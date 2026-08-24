---
name: diagnosing-ui
description: UI branch of the diagnosing loop. Use when debugging any UI bug — wrong rendering, layout or scroll jumps, flicker, styling, interaction, focus/attention, or reactivity failures — in Composer plugins, react-ui components, storybook stories, or the running app. Applies from the first symptom report, before proposing any fix.
---

# Diagnosing UI

The UI branch of the `diagnosing-bugs` skill. That loop governs — repro contract first, tight red loop, minimise, 3–5 ranked hypotheses, golden rule after every change. This skill adds what is specific to bugs a browser renders: the instrument table, the isolation ladder, the verification contract, and the interaction budget.

Forked from the dxos repo's `debugging-ui`, with the generic phases evacuated into `diagnosing-bugs`.

## Core principle

**The user is the most expensive and least available instrument you have.** Every verification you can perform yourself — running a test, driving a browser, reading a frame trace — is strictly cheaper than asking the user to look. A debugging process that consumes user round-trips is a failing process even when it eventually finds the bug. One real session burned 13 user test-asks over 21 hours; every correction that worked came from the user, not the agent. This skill exists so that never happens again.

Violating the letter of these rules is violating their spirit.

## Instruments

| Instrument                                 | Use for                                                          |
| ------------------------------------------ | ---------------------------------------------------------------- |
| Unit tests (vitest)                        | State/logic isolation; cheapest repro                            |
| Storybook stories + play scripts           | Component/container behavior; deterministic fixtures             |
| Playwright / browser MCP against storybook | Gestures, frame traces, console, screenshots                     |
| Browser MCP against the running app        | The bug as the user actually sees it                             |
| Runtime log instrumentation                | See `instrumentation` (@dxos/log → app.log pipeline)             |
| The user                                   | Only what no tool can observe (their environment, their intent)  |

Server etiquette (check listeners first, never kill or `pkill` a server you did not start) is in `diagnosing-bugs` Phase 1. If you cannot drive a browser at all, say so in your first report and agree the verification protocol up front — do not discover this mid-loop.

## Check the classes are real before debugging the layout

A layout that is "wrong for no reason" is often a class that does not exist. The `tailwindcss-logical` dialect (`pis-*`, `pbs-*`, `pli-*`, `mis-*`, `is-*`, `bs-*`, `min-bs-*`, …) was dropped in the Tailwind v4 migration and compiles to **nothing** — no error, no lint, no warning.

Before forming a hypothesis about a spacing, sizing or overflow bug:

```bash
git diff | grep -nE '\b(p|m)(is|ie|bs|be|li|lb)-|\b(min-|max-)?(is|bs)-'
```

Then confirm in the browser rather than in the source: read the element's computed style and check the property is actually set. A class that produces no rule is invisible in the source and obvious in `getComputedStyle` — the cheapest probe, and the one to try first when the symptom is geometric. Replacement table in **composer-ui** § "Sizing vs logical utilities".

## The isolation ladder

Start at the level where the bug manifests — usually the app. **After 2–3 failed attempts at one level, step DOWN a level** and reproduce the bug in a smaller demo:

```text
app  →  storybook story (fixture-first)  →  unit test
```

- A failed attempt = an instrumented hypothesis test or candidate fix that did not change the observed symptom. Count them.
- Stepping down means building a progressively smaller demo of the same behavior — a story with the app's exact shape (fixture-first), then a unit test on the suspect state transition. If the lower-level story/test doesn't exist and would improve the codebase, write it; it becomes the regression net.
- **When two levels disagree** (story green, app broken), the divergence IS the diagnosis: diff the environments — structure, then conditions (attention traffic, scroll position, timing, real vs synthetic input) — and degrade one toward the other until the signatures match. Do not patch the symptom at the level that happens to be green.

## Verification contract

A bug is **fixed** only when the agreed repro passes — the original symptom observed gone, by you, in the environment where it was reported, measured the same way the repro measured the failure (frame trace, screenshot, console/log capture). Anything less is a **candidate fix**, and every status line — especially the one-sentence summary — must say so: "candidate fix — verified in <level>, not yet in <reporting environment>". Never write "fixed"/"resolved" on lower-level evidence, however strong. If the reporting environment needs state only the user has, first try to drive it yourself with browser tools; ask only if no tool reaches it.

- Storybook green ≠ done. Your own metric green ≠ done. Build/lint/tests green ≠ done.
- Rule out your own measurement artifacts (hidden tabs suspend rAF; synthetic `.click()` does not move attention/focus; smooth-scroll glides abort on reflow) before trusting a trace — and before blaming the code.
- Never propose removing a working feature as the fix; that is a symptom patch with the largest possible blast radius.

## Interaction budget

- **Answer any direct user question immediately**, before continuing work — even mid-investigation. An unanswered question outranks your current step.
- **Front-load asks.** At start, list everything only the user can provide — starting with "do you have a repro?" and the acceptance criteria, plus reproduction environment, gestures you cannot synthesize, credentials, judgment calls — and request it in one batch. An experiment that needs user feedback stalls by default — design it out.
- **Count your diagnostic asks** (reproduce / verify / observe requests). Budget: 3 per bug. When you hit it without having identified the problem, your process is failing — stop, say so, and discuss the approach itself with the user.
- Each ask must be: (a) precise — numbered steps, exact expected/actual observation; (b) maximally terse; (c) justified — state what the answer buys that no tool could.

## Report shape

Every status message to the user is, in order:

0. **Repro contract** — first message only; the block from `diagnosing-bugs`.
1. **Problem** — one sentence: the live sub-problem, not the original symptom. If you cannot state it, that is the finding: say "I do not have a solid plan" and what you'll do to get one.
2. **Plan** — the next 1–3 concrete steps and which instrument each uses.
3. **Golden rule** — after any code change: the outcome / quality / complexity assessment (`diagnosing-bugs` Phase 6).
4. **Ask** — nothing, or the batched precise asks (counted).

## Rationalizations — all of these mean STOP

| Excuse                                          | Reality                                                                          |
| ----------------------------------------------- | -------------------------------------------------------------------------------- |
| "Quicker to ask the user to check"              | 13 asks / 21 hours. Drive the browser yourself.                                  |
| "It passed in storybook, so it's fixed"         | It false-greened five times in one session. Verify in the reporting environment. |
| "My metric is green — declaring resolved"       | The user's symptom, in the user's environment, is the only exit criterion.       |
| "One more guard will catch this case"           | Six guards later the hook was deleted. Step down the ladder instead.             |
| "Simplest fix: drop the feature"                | Rejected on sight. Find the environment difference.                              |
| "I'll answer their question after this step"    | Answer it now. A missed direct question destroys trust.                          |
| "Another attempt at this level might work"      | You are at 3. The ladder exists because it won't.                                |
| "My repro reproduces it, so it's their bug"     | Yours may be a lookalike with different state. Reconcile against theirs.         |

## Red flags — self-check while working

- About to ask the user to reproduce/verify anything → can a tool observe it?
- About to write "fixed"/"resolved" → has the agreed repro passed, run by YOU, in the reporting environment?
- Third attempt at the same level → step down; build the smaller demo.
- Patch references attention/focus/timing you don't understand yet → hypothesis first (`diagnosing-bugs` Phase 3), fix second.

## Related skills

- `diagnosing-bugs` — the governing loop (repro contract, tight loop, minimise, hypotheses, golden rule, cleanup).
- `instrumentation` — @dxos/log runtime instrumentation pipeline for hypothesis testing at any ladder level.
- `composer-ui` — storybook setup and story conventions for new fixtures.
- `browser-e2e-tests` — Playwright targeting rules (data-testid) when a repro graduates to a regression spec.
