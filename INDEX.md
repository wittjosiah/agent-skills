# Skill index

Every skill in this repo, with where it came from. "Forked" means the content
diverges from its source and is maintained here; "vendored" means a verbatim copy
taken because the upstream packaging could not be subset; "original" means it
started here.

Model-invocable skills are visible to the agent on every turn and fire on their
description. Slash-only skills declare `disable-model-invocation: true`, cost no
context, and run only when you type `/name`.

## Forked

| Skill | Source | Model-invocable | What changed |
| --- | --- | --- | --- |
| `diagnosing-bugs` | [mattpocock/skills](https://github.com/mattpocock/skills) `engineering/diagnosing-bugs`, plugin v1.2.3 | yes | Phase 1's generic loop list replaced with the DXOS instrument ladder; repro contract and golden rule folded in from `dxos/dxos` `debugging-ui`; branch router added |
| `diagnosing-ui` | [dxos/dxos](https://github.com/dxos/dxos) `.agents/skills/debugging-ui` @ `cc9b81fcad` | yes | Generic phases moved out to `diagnosing-bugs`; kept the instrument table, isolation ladder, verification contract, interaction budget |
| `instrumentation` | [dxos/dxos](https://github.com/dxos/dxos) `.agents/skills/debugging` @ `e68ddada8f` | yes | Named apart from `diagnosing-bugs` so the two do not compete on the same trigger; body matches upstream, cross-references point here |

Both dxos originals are disabled in that repo's `.claude/settings.local.json`
via `skillOverrides`. The `mattpocock-skills` plugin, which carries the upstream
`diagnosing-bugs`, is disabled in `~/.claude/settings.json` (see below).

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
| `resolving-merge-conflicts` | `engineering/resolving-merge-conflicts` | yes |
| `teach` | `productivity/teach` | no |
| `two-axis-review` | `engineering/code-review` | yes |
| `handoff` | `productivity/handoff` | no |
| `improve-codebase-architecture` | `engineering/improve-codebase-architecture` | no |
| `wait-what` | `productivity/wait-what` | no |

`two-axis-review` is upstream's `code-review` under a different name. That name
is taken by Claude Code's built-in `/code-review` (ultra mode, `--comment`,
`--fix`), and a user skill claiming it replaces the built-in's listing entry. Its
spec lookup uses `gh` and the Linear MCP; upstream's route through
`docs/agents/issue-tracker.md` and `/setup-matt-pocock-skills` needs a setup
skill this repo does not vendor.

`codebase-design` and `domain-modeling` are here because
`improve-codebase-architecture` and `grilling` point at them. Every
cross-reference in the vendored set resolves inside the set.

## From pstack

Vendored from [`cursor/plugins`](https://github.com/cursor/plugins) `pstack/` at
version 0.14.2, then ported off Cursor (see below). Upstream is the source of
truth; re-vendor straight from it.

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
| `blast-radius` | no |
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
- **Subagent parameters.** `general-purpose`, not upstream's `generalPurpose`.
  Read-only posture is a prompt instruction, since the Agent tool has no
  `readonly` parameter; `how`'s explorers use the `Explore` agent type, which is
  read-only by construction.
- **MCP discovery.** `why` enumerates `mcp__<server>__*` tools and `ToolSearch`,
  where upstream inspects an `mcps/` directory Cursor exposes.
- **Panel diversity.** Only Claude models are reachable, where upstream draws
  reviewers from four families, so `interrogate` and `how` treat agreement as
  shared-family agreement rather than independent confirmation. `interrogate`
  also warns that subagents inherit a session-start skill listing, which goes
  stale on any question about skill loading, plugins, or settings.

## Original

Written here, with no upstream.

| Skill | Model-invocable |
| --- | --- |
| `principle-write-the-as-built` | no |

Sits alongside the 21 vendored `principle-*` skills and follows their shape.
dxos `code-style` and `unslop` both state this rule inline; neither cites this
skill yet.

## Not in this repo

Symlinked into `~/.claude/skills/` from elsewhere, deliberately kept separate
because they track their own upstreams:

`worktree-slots` is a relative symlink to `~/Code/worktree-slots/skill`; the
skill ships beside the `wtslots` binary it documents and stays there.

Both it and the pstack links depend on those repos being cloned as siblings of
this one. Nothing enforces that; if they are missing the links dangle silently.
