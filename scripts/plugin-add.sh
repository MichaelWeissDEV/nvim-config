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

# Resolve the branch to a concrete commit ONCE, then vendor exactly that
# commit and lock exactly that commit.
#
# The previous version passed the branch name to `git subtree add` and then
# asked `git ls-remote` for the branch head again afterwards. If upstream
# published between those two steps, plugins.lock recorded a commit that
# was never vendored -- the lockfile would describe a tree that does not
# exist in this repository. Fetching once and using FETCH_HEAD for both the
# subtree operation and the lock entry removes the window entirely, and
# works against servers that refuse to serve arbitrary SHAs.
echo "==> Fetching $plugin_name ($url @ $branch)"
git fetch --no-tags "$url" "$branch"
sha="$(git rev-parse FETCH_HEAD)"
echo "==> Resolved $branch to $sha"

echo "==> Adding $plugin_name into $prefix"
git subtree add --prefix="$prefix" FETCH_HEAD --squash \
  -m "vendor($plugin_name): subtree add $url @ $branch ($sha)"

"$repo_root/scripts/plugin-status.sh" --record "$plugin_name" "$url" "$branch" "$prefix" "$load_type" "$sha"
git add plugins.lock
git commit -q -m "plugins.lock: record $plugin_name @ ${sha:0:12}"

echo "==> Done. Recorded in plugins.lock."
