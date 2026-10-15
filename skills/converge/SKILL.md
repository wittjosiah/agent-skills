---
name: converge
description: "Loop interrogate review-and-fix rounds on one PR until a round has no Act On items. Keeps going while each round finds new defects, and replaces an area's patches with one root-cause fix when findings repeat or land in earlier fixes."
disable-model-invocation: true
---

# Converge

Run [interrogate](../interrogate/SKILL.md) in rounds on one change. Fix each round's Act On items, then review again, until a round comes back with none. Interrogate supplies the reviewers, the prompt, and the judgment framework. This skill adds the loop around them: a ledger, a convergence line every round, a progress rule with a step-back, and a stop.

The failure this guards against is fixes that breed findings. On [dxos/dxos#13367](https://github.com/dxos/dxos/pull/13367), round 1 applied Consider items as well as Act On. That grew scope, and three of round 2's five Act On items were regressions from those fixes. Rounds 4 to 7 each found a new hole in one mechanism, an anchor heuristic added in round 1. Each patch opened the next hole, and the diff grew from +392/−168 to +588/−202 before the user had to ask whether the loop was converging. It was not. Reverting that mechanism to main's behaviour plus one small guard ended it: round 8 had no Act On items, at +427/−186.

## Setup

Do this once, before round 1.

1. **Target.** A PR number, or the current branch's diff. Take the intent from the PR description, commits, and the conversation, as interrogate's Step 2 does. If the intent is unclear, ask for it before round 1. That is the only setup question.
2. **Scratch directory.** Use the session scratchpad if the system prompt names one, otherwise `mktemp -d`. Round prompts, snapshots, and the ledger live there. In the commands below, `$SCRATCH`, `$N`, and `$PR` stand for literal values you substitute.
3. **Baseline.** `git merge-base origin/main HEAD > $SCRATCH/base`, with the PR's base branch in place of main if it differs. `BASE` below means `$(<$SCRATCH/base)`.
4. **Settings.** Take each from the invocation or the conversation if the user set it, otherwise use the default. Do not ask.

   | Setting | Default | Alternative |
   | --- | --- | --- |
   | Scope | Act On only | Act On and Consider |
   | Commits during the loop | none | one per round |

   Print the settings in one line and carry on without waiting for a reply:

   > Converging on #13367: Act On only, no commits. Rounds run until one has no Act On items, with a step-back for any area that loops. Each round runs 3 reviewers at 5 to 14 minutes each. Interrupt to change any of these.

   Consider items are where scope grows. If the user brings them in, apply only the ones that change no behaviour outside the lines they name. Whatever the settings, keep the diff minimal.

   After this, ask nothing until one of the cases under Stop.
5. **Snapshot the start.** Write `snap-0` (see Build the diff) and record round 0 in the ledger with the diff size against `BASE`.

## Each round

### 1. Build the diff

Snapshot the working tree first, untracked files included, without touching the real index or committing:

```zsh
I=$SCRATCH/index
GIT_INDEX_FILE=$I git read-tree HEAD && GIT_INDEX_FILE=$I git add -A
git commit-tree $(GIT_INDEX_FILE=$I git write-tree) -p HEAD -m snap-$N > $SCRATCH/snap-$N
```

`snap-N` is the tree as round N's reviewers see it, before round N's fixes. Round k's fixes are therefore `git diff $(<$SCRATCH/snap-$k) $(<$SCRATCH/snap-$((k+1)))`, and the size against the loop's start is `git diff --shortstat $(<$SCRATCH/snap-0) $(<$SCRATCH/snap-$N)`. Shell variables do not survive between Bash calls, so `BASE` and every snapshot live in files.

Then diff from `BASE` to the snapshot, limited to the PR's files plus anything changed. In zsh, split the file list into an array or the diff comes out empty:

```zsh
SNAP=$(<$SCRATCH/snap-$N)
F=(${(f)"$( { gh pr diff $PR --name-only; git diff --name-only $BASE $SNAP; } | sort -u )"})
git diff $BASE $SNAP -- "${F[@]}" > $SCRATCH/round-$N.diff
git diff --shortstat $BASE $SNAP -- "${F[@]}"
```

Drop the `gh` line when the target is a branch, not a PR. Files created since `BASE` show in the diff in full.

### 2. Write the round prompt

Write one file, `$SCRATCH/round-$N-prompt.md`: interrogate's [reviewer-prompt.md](../interrogate/references/reviewer-prompt.md) filled as interrogate's Step 3 fills it (intent, diff, [rubric](../interrogate/references/rubric.md), [code-quality lens](../interrogate/references/code-quality-review.md)), with the three sections in [round-addendum.md](references/round-addendum.md) inserted after the intent. The addendum carries the changes since the last round, the scope rule, and the deferred list. Reviewers see only a slice of the code, so these go in the prompt itself.

### 3. Spawn the reviewers

Same table and settings as interrogate's Step 3: `opus`, `fable`, `sonnet`, `general-purpose`, foreground, all three in one message. Each agent's prompt is short:

> Read `<absolute path to round-N-prompt.md>` in full and follow it. This is a read-only review: modify no files, run no commands that write.

One file, read three times, in place of three pasted copies of the diff.

### 4. Judge, classify, fix

Apply [lead-judgment.md](../interrogate/references/lead-judgment.md), with three changes.

- **Verify every load-bearing claim in the source before you categorize it.** If a finding depends on library internals, React commit and effect order, or what a consumer does with a value, open that code and confirm it. A claim you have not checked is not Act On.
- **Hold the bar.** Act On means a defect by the Scope section of the round addendum, judged in round 6 as in round 1. The deferred list records where the bar sits: a finding of the same kind and weight as a deferred one is deferred too. Without a fixed bar, reviewers always find something and the loop never ends.
- **Apply only what setup put in scope.** Everything else goes on the deferred list with a one-line reason and the round it was ruled on. The list grows; nothing leaves it. A deferred item that a reviewer raises again with a concrete path the ruling missed is a new Act On item.

Classify each Act On item before fixing anything (see Progress). Fix the new items with the smallest change that closes each. A fix that adds a new mechanism, a heuristic, or a new state is the kind that regressed on #13367. Prefer removing the cause. Repeats and regressions get no fix of their own: they start a step-back on their area, in this round.

### 5. Verify

Run format, lint, typecheck, and the unit and storybook tests the fix touches. For each new test, check that it fails without the fix: revert the fix, run the test, see red, restore. A test that passes both ways goes back for rework.

### 6. Record and report

Add each fixed item to the ledger's Closed list, record any step-back, add a ledger row, and print the convergence line. Formats are in [ledger.md](references/ledger.md). Print the line every round, whether or not anything looks wrong, so the user never has to ask.

If commits are allowed, commit the round now.

## Progress

There is no round cap. The loop keeps going while each round makes progress, and ends when a round has no Act On items.

Give each Act On item exactly one class, testing in this order:

1. **Repeat.** It matches an entry on the ledger's Closed list: the same defect, at the same spot or by another path to it.
2. **Regression.** It sits in lines a fix wrote: lines that `git diff $(<$SCRATCH/snap-0) $(<$SCRATCH/snap-$N)` adds, which includes every file the loop created. The round that wrote them is the k whose fix diff (see Build the diff) adds them.
3. **New.** Everything else, including a deferred item re-raised on a new path.

The three counts add up to the round's Act On count.

A round whose Act On items are all new is progress. Counts that fall round over round are the healthy shape, but a round with more new items than the last is still progress, as long as the bar holds.

A repeat or a regression means its area thrashes. The loop is solving the same problem twice, or fixing its own fixes. That area is a patch stack. Each fix closed the finding in front of it and opened the next, because none of them touched the cause the findings share. Step back on that area, without asking. New items in other areas get fixed as usual in the same round.

### Step back

The stack is every fix on the Closed list in the area, plus any earlier step-back on it. A stack of one fix gets a short step-back. Name the invariant that fix should have kept, rewrite the fix from that invariant instead of patching it, and test the original finding and every new one against the rewrite, each failing without it. Record it in the ledger's Step-backs section. The next round is an ordinary round.

A stack of two or more fixes gets the full step-back:

1. **Lay out the stack.** Write down the area's baseline behaviour, then each fix in the stack: the finding it answered, and what later rounds found in it. Each round's fix diff, limited to the area's files, shows the code. Record the stack in the ledger's Step-backs section.
2. **Name the invariant.** Find the one requirement every finding in the stack broke, stated as a property of the code rather than a symptom: "an index row is placed by an open database exactly once, and a close drops it", not "rows before open throw". If the findings share no invariant, they are separate defects. Fix each on its own and record the step-back as "no shared invariant".
3. **Find its owner.** The owner is the one place that can enforce the invariant for every path through it: usually the earliest point the paths share, or the layer holding the state the invariant is about. Each patch in the stack guarded one path downstream of the owner.
4. **Design one change at the owner.** It replaces the stack, so the patches come out as it goes in. Reverting the mechanism to baseline is one candidate, and the right one when the mechanism itself is the cause, as the anchor heuristic was on #13367. Check the design against every finding in the stack, not only the latest, and write one line per finding on why it cannot recur. A design that only adds code on top of the stack is another patch.
5. **Test the invariant.** Keep or write a test for each finding in the stack, and check each fails without the change. Where one test can show the invariant, prefer it to several that each show a symptom.
6. **Run the next round as a step-back round.** The round addendum states the invariant and lists the patches removed, so reviewers attack the invariant rather than the last diff.

The step-back's change goes on the Closed list like any fix. A later finding in it is classified the usual way, and a regression there starts the area's next step-back, whose stack includes this one.

## Stop

The loop ends or pauses in four cases:

- **Converged.** A round has no Act On items. Go to the final report.
- **The step-back leaves the change.** The invariant conflicts with the stated intent, or its owner lies outside the code the change touches. Present the stack, the invariant, the owner and the design, and ask whether to widen the scope, revert the mechanism to baseline, or stop. Carry on as told.
- **A step-back failed.** A later finding breaks the invariant a full step-back named, or repeats a finding from the stack it replaced. Stop and ask, with the stack, the invariant and the design in front of the user.
- **An area needs a third step-back.** Two step-backs did not settle it. Stop and ask, with both stacks in front of the user.

## Final report

Before any commit, report in the format in [ledger.md](references/ledger.md): fixes grouped by theme, step-backs and the patches they replaced, reverted attempts and why, the deferred list, test results, the ledger, and diff size against `BASE` and against the loop's start. End with numbered commit options:

> 1. Commit as is.
> 2. Fold in the cheap deferred nits first (list them), then commit.
> 3. Hold for your review; nothing committed.
