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

Relative symlinks into [`~/Code/pstack-fork/pstack`](https://github.com/cursor/plugins),
a fork of `cursor/plugins`. Individual skills are linked rather than the plugin
root: linking the root registers pstack as a *plugin*, which namespaces every
skill (`pstack:how`) and puts all 44 of them beyond `skillOverrides`, since that
setting is a no-op for `source === "plugin"`. Linking skills gives bare names and
per-skill control.

| Skill | Model-invocable |
| --- | --- |
| `how` | yes |
| `why` | yes |
| `unslop` | yes |
| `architect` | no |
| `arena` | no |
| `interrogate` | no |
| `tdd` | no |
| `principle-*` (21 skills) | no |

`architect` calls `arena`, `how`, `why`, and `interrogate`; `architect` and
`arena` together cite eight of the principle skills, and the principles cite each
other. All 21 are linked so no reference dangles, which costs nothing: every one
declares `disable-model-invocation`.

Dropping the plugin root also drops the agents it contributed
(`pstack:Comment Sicko`, `pstack:poteto-agent`) and the ~37 unlinked skills.
Nothing in the linked set uses them.

## Not in this repo

Symlinked into `~/.claude/skills/` from elsewhere, deliberately kept separate
because they track their own upstreams:

`worktree-slots` is a relative symlink to `~/Code/worktree-slots/skill`; the
skill ships beside the `wtslots` binary it documents and stays there.

Both it and the pstack links depend on those repos being cloned as siblings of
this one. Nothing enforces that; if they are missing the links dangle silently.
