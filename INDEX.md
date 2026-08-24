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

## Not in this repo

Symlinked into `~/.claude/skills/` from elsewhere, deliberately kept separate
because they track their own upstreams:

| Path | Source | Why separate |
| --- | --- | --- |
| `~/Code/pstack-fork/pstack` | fork of [cursor/plugins](https://github.com/cursor/plugins) | A whole multi-plugin monorepo; pulls upstream |
| `~/Code/worktree-slots/skill` | own tool, ships with its code | Belongs beside the `wtslots` binary it documents |
