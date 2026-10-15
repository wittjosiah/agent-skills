# Ledger and reports

Keep the ledger in `$SCRATCH/ledger.md` and rewrite it every round. It is the evidence for the convergence line, the progress rule, and the final report.

## Ledger

The ledger has three parts: the round table, the Closed list, and the Step-backs section. The numbers and names below are illustrative.

### Round table

| Round | Act On | Areas flagged | Repeats | Regressions | Step-back | Diff vs base | Diff vs start |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | | | | | | +392/−168 | 0 |
| 1 | 5 | focus, drag, virtualizer anchor | 0 | 0 | | +470/−175 | +78/−7 |
| 2 | 5 | virtualizer anchor, keyboard nav | 0 | 3 (r1) | virtualizer anchor, short | +498/−180 | +106/−12 |

- **Areas flagged** names the mechanism, not the file: "virtualizer anchor", not `Tree.tsx`. A step-back gathers its stack by that name, so reuse names across rounds.
- **Repeats** counts Act On items that match the Closed list, with the round that closed them in parentheses.
- **Regressions** counts Act On items in lines a fix wrote, with the round that wrote them in parentheses. An item that is a repeat is not counted again here, so new, repeats and regressions add up to Act On.
- **Step-back** names each area stepped back on this round, and whether the step-back was short or full.
- **Diff** columns are `git diff --shortstat` against `BASE` and against `snap-0`, as `+ins/−del`. They are for the user and the final report; no rule reads them.

### Closed list

One line per fixed Act On item, added in the round that fixed it. Step-back changes go here too. Repeat matching reads this list, and a step-back's stack comes from it.

```
- Anchor offset lost when a row above resizes (virtualizer anchor, r1): useAnchor caches the offset per row key. Test: keeps anchor on resize.
- Arrow-down skips collapsed rows' siblings (keyboard nav, r1): nextVisible walks the flattened list. Test: arrow-down after collapse.
```

### Step-backs

One entry per step-back, short or full, including those that found no shared invariant.

```
- virtualizer anchor, r2, short.
  Stack: r1 cached the offset per row key (useAnchor); r2 found the cache stale after collapse, after expand, and after a filter.
  Invariant: the anchor offset is read from the live row, never from a value kept across renders.
  Owner: useAnchor's measure step.
  Removed: the per-key offset cache.
  Change: measure the anchor row on every layout pass. Tests: all four findings fail without it.
```

## Convergence line

Print one line after every round, before anything else:

```
Round 4: Act On 5 → 5 → 4 → 3: 2 new, 0 repeats, 1 regression (keyboard nav, r3). Step-backs: virtualizer anchor (r2, short), keyboard nav (r4, full). Diff +588/−202 vs base, +196/−34 since start.
```

Write "all new" in place of the three counts when the round has no repeats or regressions, and "Step-backs: none" before the first one. Every repeat or regression in the line has a step-back on its area in the same round.

## Final report

1. **Fixes**, from the Closed list, grouped by theme. One line each: what was wrong, what changed, which test covers it.
2. **Step-backs**, from the Step-backs section: for each, the stack it replaced, the invariant, its owner, and the patches removed.
3. **Reverted attempts.** What was tried, which rounds flagged it, why it went, and what guard replaced it.
4. **Deferred.** The full list with each one-line reason. Mark the cheap nits.
5. **Tests.** Commands run and their results, and each new test's fails-without-the-fix check.
6. **Ledger**, the full table.
7. **Diff size** against `BASE` and against the loop's start.
8. **Commit options**, numbered, as in SKILL.md.
