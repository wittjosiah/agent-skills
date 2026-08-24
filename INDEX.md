# Skill index

Every skill in this repo, with where it came from. "Forked" means the content
diverges from its source and is maintained here; "vendored" means a verbatim copy
taken because the upstream packaging could not be subset.

Model-invocable skills are visible to the agent on every turn and fire on their
description. Slash-only skills declare `disable-model-invocation: true`, cost no
context, and run only when you type `/name`.

## Forked

| Skill | Source | Model-invocable | What changed |
| --- | --- | --- | --- |
| `diagnosing-bugs` | [mattpocock/skills](https://github.com/mattpocock/skills) `engineering/diagnosing-bugs`, plugin v1.2.3 | yes | Phase 1's generic loop list replaced with the DXOS instrument ladder; repro contract and golden rule folded in from `dxos/dxos` `debugging-ui`; branch router added |
| `diagnosing-ui` | [dxos/dxos](https://github.com/dxos/dxos) `.agents/skills/debugging-ui` @ `cc9b81fcad` | yes | Generic phases moved out to `diagnosing-bugs`; kept the instrument table, isolation ladder, verification contract, interaction budget |
| `instrumentation` | [dxos/dxos](https://github.com/dxos/dxos) `.agents/skills/debugging` @ `e68ddada8f` | yes | Renamed from `debugging` to stop it competing with `diagnosing-bugs`; cross-references updated, body unchanged |

Both dxos originals are disabled in that repo's `.claude/settings.local.json` via
`skillOverrides`. The upstream `mattpocock-skills:diagnosing-bugs` is gone with
the plugin (see below).

## Vendored

All ten are verbatim from [mattpocock/skills](https://github.com/mattpocock/skills)
plugin v1.2.3. The `mattpocock-skills@claude-plugins-official` plugin is set to
`false` in `~/.claude/settings.json`, because `skillOverrides` cannot disable
individual plugin skills: the gate returns `"on"` early for anything with
`source === "plugin"` (verified on Claude Code 2.1.238 across four key/scope
combinations). Disabling the plugin wholesale and vendoring the keepers is the
only way to hold a subset. Vendoring drops the `mattpocock-skills:` prefix, so
these are invoked by bare name.

| Skill | Upstream path | Model-invocable |
| --- | --- | --- |
| `codebase-design` | `engineering/codebase-design` | yes |
| `domain-modeling` | `engineering/domain-modeling` | yes |
| `grilling` | `productivity/grilling` | yes |
| `wizard` | `engineering/wizard` | yes |
| `writing-for-agents` | `productivity/writing-for-agents` | yes |
| `grill-me` | `productivity/grill-me` | no |
| `grill-with-docs` | `engineering/grill-with-docs` | no |
| `handoff` | `productivity/handoff` | no |
| `improve-codebase-architecture` | `engineering/improve-codebase-architecture` | no |
| `wait-what` | `productivity/wait-what` | no |

`codebase-design` and `domain-modeling` are here because
`improve-codebase-architecture` and `grilling` point at them. Every
cross-reference in the vendored set resolves inside the set.

## From pstack

Vendored from [`cursor/plugins`](https://github.com/cursor/plugins) `pstack/` at
version 0.14.2, then ported off Cursor (see below). Upstream is the source of
truth; re-vendor straight from it. The intermediate `wittjosiah/pstack-fork` is
gone, and its two local commits are kept as patches in
`vendor/pstack-local-commits/` (a Claude Code plugin manifest we no longer use,
and a `poteto-mode` rename for a skill not vendored here).

Skills were copied individually rather than taking the plugin root. Linking or
installing that root registers pstack as a *plugin*, which namespaces every skill
(`pstack:how`) and puts all 44 beyond `skillOverrides`, since that setting is a
no-op for `source === "plugin"`.

To re-vendor: clone `cursor/plugins`, copy the wanted directories out of
`pstack/skills/` and `pstack/agents/`, re-apply the Cursor ports below, then
delete the clone.

| Skill | Model-invocable |
| --- | --- |
| `how` | yes |
| `why` | yes |
| `unslop` | yes |
| `architect` | no |
| `arena` | no |
| `interrogate` | no |
| `no-comments` | no |
| `tdd` | no |
| `principle-*` (21 skills) | no |

`architect` calls `arena`, `how`, `why`, and `interrogate`; `no-comments` calls
`architect`, `how`, and `why`; `architect`, `arena`, and `no-comments` cite nine
of the principle skills, and the principles cite each other. All 21 are vendored
so no reference dangles, which costs nothing: every one declares
`disable-model-invocation`.

`no-comments` spawns the **Comment Sicko** agent, vendored to `agents/` and
symlinked as `~/.claude/agents`. The unvendored ~36 pstack skills and the
`poteto-agent` are gone; nothing in this set refers to them.

### Ported off Cursor

pstack targets Cursor, so the vendored copies diverge from upstream in four ways.
Re-apply these when re-vendoring a newer pstack.

- **Model roster.** Every reference to `~/.cursor/rules/pstack-models.mdc` is
  dropped and the model tables inlined as `opus` / `fable` / `sonnet`. The
  upstream slugs (`claude-fable-5-thinking-max`, `gpt-5.6-sol-max`,
  `grok-4.6-fast-xhigh`, `claude-opus-5-thinking-xhigh`) are not accepted by the
  Agent tool, which takes only `opus`, `fable`, `sonnet`, `haiku`. The config
  indirection went with them: `setup-pstack`, which wrote that file, is not
  vendored. Touched `arena`, `architect`, `how`, `interrogate`, `why`.
- **Subagent parameters.** `generalPurpose` becomes `general-purpose`, and
  `readonly: true` becomes a prompt instruction, since the Agent tool has no such
  parameter. `how`'s explorers now use the `Explore` agent type, which is
  genuinely read-only.
- **MCP discovery.** `why` inspected an `mcps/` directory Cursor exposes; it now
  enumerates `mcp__<server>__*` tools and `ToolSearch`, and the readonly-strips-MCP
  caveat is gone because it does not apply here.
- **Panel diversity.** Upstream draws reviewers from four model families. Only
  Claude models are reachable, so `interrogate` and `how` now say that agreement
  is shared-family agreement, not independent confirmation. `interrogate` also
  warns that subagents inherit a session-start skill listing, which is how a live
  run produced two confident false positives about plugin state.

## Not in this repo

Symlinked into `~/.claude/skills/` from elsewhere, deliberately kept separate
because they track their own upstreams:

`worktree-slots` is a relative symlink to `~/Code/worktree-slots/skill`; the
skill ships beside the `wtslots` binary it documents and stays there.

Both it and the pstack links depend on those repos being cloned as siblings of
this one. Nothing enforces that; if they are missing the links dangle silently.
