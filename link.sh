#!/usr/bin/env bash
# Symlink every skill in this repo into ~/.claude/skills/.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${HOME}/.claude/skills"
mkdir -p "$dest"

for path in "$repo"/skills/*/; do
  name="$(basename "$path")"
  ln -sfn "${path%/}" "$dest/$name"
  echo "linked $name"
done
