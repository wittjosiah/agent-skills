# Ledger and reports

Keep the ledger in `$SCRATCH/ledger.md` and rewrite it every round. It is the evidence for the convergence line, the progress rule, and the final report.

## Ledger

The ledger has two parts: the round table and the fix log. The numbers and names below are illustrative.

### Round table

| Round | Act On | Areas flagged | Repeats | Regressions | Step-backs | Diff vs base | Diff vs start |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | | | | | | +392/−168 | 0 |
| 1 | 5 | focus, drag, virtualizer anchor, keyboard nav | 0 | 0 | | +392/−168 | 0 |
| 2 | 5 | virtualizer anchor, keyboard nav | 0 | 3 (F1) | S1 virtualizer anchor | +470/−175 | +78/−7 |

- **Areas flagged** names the mechanism, not the file: "virtualizer anchor", not `Tree.tsx`. Reuse names across rounds. Each fix-log entry carries its area, and step-backs are counted by the area of the entry a finding names, not the area it was flagged in.
- **Repeats** and **Regressions** count Act On items by class, with the fix-log entries they trace to in parentheses. Each item has one class, so new, repeats and regressions add up to Act On.
- **Step-backs** names each step-back entry this round added, with its area: the area of the entry its repeats and regressions named.
- A round that stopped still gets its row, with the Stop case in the Step-backs column.
- **Diff** columns are the two shortstats from Build the diff, as `+ins/−del`, with an empty one written as 0: the tree this round reviewed, against `BASE` and against `snap-0`. Round 1 reviews the start, so its row matches round 0. They are for the user and the final report; no rule reads them.

### Fix log

One entry per change the loop makes to the code: Act On fixes, Consider fixes, and step-back changes. Lint and test edits from Verify belong to the fix they follow. Classification reads this log: a repeat matches what an entry closed, and a regression names the entry that caused it. Entries are F1, F2, and so on for fixes, S1, S2 for step-backs.

```
- F1 (r1, virtualizer anchor, Act On). Closed: anchor offset lost when a row above resizes.
  Change: useAnchor.ts useAnchor caches the offset per row key. Test: keeps anchor on resize.
  Replaced by S1 (flagged r2).
- F2 (r1, keyboard nav, Act On). Closed: arrow-down skips collapsed rows' siblings.
  Change: Tree.tsx nextVisible walks the flattened list. Test: arrow-down after collapse. Live.
- F3 to F5 (r1): the other three round-1 fixes, in the same form.
- F6, F7 (r2, keyboard nav): round 2's two new items, in the same form.
- S1 (r2, virtualizer anchor, step-back). Stack: F1.
  Closed: anchor offset lost on resize (F1's), and anchor cache stale after collapse, after expand, and after a filter (regressions of F1).
  Invariant: the anchor offset is read from the live row, never from a value kept across renders.
  Owner: useAnchor.ts, the measure step. Removed: F1's per-key offset cache.
  Change: measure the anchor row on every layout pass. Tests: the resize test failed in round 1, under F1; the collapse, expand and filter tests fail at snap-2; all four pass with S1. Live.
```

Each entry names the files and functions it changed, so its hunks can be found in its round's fix diff. A replaced entry records the rounds that flagged it, for the final report.

## Convergence line

Print one line after every round, before anything else:

```
Round 4: Act On 5 → 5 → 4 → 3: 2 new, 0 repeats, 1 regression (F6, keyboard nav). Step-backs: S1 virtualizer anchor (r2), S2 keyboard nav (r4). Reviewed +588/−202 vs base, +196/−34 since start.
```

Write "all new" in place of the three counts when the round has no repeats or regressions, and "Step-backs: none" before the first one. Each repeat or regression has a step-back in the same round. If the round stopped instead, the line names the Stop case.

## Final report

1. **Fixes**, from the fix log's F entries, grouped by theme. One line each: what was wrong, what changed, which test covers it.
2. **Step-backs**, from the fix log's S entries: for each, the stack it replaced with the rounds that flagged each replaced entry, the invariant, its owner, and the change that replaced them.
3. **Deferred.** The full list with each one-line reason, promoted items marked. Mark the cheap nits.
4. **Tests.** Commands run and their results, each new test's fails-without-the-fix check, and the tests that had no red check.
5. **Ledger**, the full table.
6. **Diff size** against `BASE` and against the loop's start.
7. **Commit options**, numbered, as in SKILL.md.
