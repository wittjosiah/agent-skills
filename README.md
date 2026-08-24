# agent-skills

Personal forks and vendored copies of agent skills, symlinked into
`~/.claude/skills/` so they load in every session.

See [INDEX.md](INDEX.md) for what each skill is and where it came from.

## Install

```sh
[ -L ~/.claude/skills ] || mv ~/.claude/skills ~/.claude/skills.bak
ln -sfn ~/Code/agent-skills/skills ~/.claude/skills
ls ~/.claude/skills/unslop/SKILL.md   # proof it took
```

The guard matters: plain `ln -s` against an existing `~/.claude/skills` directory
creates the link *inside* it and exits 0, so the install reports success and does
nothing. Claude Code creates that directory itself, so this is the usual case.

The skills root itself is the symlink, so every directory under `skills/` is a
skill with no per-skill wiring. Adding a directory is all it takes.

Skills that live in their own repos are relative symlinks committed here (the
pstack set, `worktree-slots`), valid on any machine that clones those repos as
siblings of this one. Nothing checks that they are present; missing siblings
leave dangling links and no error.

Because the skills root is inside this working tree, skills the agent writes land
here as untracked directories. Commit or move them before any `git clean -fd`.

## Adding a skill

1. Put it in `skills/<name>/`, keeping any sibling files it references. It is
   live immediately; there is nothing to re-run.
2. Add a row to `INDEX.md` citing the source.
3. If it supersedes a skill that is not from a plugin, disable that one by bare
   name in the right `settings.json`:

   ```json
   "skillOverrides": { "<name>": "off" }
   ```

   Values are `on`, `name-only`, `user-invocable-only`, `off`.

   This does **not** work on plugin skills: the gate returns `on` early for
   `source === "plugin"`. A directory here that carries `.claude-plugin/plugin.json`
   registers as a plugin, so link *individual skills* out of such a repo rather
   than its root, or you lose bare names and per-skill control for everything in it.

## Upstreaming to dxos

The `diagnosing-*` and `instrumentation` skills are staged here for
`dxos/dxos` `.agents/skills/`. To land them: copy the directory in, delete the
matching `skillOverrides` entry from that repo's `.claude/settings.local.json`,
and drop the symlink once the PR merges.
