---
name: explain-diff
description: Use when the user asks for a rich explanation of a code change, diff, branch, or PR. Produces HTML output.
disable-model-invocation: true
---

# Explain Diff

Please make me a rich, interactive explanation of the specified code change.

It should have these sections:

- Background: Explain the existing system relevant to this change. (You should broadly explore surrounding code for this.) We don't know how much the reader already knows, so include a deep background for beginners (note that it can be skipped if the reader is already familiar), and then a more narrow background directly relevant to the change.
- Intuition: Explain the core intuition for the code change. The focus here is to explain the essence, not the full details. Use concrete examples with toy data. Use figures and diagrams liberally.
- Code: Do a high-level walkthrough of the changes to the code. Group/order the changes in an understandable way.
- Quiz: Come up with five questions that test the reader's knowledge of this PR. This should be medium difficulty, difficult enough that you actually need to understand the substance of the PR to answer them, but not gotchas. The goal is to help the reader make sure that they've actually understood. These should be presented as interactive multiple-choice questions, and when the user clicks, it tells them whether they were correct and gives feedback.
  - The quiz has to be answerable only by understanding the change. Two habits break that, and both are easy to fall into. The right answer is the one you know most about, so it comes out longer and more specific than the distractors, and a reader can pick it on shape alone without reading the question. The right answer also drifts to a habitual slot, usually second. Write every option to roughly the same length and specificity, then place the correct one by rolling a die per question rather than by eye. Before saving, check where the five correct answers landed: if three or more share a position, move them.
  - Distractors should be wrong for a reason a reader could hold. Draw them from how the code behaved before this change, from the approach the PR considered and rejected, or from a plausible misreading of the new code. An option nobody would pick is a wasted option.

Format:

- Output a single self-contained HTML page which includes CSS and JavaScript. Make the whole thing one long page with section headers and a table of contents. Don't use tabs for the top-level structure. Basic responsive styling so you can view it on a phone is nice too.
- Where to put it. If the Artifact tool is available, publish it there: it renders, it survives the session, and it has a link to share. Write the HTML to a file first, outside the code repo, with a filename starting with today's date in `YYYY-MM-DD-` format (`/tmp/2026-01-12-explanation-<slug>.html`), then publish that path. The dated name keeps the files time-sorted and out of version control, and it is the path to edit and re-publish if the reader asks for changes. Without the Artifact tool, the file on disk is the deliverable; say where it landed.
- Please write with the clarity and flow of Martin Kleppmann, making it engaging and written in classic style. Transitions between sections should be smooth.
- Some tips on diagrams. Ideally, you should pick a small number of diagram families that can be reused throughout the explanation to explain various cases. Some useful kinds of diagrams:
  - A very simplified version of the UI that the user sees in the app, to explain UI changes.
  - A system diagram showing data flow or communication between components. Make sure to include example data here!
- Don't use ASCII diagrams. Always use simple HTML designs for your diagrams, HTML lists for lists of things, etc.
  - For code blocks, always use `<pre>` tags. If you use a custom styled div instead, it **must** have
    `white-space: pre-wrap` in its CSS, or the browser will collapse all newlines into a single line.
    Before saving the file, scan each code block in the HTML source and confirm its CSS includes
    `white-space: pre` or `pre-wrap`.
- Use callouts for key concepts or definitions, important edge cases, etc.

---

Source: [gist by Geoffrey Litt](https://gist.github.com/geoffreylitt/a29df1b5f9865506e8952488eac3d524).
