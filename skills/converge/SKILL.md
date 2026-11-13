---
name: converge
description: "Loop interrogate review-and-fix rounds on one PR until a full-panel round has no Act On items. Fixes new defects as they come, and when a finding repeats one already fixed or was caused by an earlier fix, replaces that fix with one root-cause change."
disable-model-invocation: true
---

# Converge

Run [interrogate](../interrogate/SKILL.md) in rounds on one change. Fix each round's Act On items, then review again, until a round comes back with none. Interrogate supplies the reviewers, the prompt, and the judgment framework. This skill adds the loop around them: a ledger with a fix log, a convergence line every round, a progress rule with a step-back, and a stop.

The failure this guards against is fixes that breed findings. On [dxos/dxos#13367](https://github.com/dxos/dxos/pull/13367), round 1 applied Consider items as well as Act On. That grew scope, and three of round 2's five Act On items were regressions from those fixes. Rounds 4 to 7 each found a new hole in one mechanism, an anchor heuristic added in round 1. Each patch opened the next hole, and the diff grew from +392/−168 to +588/−202 before the user had to ask whether the loop was converging. It was not. Reverting that mechanism to main's behaviour plus one small guard ended it: round 8 had no Act On items, at +427/−186.

## Setup

Do this once, before round 1.

1. **Target.** A PR number, or the current branch's diff. Take the intent from the PR description, commits, and the conversation, as interrogate's Step 2 does. If the intent is unclear, ask for it before round 1. That is the only setup question.
2. **Scratch directory.** Use the session scratchpad if the system prompt names one, otherwise `mktemp -d`. Round prompts, snapshots, and the ledger live there. In the commands below, `$SCRATCH` and `$N` stand for literal values you substitute. Every block starts at the repo root.
3. **Baseline.** `git merge-base origin/main HEAD > $SCRATCH/base`, with the PR's base branch in place of main if it differs. Shell variables do not survive between Bash calls, so each command block below reads `BASE` back from that file.
4. **Settings.** Take each from the invocation or the conversation if the user set it, otherwise use the default. Do not ask.

   | Setting | Default | Alternative |
   | --- | --- | --- |
   | Scope | Act On only | Act On and Consider |
   | Commits during the loop | none | one per round |

   Print the settings in one line and carry on without waiting for a reply:

   > Converging on #13367: Act On only, no commits. Rounds run until a full-panel round has no Act On items, with a step-back wherever a finding repeats a fixed defect or was caused by a fix. Fix rounds run 2 reviewers at medium effort on the last fixes, step-back rounds run 2 at xhigh on the step-back, and the first and confirm rounds run 3 on the whole diff. Interrupt to change any of these.

   Consider items are where scope grows. If the user brings them in, apply only the ones that change no behaviour outside the lines they name. Whatever the settings, keep the diff minimal.

   After this, ask nothing until one of the cases under Stop.
5. **List strays.** Snapshots take every untracked file that is not ignored. Run `git -C "$(git rev-parse --show-toplevel)" ls-files -z --others --exclude-standard | tr '\0' '\n'`, which prints every name unquoted, and write each untracked path that is not part of the change, such as notes or test output, on its own line in `$SCRATCH/strays`, exactly as listed. Each line is a literal path. Snapshots and commits leave them out. The repo, its config, and the user's files stay as they are.
6. **Snapshot the start.** Write `snap-0` (see Build the diff) and record round 0 in the ledger with the diff size against `BASE`.

## Each round

### 0. Pick the round's kind

The kind sets the reviewers, their effort, and the diff they get. Pass the effort as the Agent tool's `effort` parameter.

| Kind | When | Reviewers | Effort | Code under review |
| --- | --- | --- | --- | --- |
| First | Round 1 | `opus`, `fable`, `sonnet` | `high` | Full diff |
| Fix | The last round fixed items and applied no step-back | `opus`, `sonnet` | `medium` | Last round's fixes |
| Step-back | The last round applied a step-back | `opus`, `fable` | `xhigh` | Last round's fixes |
| Confirm | The last round was a fix or step-back round with no Act On items | `opus`, `fable`, `sonnet` | `high` | Full diff |

First and confirm rounds are full-panel rounds. Only a full-panel round can converge. A step-back round reviews one invariant, not the whole change, so it needs depth more than a third model.

### 1. Build the diff

List untracked files the same way and add any new stray to `$SCRATCH/strays`, such as output from the last round's tests. Then snapshot the working tree, untracked files included, without touching the real index or committing. Starting from a copy of the real index keeps its file stats, so only changed files get hashed:

```zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
I=$SCRATCH/index
{ cp "$(git rev-parse --git-path index)" $I 2>/dev/null || GIT_INDEX_FILE=$I git read-tree HEAD; } &&
  GIT_INDEX_FILE=$I git add -A &&
  { p=$(grep -v '^[[:space:]]*$' $SCRATCH/strays 2>/dev/null | sed 's/^/:(literal)/'); [[ -z $p ]] || print -r -- $p | GIT_INDEX_FILE=$I git rm -r -q --cached --ignore-unmatch --pathspec-from-file=-; } &&
  t=$(GIT_INDEX_FILE=$I git write-tree) &&
  git commit-tree $t -p HEAD -m snap-$N > $SCRATCH/snap-$N &&
  [[ -s $SCRATCH/snap-$N ]] || { echo "snap-$N FAILED"; exit 1; }
```

If it prints `FAILED`, fix the cause and snapshot again. A failed snapshot looks like every fix was reverted.

`snap-N` is the tree round N's reviewers see, before round N's fixes. A round's fixes are the diff from its snapshot to the next: round 3's are `git diff $(<$SCRATCH/snap-3) $(<$SCRATCH/snap-4)`.

Then diff from `BASE` to the snapshot:

```zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
BASE=$(<$SCRATCH/base) SNAP=$(<$SCRATCH/snap-$N)
[[ -n $BASE && -n $SNAP ]] || { echo "BASE or snap-$N MISSING"; exit 1; }
git diff --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ $BASE $SNAP > $SCRATCH/round-$N.diff
[[ -s $SCRATCH/round-$N.diff ]] || { echo "round-$N diff EMPTY"; exit 1; }
git diff --shortstat $BASE $SNAP
git diff --shortstat $(<$SCRATCH/snap-0) $SNAP
```

If it prints `MISSING` or `EMPTY`, fix the cause and run it again. An empty diff gets no findings and looks like convergence. The two shortstats are this round's ledger diff columns; write an empty one as 0. Files created since `BASE` show in the diff in full.

In a fix or step-back round, also write the last round's fixes:

```zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
git diff --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ $(<$SCRATCH/snap-$((N-1))) $(<$SCRATCH/snap-$N) > $SCRATCH/round-$N-fixes.diff
[[ -s $SCRATCH/round-$N-fixes.diff ]] || echo "round-$N fixes EMPTY"
```

An empty fixes diff means the last round changed nothing, so it had no Act On items: run a confirm round instead.

### 2. Write the round prompt

Write one file, `$SCRATCH/round-$N-prompt.md`: interrogate's [reviewer-prompt.md](../interrogate/references/reviewer-prompt.md) filled with the intent, the code under review, and the [rubric](../interrogate/references/rubric.md), with the three sections in [round-addendum.md](references/round-addendum.md) inserted after the intent. Delete the template's Code Quality Lens section; the addendum's Scope rules out what it would find. The addendum carries the last round's fixes, the scope rule, and the deferred list. Reviewers see only a slice of the code, so these go in the prompt itself.

For the code under review, paste the diff the round's kind names. In a fix or step-back round that is `round-$N-fixes.diff`, followed by this line with the absolute path filled in:

> The whole change against the base branch is in `<absolute path to round-N.diff>`. Read the parts you need to trace these fixes through their callers and state.

### 3. Spawn the reviewers

Spawn the reviewers the round's kind names, with its `effort`: `general-purpose`, foreground, all in one message. Each agent's prompt is short:

> Read `<absolute path to round-N-prompt.md>` in full and follow it. This is a read-only review: modify no files, run no commands that write.

One file, read by each reviewer, in place of pasted copies of the diff.

### 4. Judge, classify, fix

Apply [lead-judgment.md](../interrogate/references/lead-judgment.md), with these changes.

- **Verify every load-bearing claim in the source before you categorize it.** If a finding depends on library internals, React commit and effect order, or what a consumer does with a value, open that code and confirm it. A claim you have not checked is not Act On.
- **Hold the bar.** Act On means a defect by the Scope section of the round addendum, judged in round 6 as in round 1. Defer only by that bar, never to bring the count down: lead-judgment's warning about more than 5 Act On items does not apply here. The deferred list records where the bar sits, so a finding of the same kind and weight as a deferred one is deferred too, unless that one was promoted. Without a fixed bar, reviewers always find something and the loop never ends.
- **Apply only what setup put in scope.** Everything else goes on the deferred list with a one-line reason and the round it was ruled on: below the bar, or outside the scope setting. Nothing is deleted from the list. A deferred item a reviewer raises again with a path the ruling missed is promoted: mark it "promoted rK, F<n>", leave it out of the next prompt's list, and leave it out of the bar's precedent.

When setup brings Consider items in, they go through the same steps as Act On items and count with them. Then, in order:

1. **Classify** every Act On item as a repeat, a regression, or new (see Progress). A repeat or regression belongs to the area of the entry it names, whatever area the finding sits in.
2. **Check for a failed step-back or a third step-back** (see Stop). If either applies, change no code this round: record the round, print the line, and ask.
3. **Design the step-backs** for each area that has a repeat or regression: Step back steps 1 to 4, changing no code. A new item in that area goes into the step-back only if it breaks the same invariant, and the step-back's change must close it too. If any design leaves the change (see Stop), change no code this round: record the round, print the line, and ask.
4. **Apply the step-backs** (Step back steps 5 to 7). Then re-check any new item in code a step-back removed: if its finding no longer applies, drop it, note why in the ledger, and take it out of the round's counts.
5. **Fix the other new items** with the smallest change that closes each, test first (see below). A fix that adds a new mechanism, a heuristic, or a new state is the kind that regressed on #13367. Prefer removing the cause.

Every change you make to the code gets a fix-log entry (see [ledger.md](references/ledger.md)): Act On fixes, Consider fixes, step-back changes. Edits made in Verify to pass lint or tests belong to the fix they follow.

**Test first.** For every fix or step-back that changes behaviour, write the test for this round's finding before the change, and run it on the current tree. It must fail on its assertion about the finding. When the finding is that a capability is missing, failing because the export or module the change will add is absent also counts. Any other build or import error proves nothing. Then make the change and see the test pass. If the test passes before the change:

- **The behaviour was already right** when the test reaches the finding's path and reading the code confirms it. The finding was wrong: put it on the deferred list as not a defect and make no change. If the test belongs to a step-back, stop instead (see Stop).
- **Otherwise the test is wrong.** Rework it. A test still not red after its second rework stays; make the change, mark the test "no red check" in its entry, and go on.

A fix that changes no behaviour, such as a rename, removing dead code, a prose edit, or a config edit that changes no behaviour, needs no test. A test for behaviour already in the tree, such as one added for a missing-test finding, cannot go red; it only needs to pass, and gets the same mark.

### 5. Verify

Run format, lint, typecheck, and the unit and storybook tests the fixes touch, and see them pass, earlier rounds' tests included. Add any output the test run left, such as logs or coverage, to the strays list; new files that belong to the change, such as `__snapshots__/*.snap`, stay off it.

### 6. Record and report

Update the fix log, add a ledger row, and print the convergence line. Formats are in [ledger.md](references/ledger.md). Print the line every round, whether or not anything looks wrong, so the user never has to ask.

If commits are allowed, commit the round now, leaving the strays out (see Final report).

## Progress

There is no round cap. The loop runs until a full-panel round has no Act On items, or a Stop case applies.

Give each Act On item exactly one class, by what caused it, testing in this order:

1. **Repeat.** It is a defect a fix-log entry already closed, at the same spot or by another path to the same broken requirement. Name the entry. If that entry was replaced, name the step-back that replaced it, since a step-back closes everything in its stack.
2. **Regression.** A fix in the log caused it: the defect would not exist without that fix. The fix's hunks are the evidence. The execution path runs through lines it added, or through something it removed or changed, such as a deleted guard or a new contract a caller breaks. Name the entry. A finding caused by a step-back's change is not a regression unless the step-back failed (see Stop); otherwise it is new. A finding that a behaviour-changing fix has no test is not a regression either: add the test under that entry, or under the step-back that replaced it, and count the item as new.
3. **New.** Everything else, including a deferred item re-raised with a path the ruling missed.

The three counts add up to the round's Act On count, less any item dropped while applying the step-backs or found already right by its test.

A round whose Act On items are all new is progress. Counts that fall round over round are the healthy shape, but a round with more new items than the last is still progress, as long as the bar holds.

A repeat or a regression means the loop is solving a problem twice or fixing its own fixes. The fix it traces to is a patch: it closed the finding in front of it without touching the cause. Step back on that fix's area before patching anything there, without asking.

### Step back

1. **Lay out the area.** List the base branch's behaviour in the area, then every live entry in the area from the fix log, step-backs included. Each round's fix diff, limited to the area's files, shows the code. The stack is the subset step 2 keeps.
2. **Name the invariant.** Find the one requirement every finding in the stack broke, stated as a property of the code rather than a symptom: "an index row is placed by an open database exactly once, and a close drops it", not "rows before open throw". Start from the entries this round's repeats and regressions name. For one entry, the invariant is the requirement that fix should have kept. The stack is those entries plus any other live entry in the area that guards the same invariant. If two named entries share no invariant, split them into separate step-backs.
3. **Find its owner.** The owner is the one place that can enforce the invariant for every path through it: usually the earliest point the paths share, or the layer holding the state the invariant is about. Each patch in the stack guarded one path downstream of the owner.
4. **Design one change at the owner.** It replaces the stack, so the patches come out as it goes in. Reverting the mechanism to the base branch's behaviour is one candidate, and the right one when the mechanism itself is the cause, as the anchor heuristic was on #13367. Check the design against every finding in the stack and every new item folded in, and write one line per finding on why it cannot recur. A design that only adds code on top of the stack is another patch.
5. **Test the invariant first.** Keep or write a test for each finding the step-back closes. Tests for this round's findings must fail on the current tree, as Test first says. Tests from earlier rounds already failed in their round. Where one test can show the invariant, prefer it to several that each show a symptom.
6. **Make the change** at the owner, take out the stack's patches, and see every test from step 5 pass.
7. **Log it.** The change gets one fix-log entry, with the stack, invariant and owner. It closes every finding in its stack: what the stack's entries closed, the repeats and regressions that started it, and the new items folded in. The stack's entries are marked replaced by it.
8. **Run the next round as a step-back round.** The round addendum states the invariant and lists the patches removed, so reviewers attack the invariant rather than the last diff.

## Stop

The loop ends or pauses in five cases. Judge, classify, fix says when each is checked.

- **Converged.** A full-panel round has no Act On items. Go to the final report. A fix or step-back round with none runs a confirm round next.
- **The step-back leaves the change.** The invariant conflicts with the stated intent, or its owner lies outside the code the change touches. Present the stack, the invariant, the owner and the design, and ask whether to widen the scope, revert the mechanism to the base branch's behaviour, or stop.
- **A step-back failed.** A finding repeats something a step-back closed, whatever the cause, or a finding its change caused breaks its invariant. Stop and ask, with the stack, the invariant and the design in front of the user.
- **An area needs a third step-back.** Step-backs are counted per area across rounds, and those started in the same round, such as the halves of a split, count once. Two did not settle it. Stop and ask, with both stacks in front of the user.
- **A step-back's test passes before the change.** The behaviour was already right, so the step-back may rest on a wrong finding. Stop and ask, with the stack and the test in front of the user.

After a stop, carry on as the user says.

## Final report

Every commit, per round or final, leaves the strays out. Stage with:

```zsh
cd "$(git rev-parse --show-toplevel)" || exit 1
X=(${(f)"$(grep -v '^[[:space:]]*$' $SCRATCH/strays 2>/dev/null | sed 's/^/:(exclude,literal)/')"})
git add -A -- . $X
```

Before any commit, report in the format in [ledger.md](references/ledger.md): fixes grouped by theme, step-backs and the patches they replaced, the deferred list, test results, the ledger, and diff size against `BASE` and against the loop's start. End with numbered commit options:

> 1. Commit as is.
> 2. Fold in the cheap deferred nits first (list them), then commit.
> 3. Hold for your review; nothing committed.
