# Ledger and reports

Keep the ledger in `$SCRATCH/ledger.md` and rewrite it every round. It is the evidence for the convergence line, the progress rule, and the final report.

## Ledger

The numbers below are illustrative.

| Round | Act On | Areas flagged | Repeats | Regressions | Diff vs base | Diff vs start |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | | | | | +392/−168 | 0 |
| 1 | 5 | focus, drag, virtualizer anchor | 0 | 0 | +470/−175 | +78/−7 |
| 2 | 5 | virtualizer anchor, keyboard nav | 1 (r1) | 3 (r1) | +512/−181 | +120/−13 |

- **Areas flagged** names the mechanism, not the file: "virtualizer anchor", not `Tree.tsx`. A step-back gathers its stack by that name, so reuse names across rounds.
- **Repeats** counts Act On items the ledger already closed, with the round that closed them in parentheses.
- **Regressions** counts Act On items whose flagged lines an earlier round's fix wrote, with that round in parentheses.
- **Diff** columns are `git diff --shortstat` against `BASE` and against `snap-0`, as `+ins/−del`.

## Convergence line

Print one line after every round, before anything else:

```
Round 4: Act On 5 → 5 → 4 → 3, 2 new, 1 regression (virtualizer anchor, r3). Step-backs so far: none. Diff +588/−202 vs base, +196/−34 since start.
```

Write "all new" when the round has no repeats or regressions. If the line shows either, the next step is the step-back in SKILL.md, not another fix.

## Final report

1. **Fixes**, grouped by theme. One line each: what was wrong, what changed, which test covers it.
2. **Step-backs.** For each, the stack it replaced (finding and fix per round), the invariant, its owner, and the patches removed.
3. **Reverted attempts.** What was tried, which rounds flagged it, why it went, and what guard replaced it.
4. **Deferred.** The full list with each one-line reason. Mark the cheap nits.
5. **Tests.** Commands run and their results, and each new test's fails-without-the-fix check.
6. **Ledger**, the full table.
7. **Diff size** against `BASE` and against the loop's start.
8. **Commit options**, numbered, as in SKILL.md.
