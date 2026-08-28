---
name: handoff
description: Compact the current conversation into a handoff prompt the user pastes into another agent.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff prompt summarising the current conversation so a fresh agent can continue the work. The deliverable is a single fenced code block in your reply, ready for the user to copy and paste into the other agent. That block is the entire output: create no files.

Address the prompt to the receiving agent in second person, as instructions it can act on directly.

Include a "suggested skills" section naming which skills the receiving agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the prompt accordingly.
