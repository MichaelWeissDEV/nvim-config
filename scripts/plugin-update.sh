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

# Same atomicity requirement as plugin-add.sh: resolve once, vendor that
# exact commit, lock that exact commit. See the comment there.
echo "==> Fetching $plugin_name ($url @ $branch)"
git fetch --no-tags "$url" "$branch"
sha="$(git rev-parse FETCH_HEAD)"
echo "==> Resolved $branch to $sha"

if [ "$(awk -F'\t' -v n="$plugin_name" 'NR>1 && $1==n {print $4}' "$repo_root/plugins.lock" 2>/dev/null)" = "$sha" ]; then
  echo "==> Already at $sha, nothing to update."
  exit 0
fi

# `git subtree merge`, not `git subtree pull`: pull insists on
# <repository> <ref> and would re-resolve the branch itself, reopening the
# exact race this script exists to close. pull is defined as fetch + merge,
# and the fetch already happened above -- so merging FETCH_HEAD applies
# precisely the commit that was resolved and reported.
echo "==> Updating $plugin_name in $prefix"
git subtree merge --prefix="$prefix" FETCH_HEAD --squash \
  -m "vendor($plugin_name): subtree merge $url @ $branch ($sha)"

"$repo_root/scripts/plugin-status.sh" --record "$plugin_name" "$url" "$branch" "$prefix" "$load_type" "$sha"
git add plugins.lock
git commit -q -m "plugins.lock: record $plugin_name @ ${sha:0:12}"
echo "==> Done."
