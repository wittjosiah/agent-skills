# agent-skills

Personal forks and vendored copies of agent skills, symlinked into
`~/.claude/skills/` so they load in every session.

See [INDEX.md](INDEX.md) for what each skill is and where it came from.

## Install

```sh
./install.sh
```

It links `skills/` and `agents/` into `$CLAUDE_CONFIG_DIR` (default `~/.claude`)
and merges the `skillOverrides` that hide skills this repo supersedes. It moves a
real directory aside first: a plain `ln -s` against an existing `~/.claude/skills`
links *inside* it and exits 0, and Claude Code creates that directory itself, so
that is the usual case.

`skillOverrides` is keyed by bare skill name and resolves from user settings for
any non-plugin skill, so it holds in a fresh container. Plugin skills ignore it
entirely; disable the whole plugin for those.

The skills root itself is the symlink, so every directory under `skills/` is a
skill with no per-skill wiring. Adding a directory is all it takes.

`worktree-slots` is a relative symlink to `~/Code/worktree-slots/skill`, so it
needs that repo cloned as a sibling of this one. Nothing checks; a missing
sibling leaves a dangling link and no error. Everything else is a real copy.

Agents live in `agents/`, symlinked as `~/.claude/agents`:

```sh
[ -L ~/.claude/agents ] || mv ~/.claude/agents ~/.claude/agents.bak 2>/dev/null
ln -sfn ~/Code/agent-skills/agents ~/.claude/agents
```

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

## Making these available to cloud agents

A Claude Code cloud sandbox starts with an empty `~/.claude`, so nothing here
reaches it. Skills committed to the repo the agent works in do arrive, via that
repo's `.claude/skills` symlink; everything else has to be fetched.

The plan: push this repo somewhere the sandbox can clone from, then have the
environment's setup command clone and run `install.sh`. In dxos that is
`.config/claude-code-setup.sh`, which already bootstraps plugins for the same
reason. Add it early in that script, before the toolchain steps, so a toolchain
failure under `set -e` cannot take it down:

```sh
SKILLS_DIR="$HOME/.agent-skills"
if [ -d "$SKILLS_DIR/.git" ]; then
  git -C "$SKILLS_DIR" pull --ff-only
else
  git clone --depth 1 https://github.com/<you>/agent-skills "$SKILLS_DIR"
fi
bash "$SKILLS_DIR/install.sh"
```

The setup command runs at image build, so the first session already sees the
skills. This is per-repo: every repo whose cloud agents need them wants the same
lines.

### Before publishing

1. **Licensing.** Recorded in [NOTICE.md](NOTICE.md), with full texts in `licenses/`.
   Three licenses apply and they are not interchangeable: the pstack and
   mattpocock sets are MIT, while `diagnosing-ui`, `instrumentation`, and part of
   `diagnosing-bugs` derive from `dxos/dxos` under **FSL-1.1-Apache-2.0**, which
   is source-available with a non-compete restriction. The repository cannot be
   declared MIT as a whole. Still to decide: which license covers this repo's own
   files (README, INDEX, NOTICE, install.sh).
2. **`explain-diff` comes from an unlicensed gist.** It links back to the
   original and is recorded in NOTICE.md. No terms were granted, so decide
   whether attribution is enough for you before pushing this public.
3. **A private repo needs credentials in the sandbox**, where `gh` is not on
   PATH. Public is much less work.
4. `worktree-slots` is a relative symlink to a sibling repo and will dangle in a
   container. `install.sh` reports it and carries on; the other 42 still load.
5. Check for anything you would not publish. As of this writing there are no
   secrets and no absolute home paths in tracked files.

### The other two routes

- **claude.ai skills sync** (`syncClaudeAiSkills`, on by default) downloads
  skills you enable on claude.ai into `~/.claude/skills/synced`. Account-scoped
  rather than per-repo, so it would cover every cloud agent. Untested here:
  whether sync fires inside a sandbox is unverified. `.gitignore` already covers
  `synced/` and `.trash/`, which would otherwise land inside this repo.
- **Commit into the target repo.** Guaranteed, no bootstrap, no network, but it
  puts personal skills in a shared tree. Worth it only for the three below.

## Upstreaming to dxos

The `diagnosing-*` and `instrumentation` skills are staged here for
`dxos/dxos` `.agents/skills/`. To land them: copy the directory in, delete the
matching `skillOverrides` entry from that repo's `.claude/settings.local.json`,
and drop the symlink once the PR merges.
