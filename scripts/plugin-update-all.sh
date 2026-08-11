#!/usr/bin/env bash
# Update every vendored plugin, one subtree-pull commit each. Explicit
# maintainer action only -- never run by nvim itself.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/scripts/plugins.tsv"

tail -n +2 "$manifest" | while IFS=$'\t' read -r name url branch prefix load_type trigger; do
  if [ -d "$repo_root/$prefix" ]; then
    "$repo_root/scripts/plugin-update.sh" "$name"
  else
    echo "==> Skipping $name (not vendored yet; run plugin-add.sh $name)"
  fi
done
