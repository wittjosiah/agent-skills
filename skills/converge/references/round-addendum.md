# Round addendum

Three sections added to interrogate's reviewer prompt, placed after `## Intent`. Fill the placeholders and keep the wording otherwise as is.

---

## Round {N}

This is round {N} of a review-and-fix loop on one change. The code under review includes the author's uncommitted fixes from earlier rounds. Since round {N-1}, the author changed:

{CHANGES_SINCE_LAST_ROUND}

Recent fixes are where new defects hide. Review these changes first and hardest: trace each one through its callers and through the state it reads and writes, then review the rest.

## Scope

Report only defects in code this change adds or modifies. A defect is behaviour that is wrong for the stated intent: a bug, a regression against the base branch, a broken invariant, or a fixed bug with no test. Leave out new features, refactors to taste, and improvements to code the change does not touch, even when you are confident in them.

## Already ruled on

The lead has already judged these out of scope or not defects. Raise one again only if you have a concrete execution path the ruling missed, and say what is new.

{DEFERRED_LIST}

---

## Filling it

- **`{CHANGES_SINCE_LAST_ROUND}`**: one bullet per change, from the diff between the last two snapshots. Name the file and function, what the code now does, and which finding it answered. Include reverts. In round 1, replace the whole paragraph with "This is round 1; there are no earlier fixes."
- **`{DEFERRED_LIST}`**: one bullet per item, `<finding> (round K): <one-line reason>`. Empty in round 1: write "None yet."
- **New untracked files**: after the diff, list their absolute paths under "Read these new files in full".
