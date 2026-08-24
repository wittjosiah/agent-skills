#!/usr/bin/env bash
# Point a Claude Code config dir at this repo's skills and agents.
# Idempotent: safe to re-run, and safe to run from a cloud environment setup command.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$dest"

link() {
  local src="$repo/$1" target="$dest/$1"
  # A plain `ln -s` against an existing directory links *inside* it and exits 0,
  # so move a real directory aside first.
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak.$(date +%s)"
    echo "[skills] moved existing $target aside"
  fi
  ln -sfn "$src" "$target"
  echo "[skills] $target -> $src"
}

link skills
link agents

# Skills this repo supersedes under a *different* name. A skill here that keeps
# its upstream directory name shadows the project copy on its own and needs no
# entry. skillOverrides is keyed by the directory name as listed, not the
# frontmatter `name:`, resolves from user settings for any non-plugin skill, and
# is ignored outright by plugin skills.
settings="$dest/settings.json"
overrides='{"debugging":"off","debugging-ui":"off"}'
if command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, sys, pathlib
path, overrides = pathlib.Path(sys.argv[1]), json.loads(sys.argv[2])
data = json.loads(path.read_text()) if path.exists() else {}
data.setdefault("skillOverrides", {}).update(overrides)
path.write_text(json.dumps(data, indent=2))
print("[skills] skillOverrides: " + ", ".join(overrides))
' "$settings" "$overrides"
else
  echo "[skills] python3 missing; add to $settings by hand: \"skillOverrides\": $overrides"
fi

# Skills that live in sibling repos are relative symlinks. Those siblings are
# absent in a fresh container, so report rather than fail: a dangling entry is
# skipped by the scanner, and the rest of the set still loads.
missing=()
for path in "$repo"/skills/*; do
  [ -e "$path" ] || missing+=("$(basename "$path")")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "[skills] unresolved (sibling repo not present): ${missing[*]}"
fi

echo "[skills] $(find "$repo/skills" -maxdepth 1 -mindepth 1 -exec test -e {} \; -print | wc -l | tr -d ' ') skills available"
