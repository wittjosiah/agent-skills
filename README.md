# agent-skills

Personal forks and vendored copies of agent skills, symlinked into
`~/.claude/skills/` so they load in every session.

See [INDEX.md](INDEX.md) for what each skill is and where it came from.

## Install

```sh
ln -s ~/Code/agent-skills/skills ~/.claude/skills
```

The skills root itself is the symlink, so every directory under `skills/` is a
skill with no per-skill wiring. Adding a directory is all it takes.

Skills that live in their own repos are relative symlinks committed here
(`pstack`, `worktree-slots`), so they stay valid on any machine that clones the
sibling repos alongside this one.

## Adding a skill

1. Put it in `skills/<name>/`, keeping any sibling files it references. It is
   live immediately; there is nothing to re-run.
2. Add a row to `INDEX.md` citing the source.
3. If it supersedes a skill that is not from a plugin, disable that one by bare
   name in the right `settings.json`:

   ```json
   "skillOverrides": { "<name>": "off" }
   ```

   Values are `on`, `name-only`, `user-invocable-only`, `off`. This does **not**
   work on plugin skills; disable the whole plugin and vendor what you want.

## Upstreaming to dxos

The `diagnosing-*` and `instrumentation` skills are staged here for
`dxos/dxos` `.agents/skills/`. To land them: copy the directory in, delete the
matching `skillOverrides` entry from that repo's `.claude/settings.local.json`,
and drop the symlink once the PR merges.
