#!/usr/bin/env bash
# Update one already-vendored plugin via `git subtree pull --squash`.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/scripts/plugins.tsv"

usage() {
  echo "Usage: $0 <plugin-name>" >&2
  exit 1
}
[ $# -eq 1 ] || usage
name="$1"

line="$(awk -F'\t' -v n="$name" 'NR>1 && $1==n {print; exit}' "$manifest")"
[ -n "$line" ] || { echo "error: '$name' not found in $manifest" >&2; exit 1; }
IFS=$'\t' read -r plugin_name url branch prefix load_type trigger <<<"$line"

cd "$repo_root"
[ -d "$prefix" ] || { echo "error: $prefix does not exist yet; use plugin-add.sh first." >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "error: working tree is not clean." >&2; exit 1; }

echo "==> Updating $plugin_name ($url @ $branch)"
git subtree pull --prefix="$prefix" "$url" "$branch" --squash -m "vendor($plugin_name): subtree pull $url @ $branch"

sha="$(git ls-remote "$url" "refs/heads/$branch" | cut -f1)"
"$repo_root/scripts/plugin-status.sh" --record "$plugin_name" "$url" "$branch" "$prefix" "$load_type" "$sha"
echo "==> Done."
