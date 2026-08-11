#!/usr/bin/env bash
# Two jobs, sharing one script so plugins.lock has exactly one writer:
#   scripts/plugin-status.sh                    -- print vendoring status (offline, no network)
#   scripts/plugin-status.sh --record ...        -- upsert one plugins.lock line (called by plugin-add.sh/plugin-update.sh)
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$repo_root/scripts/plugins.tsv"
lockfile="$repo_root/plugins.lock"

if [ "${1:-}" = "--record" ]; then
  shift
  name="$1" url="$2" branch="$3" prefix="$4" load_type="$5" sha="$6"
  touch "$lockfile"
  tmp="$(mktemp)"
  awk -F'\t' -v n="$name" 'NR==1 || $1!=n' "$lockfile" > "$tmp" 2>/dev/null || true
  if [ ! -s "$tmp" ]; then
    printf 'name\turl\tbranch\tsha\tprefix\tload_type\n' > "$tmp"
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$url" "$branch" "$sha" "$prefix" "$load_type" >> "$tmp"
  # keep header first, rest sorted by name for stable diffs
  { head -1 "$tmp"; tail -n +2 "$tmp" | sort; } > "$lockfile"
  rm -f "$tmp"
  exit 0
fi

cd "$repo_root"
printf "%-24s %-6s %-10s %s\n" "PLUGIN" "TYPE" "STATUS" "PREFIX"
tail -n +2 "$manifest" | while IFS=$'\t' read -r name url branch prefix load_type trigger; do
  if [ -d "$prefix" ]; then
    status="vendored"
  else
    status="MISSING"
  fi
  printf "%-24s %-6s %-10s %s\n" "$name" "$load_type" "$status" "$prefix"
done
