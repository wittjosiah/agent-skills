---
name: principle-write-the-as-built
description: "Apply when writing anything a reader takes as truth: comments, docs, commit bodies, PR descriptions, design notes. Describe the thing as it stands, so no sentence leans on a version the reader never saw."
disable-model-invocation: true
---

# Write the As-Built

An **as-built** drawing shows the building that exists, not the revisions that produced it. Write documentation the same way.

**Why:** The author has the change fresh in mind, so the delta feels like the content. To a later reader it is a report on a version they never saw. It also rots: the new behaviour becomes the only behaviour, and the sentence still calls it new. The reader pays twice, reconstructing a dead version to parse a live sentence, then finding they cannot check the claim against the artifact in front of them. Sibling of [Minimize Reader Load](../principle-minimize-reader-load/SKILL.md): same budget, spent on time instead of layers.

**The pattern:**

- **State the invariant, not the transition.** "The loader parses the file", not "the loader now parses the file, which the reader used to do."
- **Give the constraint that makes the current shape correct**, then stop. Rejected alternatives were the author's path, not the reader's.
- **Let the tools carry history.** git log, the PR, the changelog. They are built for it, they stay accurate, and they cost nothing until asked.
- **Keep a contrast only where someone acts on it.** Upstream's name for a vendored file, the old flag a caller still passes. Acting on it is the bar, not being true.
- **Audit for the tells:** now, currently, no longer, used to, previously, instead of, as requested, renamed from, moved to, has since. Each marks a sentence written from the author's seat.

**The test:** Delete every version of the artifact except this one. Does the sentence still say something? If it only means something against what is gone, cut it.
