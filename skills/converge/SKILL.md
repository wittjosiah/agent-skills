---
name: converge
description: "Loop interrogate review-and-fix rounds on one PR until a round has no Act On items. Fixes new defects as they come, and when a finding repeats one already fixed or was caused by an earlier fix, replaces that fix with one root-cause change."
disable-model-invocation: true
---

# Converge

Run [interrogate](../interrogate/SKILL.md) in rounds on one change. Fix each round's Act On items, then review again, until a round comes back with none. Interrogate supplies the reviewers, the prompt, and the judgment framework. This skill adds the loop around them: a ledger with a fix log, a convergence line every round, a progress rule with a step-back, and a stop.

The failure this guards against is fixes that breed findings. On [dxos/dxos#13367](https://github.com/dxos/dxos/pull/13367), round 1 applied Consider items as well as Act On. That grew scope, and three of round 2's five Act On items were regressions from those fixes. Rounds 4 to 7 each found a new hole in one mechanism, an anchor heuristic added in round 1. Each patch opened the next hole, and the diff grew from +392/−168 to +588/−202 before the user had to ask whether the loop was converging. It was not. Reverting that mechanism to main's behaviour plus one small guard ended it: round 8 had no Act On items, at +427/−186.

## Setup

Do this once, before round 1.

1. **Target.** A PR number, or the current branch's diff. Take the intent from the PR description, commits, and the conversation, as interrogate's Step 2 does. If the intent is unclear, ask for it before round 1. That is the only setup question.
2. **Scratch directory.** Use the session scratchpad if the system prompt names one, otherwise `mktemp -d`. Round prompts, snapshots, and the ledger live there. In the commands below, `$SCRATCH`, `$N`, and `$k` stand for literal values you substitute.
3. **Baseline.** `git merge-base origin/main HEAD > $SCRATCH/base`, with the PR's base branch in place of main if it differs. `BASE` below means `$(<$SCRATCH/base)`.
4. **Settings.** Take each from the invocation or the conversation if the user set it, otherwise use the default. Do not ask.

   | Setting | Default | Alternative |
   | --- | --- | --- |
   | Scope | Act On only | Act On and Consider |
   | Commits during the loop | none | one per round |

   Print the settings in one line and carry on without waiting for a reply:

   > Converging on #13367: Act On only, no commits. Rounds run until one has no Act On items, with a step-back wherever a fix causes or repeats a finding. Each round runs 3 reviewers at 5 to 14 minutes each. Interrupt to change any of these.

   Consider items are where scope grows. If the user brings them in, apply only the ones that change no behaviour outside the lines they name. Whatever the settings, keep the diff minimal.

   After this, ask nothing until one of the cases under Stop.
5. **Clear strays.** Snapshots take every untracked file that is not ignored. Run `git status` and move out or ignore anything that is not part of the change, such as notes or test output. Keep it that way through the loop.
6. **Snapshot the start.** Write `snap-0` (see Build the diff) and record round 0 in the ledger with the diff size against `BASE`.

## Each round

### 1. Build the diff

Snapshot the working tree, untracked files included, without touching the real index or committing:

```zsh
I=$SCRATCH/index
GIT_INDEX_FILE=$I git read-tree HEAD &&
  GIT_INDEX_FILE=$I git add -A &&
  t=$(GIT_INDEX_FILE=$I git write-tree) &&
  git commit-tree $t -p HEAD -m snap-$N > $SCRATCH/snap-$N &&
  [[ -s $SCRATCH/snap-$N ]] || echo "snap-$N FAILED"
```

If it prints `FAILED`, fix the cause and snapshot again. A failed snapshot looks like every fix was reverted.

`snap-N` is the tree round N's reviewers see, before round N's fixes. Round k's fixes are `git diff $(<$SCRATCH/snap-$k) $(<$SCRATCH/snap-$((k+1)))`. Shell variables do not survive between Bash calls, so `BASE` and every snapshot live in files.

Then diff from `BASE` to the snapshot:

```zsh
SNAP=$(<$SCRATCH/snap-$N)
git diff $BASE $SNAP > $SCRATCH/round-$N.diff
git diff --shortstat $BASE $SNAP
git diff --shortstat $(<$SCRATCH/snap-0) $SNAP
```

The two shortstats are this round's ledger diff columns. Files created since `BASE` show in the diff in full.

### 2. Write the round prompt

Write one file, `$SCRATCH/round-$N-prompt.md`: interrogate's [reviewer-prompt.md](../interrogate/references/reviewer-prompt.md) filled as interrogate's Step 3 fills it (intent, diff, [rubric](../interrogate/references/rubric.md), [code-quality lens](../interrogate/references/code-quality-review.md)), with the three sections in [round-addendum.md](references/round-addendum.md) inserted after the intent. The addendum carries the last round's fixes, the scope rule, and the deferred list. Reviewers see only a slice of the code, so these go in the prompt itself.

### 3. Spawn the reviewers

Same table and settings as interrogate's Step 3: `opus`, `fable`, `sonnet`, `general-purpose`, foreground, all three in one message. Each agent's prompt is short:

> Read `<absolute path to round-N-prompt.md>` in full and follow it. This is a read-only review: modify no files, run no commands that write.

One file, read three times, in place of three pasted copies of the diff.

### 4. Judge, classify, fix

Apply [lead-judgment.md](../interrogate/references/lead-judgment.md), with these changes.

- **Verify every load-bearing claim in the source before you categorize it.** If a finding depends on library internals, React commit and effect order, or what a consumer does with a value, open that code and confirm it. A claim you have not checked is not Act On.
- **Hold the bar.** Act On means a defect by the Scope section of the round addendum, judged in round 6 as in round 1. Defer only by that bar, never to bring the count down: lead-judgment's warning about more than 5 Act On items does not apply here. The deferred list records where the bar sits, so a finding of the same kind and weight as a deferred one is deferred too. Without a fixed bar, reviewers always find something and the loop never ends.
- **Apply only what setup put in scope.** Everything else goes on the deferred list with a one-line reason that cites the bar, and the round it was ruled on. The list grows; nothing leaves it.

Then, in order:

1. **Classify** every Act On item as a repeat, a regression, or new (see Progress).
2. **Check Stop** for each repeat and regression. If a Stop case applies, stop there.
3. **Step back** on each area that has a repeat or regression. A new item in the same area goes into that step-back, whose change must close it too.
4. **Fix the other new items** with the smallest change that closes each. A fix that adds a new mechanism, a heuristic, or a new state is the kind that regressed on #13367. Prefer removing the cause.

Every change you make to the code gets a fix-log entry (see [ledger.md](references/ledger.md)): Act On fixes, Consider fixes, step-back changes. Edits made in step 5 to pass lint or tests belong to the fix they follow.

### 5. Verify

Run format, lint, typecheck, and the unit and storybook tests the fixes touch. Every fix lands with a test that fails without it: revert the fix, run the test, see red, restore. A test that passes both ways goes back for rework.

### 6. Record and report

Update the fix log, add a ledger row, and print the convergence line. Formats are in [ledger.md](references/ledger.md). Print the line every round, whether or not anything looks wrong, so the user never has to ask.

If commits are allowed, commit the round now.

## Progress

There is no round cap. The loop runs until a round has no Act On items, or a Stop case applies.

Give each Act On item exactly one class, by what caused it, testing in this order:

1. **Repeat.** It is a defect a fix-log entry already closed, at the same spot or by another path to the same broken requirement. Name the entry.
2. **Regression.** A fix in the log caused it: the defect would not exist without that fix. The fix's hunks are the evidence. The execution path runs through lines it added, or through something it removed or changed, such as a deleted guard or a new contract a caller breaks. Name the entry. A finding that a fix has no test is not a regression: add the test under that entry. A finding caused by a step-back's change is a regression only when it fails that step-back (see below); otherwise it is new.
3. **New.** Everything else, including a deferred item re-raised with a path the ruling missed.

The three counts add up to the round's Act On count.

A round whose Act On items are all new is progress. Counts that fall round over round are the healthy shape, but a round with more new items than the last is still progress, as long as the bar holds.

A repeat or a regression means the loop is solving a problem twice or fixing its own fixes. The fix it traces to is a patch: it closed the finding in front of it without touching the cause. Step back on that fix's area before patching anything there, without asking.

A step-back's change becomes the baseline for its area. A later finding it caused is a failure of that step-back if it breaks the invariant the step-back named or repeats an item from its stack. Otherwise the finding is new.

### Step back

1. **Lay out the stack.** List every live fix in the area from the fix log, with the area's baseline behaviour first. The stack is the fixes this round's repeats and regressions trace to, plus any other fix there that guards the same invariant (step 2 finds them). Each round's fix diff, limited to the area's files, shows the code.
2. **Name the invariant.** Find the one requirement every finding in the stack broke, stated as a property of the code rather than a symptom: "an index row is placed by an open database exactly once, and a close drops it", not "rows before open throw". For a stack of one fix, it is the requirement that fix should have kept. If two traced fixes share no invariant, split them into separate step-backs.
3. **Find its owner.** The owner is the one place that can enforce the invariant for every path through it: usually the earliest point the paths share, or the layer holding the state the invariant is about. Each patch in the stack guarded one path downstream of the owner.
4. **Design one change at the owner.** It replaces the stack, so the patches come out as it goes in. Reverting the mechanism to baseline is one candidate, and the right one when the mechanism itself is the cause, as the anchor heuristic was on #13367. Check the design against every finding in the stack and every new item folded in, and write one line per finding on why it cannot recur. A design that only adds code on top of the stack is another patch.
5. **Test the invariant.** Keep or write a test for each finding in the stack, and check each fails without the change. Where one test can show the invariant, prefer it to several that each show a symptom.
6. **Log it.** The change gets one fix-log entry, with the stack, invariant and owner. The stack's entries are marked replaced by it.
7. **Run the next round as a step-back round.** The round addendum states the invariant and lists the patches removed, so reviewers attack the invariant rather than the last diff.

## Stop

Check these before any step-back. The loop ends or pauses in four cases:

- **Converged.** A round has no Act On items. Go to the final report.
- **The step-back leaves the change.** The invariant conflicts with the stated intent, or its owner lies outside the code the change touches. Present the stack, the invariant, the owner and the design, and ask whether to widen the scope, revert the mechanism to baseline, or stop. Carry on as told.
- **A step-back failed.** A finding caused by a step-back's change breaks its invariant or repeats an item from its stack. Stop and ask, with the stack, the invariant and the design in front of the user.
- **An area needs a third step-back.** Two step-backs did not settle it. Stop and ask, with both stacks in front of the user.

## Final report

Before any commit, report in the format in [ledger.md](references/ledger.md): fixes grouped by theme, step-backs and the patches they replaced, reverted attempts and why, the deferred list, test results, the ledger, and diff size against `BASE` and against the loop's start. End with numbered commit options:

> 1. Commit as is.
> 2. Fold in the cheap deferred nits first (list them), then commit.
> 3. Hold for your review; nothing committed.
