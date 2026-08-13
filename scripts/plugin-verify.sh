#!/usr/bin/env bash
# Validate scripts/plugins.tsv, plugins.lock and the vendored directories
# against each other. Purely local: no network, no git remote access, so it
# is safe as a CI quality gate.
#
# The three must agree exactly. Any disagreement means the repository does
# not describe what it actually contains -- a lock entry for a plugin that
# was removed, a vendored directory nobody declared, a SHA that is not a
# SHA. Those are the failures that make "reproducible" untrue.
#
# Implemented with awk rather than bash associative arrays: macOS still
# ships bash 3.2, which has no `declare -A`, and this has to run on both CI
# runners.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

manifest="scripts/plugins.tsv"
lockfile="plugins.lock"

[ -f "$manifest" ] || { echo "plugin-verify: missing $manifest" >&2; exit 1; }
[ -f "$lockfile" ] || { echo "plugin-verify: missing $lockfile" >&2; exit 1; }

problems="$(
  awk -F'\t' -v manifest="$manifest" -v lockfile="$lockfile" '
    function problem(msg) { print "plugin-verify: " msg > "/dev/stderr"; count++ }

    # ---------------------------------------------------------- manifest
    NR == FNR {
      if (FNR == 1) {
        if ($0 != "name\turl\tbranch\tprefix\tload_type\ttrigger")
          problem(manifest " header must be exactly: name|url|branch|prefix|load_type|trigger")
        next
      }
      if ($0 == "") next
      if (NF != 6) { problem(manifest " line " FNR ": expected 6 tab-separated fields, found " NF); next }

      name = $1; url = $2; branch = $3; prefix = $4; load = $5

      if (name == "")   problem(manifest " line " FNR ": empty name")
      if (branch == "") problem(manifest " line " FNR ": empty branch")
      # file:// is a legitimate git transport and is what the local
      # vendoring integration test uses; ssh:// and git@ cover the rest.
      if (url !~ /^https:\/\// && url !~ /^git@/ && url !~ /^ssh:\/\// && url !~ /^file:\/\//)
        problem(manifest " (" name "): URL must be https://, ssh://, file:// or git@, got \"" url "\"")
      if (load != "start" && load != "opt")
        problem(manifest " (" name "): load_type must be start or opt, got \"" load "\"")

      expected = "pack/vendor/" load "/" name
      if (prefix != expected)
        problem(manifest " (" name "): prefix must be \"" expected "\", got \"" prefix "\"")

      if (name in m_url)      problem(manifest ": duplicate plugin name \"" name "\"")
      if (prefix in seen_pfx) problem(manifest ": duplicate prefix \"" prefix "\"")
      seen_pfx[prefix] = 1

      m_url[name] = url; m_branch[name] = branch
      m_prefix[name] = prefix; m_load[name] = load
      order[++n] = name
      next
    }

    # ---------------------------------------------------------- lockfile
    {
      if (FNR == 1) {
        if ($0 != "name\turl\tbranch\tsha\tprefix\tload_type")
          problem(lockfile " header must be exactly: name|url|branch|sha|prefix|load_type")
        next
      }
      if ($0 == "") next
      if (NF != 6) { problem(lockfile " line " FNR ": expected 6 tab-separated fields, found " NF); next }

      name = $1; url = $2; branch = $3; sha = $4; prefix = $5; load = $6

      if (name in locked) problem(lockfile ": duplicate entry for \"" name "\"")
      locked[name] = 1

      if (!(name in m_url)) { problem(lockfile ": \"" name "\" is locked but absent from " manifest); next }

      if (sha !~ /^[0-9a-f]{40}$/)
        problem(lockfile " (" name "): sha must be 40 lowercase hex characters, got \"" sha "\"")
      if (url != m_url[name])
        problem(lockfile " (" name "): url disagrees with the manifest")
      if (branch != m_branch[name])
        problem(lockfile " (" name "): branch disagrees with the manifest")
      if (prefix != m_prefix[name])
        problem(lockfile " (" name "): prefix disagrees with the manifest")
      if (load != m_load[name])
        problem(lockfile " (" name "): load_type disagrees with the manifest")
    }

    END {
      for (i = 1; i <= n; i++)
        if (!(order[i] in locked))
          problem(order[i] ": in " manifest " but missing from " lockfile)
      print count + 0
    }
  ' "$manifest" "$lockfile"
)"

# --------------------------------------------- filesystem cross-checks
# Every declared plugin must exist on disk, and every vendored directory
# must be declared. Done in shell because awk should not stat the tree.
while IFS=$'\t' read -r name _url _branch prefix _load _trigger; do
  [ -n "$name" ] || continue
  if [ ! -d "$prefix" ]; then
    echo "plugin-verify: $name: declared in $manifest but $prefix does not exist" >&2
    problems=$((problems + 1))
  fi
done < <(tail -n +2 "$manifest")

for load_type in start opt; do
  dir="pack/vendor/$load_type"
  [ -d "$dir" ] || continue
  for path in "$dir"/*; do
    [ -d "$path" ] || continue
    name="$(basename "$path")"
    if ! awk -F'\t' -v n="$name" -v l="$load_type" 'NR>1 && $1==n && $5==l {found=1} END{exit !found}' "$manifest"; then
      echo "plugin-verify: $path is vendored but not declared in $manifest as a '$load_type' plugin" >&2
      problems=$((problems + 1))
    fi
  done
done

count="$(tail -n +2 "$manifest" | grep -c . || true)"
if [ "$problems" -eq 0 ]; then
  echo "plugin-verify: OK ($count plugins; manifest, lockfile and vendored directories agree)"
  exit 0
fi
echo "plugin-verify: $problems problem(s)" >&2
exit 1
