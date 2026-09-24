# Ledger and reports

Keep the ledger in `$SCRATCH/ledger.md` and rewrite it every round. It is the evidence for the convergence line, the thrash rule, and the final report.

## Ledger

The numbers below are illustrative.

| Round | Act On | Areas flagged | Regressions | Diff vs base | Diff vs start |
| --- | --- | --- | --- | --- | --- |
| 0 | | | | +392/−168 | 0 |
| 1 | 5 | focus, drag, virtualizer anchor | 0 | +470/−175 | +78/−7 |
| 2 | 5 | virtualizer anchor, keyboard nav | 3 (r1) | +512/−181 | +120/−13 |

- **Areas flagged** names the mechanism, not the file: "virtualizer anchor", not `Tree.tsx`. Thrash is detected by the same name recurring, so reuse names across rounds.
- **Regressions** counts Act On items whose flagged lines an earlier round's fix wrote, with that round in parentheses.
- **Diff** columns are `git diff --shortstat` against `BASE` and against `snap-0`, as `+ins/−del`.

## Convergence line

Print one line after every round, before anything else:

```
Round 4 of 5: Act On 5 → 5 → 4 → 1. Thrash: virtualizer anchor, rounds 3 and 4. Own-fix regressions: 4 of 15. Diff +588/−202 vs base, +196/−34 since start.
```

Write "Thrash: none" when nothing thrashes. If the line shows thrash, the next message is the thrash question from SKILL.md, not another fix.

## Final report

1. **Fixes**, grouped by theme. One line each: what was wrong, what changed, which test covers it.
2. **Reverted attempts.** What was tried, which rounds flagged it, why it went, and what guard replaced it.
3. **Deferred.** The full list with each one-line reason. Mark the cheap nits.
4. **Tests.** Commands run and their results, and each new test's fails-without-the-fix check.
5. **Ledger**, the full table.
6. **Diff size** against `BASE` and against the loop's start.
7. **Commit options**, numbered, as in SKILL.md.
