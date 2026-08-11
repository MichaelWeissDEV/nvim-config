#!/usr/bin/env bash
# Vendor one plugin from scripts/plugins.tsv via `git subtree add --squash`.
# This is the ONLY script in this repo that performs a network git
# operation as a side effect of normal use -- and even this one is never
# run automatically; it's a maintainer action, not something `nvim` runs.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/scripts/plugins.tsv"

usage() {
  echo "Usage: $0 <plugin-name>" >&2
  echo "  <plugin-name> must match column 1 of scripts/plugins.tsv" >&2
  exit 1
}

[ $# -eq 1 ] || usage
name="$1"

line="$(awk -F'\t' -v n="$name" 'NR>1 && $1==n {print; exit}' "$manifest")"
if [ -z "$line" ]; then
  echo "error: '$name' not found in $manifest" >&2
  exit 1
fi

IFS=$'\t' read -r plugin_name url branch prefix load_type trigger <<<"$line"

cd "$repo_root"

if [ -d "$prefix" ]; then
  echo "error: $prefix already exists. Use plugin-update.sh to update it instead." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: working tree is not clean. git subtree requires a clean tree; commit or stash first." >&2
  exit 1
fi

echo "==> Adding $plugin_name ($url @ $branch) into $prefix"
git subtree add --prefix="$prefix" "$url" "$branch" --squash -m "vendor($plugin_name): subtree add $url @ $branch"

sha="$(git ls-remote "$url" "refs/heads/$branch" | cut -f1)"
"$repo_root/scripts/plugin-status.sh" --record "$plugin_name" "$url" "$branch" "$prefix" "$load_type" "$sha"
git add plugins.lock
git commit -q -m "plugins.lock: record $plugin_name @ ${sha:0:12}"

echo "==> Done. Recorded in plugins.lock."
