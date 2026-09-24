---
name: converge
description: "Loop interrogate review-and-fix rounds on one PR until a round has no Act On items, tracking convergence and reverting areas that thrash."
disable-model-invocation: true
---

# Converge

Run [interrogate](../interrogate/SKILL.md) in rounds on one change. Fix each round's Act On items, then review again, until a round comes back with none. Interrogate supplies the reviewers, the prompt, and the judgment framework. This skill adds the loop around them: a ledger, a convergence line every round, a thrash rule, and a stop.

The failure this guards against is fixes that breed findings. On [dxos/dxos#13367](https://github.com/dxos/dxos/pull/13367), round 1 applied Consider items as well as Act On. That grew scope, and three of round 2's five Act On items were regressions from those fixes. Rounds 4 to 7 each found a new hole in one mechanism, an anchor heuristic added in round 1. Each patch opened the next hole, and the diff grew from +392/−168 to +588/−202 before the user had to ask whether the loop was converging. It was not. Reverting that mechanism to main's behaviour plus one small guard ended it: round 8 had no Act On items, at +427/−186.

## Setup

Do this once, before round 1.

1. **Target.** A PR number, or the current branch's diff. Take the intent from the PR description, commits, and the conversation, as interrogate's Step 2 does. If the intent is unclear, add it to the question in step 4.
2. **Scratch directory.** Use the session scratchpad if the system prompt names one, otherwise `mktemp -d`. Round prompts, snapshots, and the ledger live there. In the commands below, `$SCRATCH`, `$N`, and `$PR` stand for literal values you substitute.
3. **Baseline.** `git merge-base origin/main HEAD > $SCRATCH/base`, with the PR's base branch in place of main if it differs. `BASE` below means `$(<$SCRATCH/base)`.
4. **Ask one numbered question**, then do not ask again until thrash, the cap, or the final report:

   > Before I start:
   > 1. Scope: Act On only (default), or Consider items too?
   > 2. Commits during the loop: none (default), or one per round?
   > 3. Round cap: 5 (default). Each round runs 3 reviewers at 5 to 14 minutes each.
   >
   > Reply "defaults" to take all three. Either way I keep the diff minimal.

   Consider items are where scope grows. If the user brings them in, apply only the ones that change no behaviour outside the lines they name.
5. **Snapshot the start.** Write `snap-0` (see Build the diff) and record round 0 in the ledger with the diff size against `BASE`.

## Each round

### 1. Build the diff

Diff from `BASE` to the working tree, so uncommitted fixes are reviewed. Limit it to the PR's files plus anything modified. In zsh, split the file list into an array or the diff comes out empty:

```zsh
F=(${(f)"$( { gh pr diff $PR --name-only; git diff --name-only $BASE; git ls-files --others --exclude-standard; } | sort -u )"})
git diff $BASE -- "${F[@]}" > $SCRATCH/round-$N.diff
git diff --shortstat $BASE -- "${F[@]}"
```

Drop the `gh` line when the target is a branch, not a PR. `git diff` skips untracked files, so name any new untracked files in the prompt and tell reviewers to read them in full.

Snapshot the tree without committing, so later rounds can diff against it. Shell variables do not survive between Bash calls, so keep `BASE` and every snapshot in files:

```zsh
s=$(git stash create); echo ${s:-$(git rev-parse HEAD)} > $SCRATCH/snap-$N
```

`git stash create` writes a commit object for the tracked changes and touches neither the tree nor the index. `git diff $(<$SCRATCH/snap-$((N-1))) $(<$SCRATCH/snap-$N)` is then exactly what changed since the last round, and `git diff --shortstat $(<$SCRATCH/snap-0)` is the size against the loop's start. Untracked files are not in a snapshot; list them by hand.

### 2. Write the round prompt

Write one file, `$SCRATCH/round-$N-prompt.md`: interrogate's [reviewer-prompt.md](../interrogate/references/reviewer-prompt.md) filled as interrogate's Step 3 fills it (intent, diff, [rubric](../interrogate/references/rubric.md), [code-quality lens](../interrogate/references/code-quality-review.md)), with the three sections in [round-addendum.md](references/round-addendum.md) inserted after the intent. The addendum carries the changes since the last round, the scope rule, and the deferred list. Reviewers see only a slice of the code, so these go in the prompt itself.

### 3. Spawn the reviewers

Same table and settings as interrogate's Step 3: `opus`, `fable`, `sonnet`, `general-purpose`, foreground, all three in one message. Each agent's prompt is short:

> Read `<absolute path to round-N-prompt.md>` in full and follow it. This is a read-only review: modify no files, run no commands that write.

One file, read three times, in place of three pasted copies of the diff.

### 4. Judge as lead

Apply [lead-judgment.md](../interrogate/references/lead-judgment.md), with two changes.

- **Verify every load-bearing claim in the source before you categorize it.** If a finding depends on library internals, React commit and effect order, or what a consumer does with a value, open that code and confirm it. A claim you have not checked is not Act On.
- **Apply only what setup put in scope.** Everything else goes on the deferred list with a one-line reason and the round it was ruled on. The list grows; nothing leaves it.

Fix the Act On items with the smallest change that closes each. A fix that adds a new mechanism, a heuristic, or a new state is the kind that regressed on #13367. Prefer removing the cause.

### 5. Verify

Run format, lint, typecheck, and the unit and storybook tests the fix touches. For each new test, check that it fails without the fix: revert the fix, run the test, see red, restore. A test that passes both ways goes back for rework.

### 6. Record and report

Add a ledger row and print the convergence line. Formats are in [ledger.md](references/ledger.md). For each Act On item, decide whether it is a regression from an earlier round's fix: check whether the flagged lines were written between two snapshots, `snap-(k-1)` and `snap-k`. Print the convergence line every round, whether or not anything looks wrong, so the user never has to ask.

If commits are allowed, commit the round now.

## Thrash

An area thrashes when either holds:

- the same mechanism produces Act On findings in 2 or more consecutive rounds after being fixed, or
- the diff against `BASE` grows between rounds while Act On findings keep coming.

On thrash, stop before the next fix and ask:

> Round N: <mechanism> has drawn Act On findings in rounds X to N after each fix, and the diff grew from A to B.
> 1. Revert <mechanism> to baseline, keeping only the smallest guard that fixes the worst failure against baseline, with a test that fails on baseline. (recommended)
> 2. One more targeted fix, then revert if round N+1 flags it again.
> 3. Stop here and report.

Option 1's test is the proof the guard earns its place: run it against baseline behaviour and see it fail. Adding another heuristic is not an option on this list, and it stays off it.

## Stop

- **Converged.** A round has no Act On items. Go to the final report.
- **Cap.** The round cap is reached with Act On items still open. Escalate with the ledger and the open items, and ask whether to raise the cap, revert the worst area, or stop.

## Final report

Before any commit, report in the format in [ledger.md](references/ledger.md): fixes grouped by theme, reverted attempts and why, the deferred list, test results, the ledger, and diff size against `BASE` and against the loop's start. End with numbered commit options:

> 1. Commit as is.
> 2. Fold in the cheap deferred nits first (list them), then commit.
> 3. Hold for your review; nothing committed.
