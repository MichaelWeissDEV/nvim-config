#!/usr/bin/env bash
# Print the CHANGELOG section for one version, i.e. the release notes.
#
# Used by .github/workflows/release.yml to build a release body, and by
# tests/test_release_notes.sh to prove it still works. Those two calling the
# same script is the point: the extraction used to live inline in the
# workflow, where it ran exactly once per release -- at the moment a failure
# is most expensive and least expected. It had in fact never worked.
#
# Usage: release-notes.sh <version> [changelog-file]
#   version         without the leading "v", e.g. 0.1.1
#   changelog-file  defaults to CHANGELOG.md next to this script's repo root
#
# Exits non-zero, with a message on stderr, when the version has no section.
set -euo pipefail

version="${1:-}"
if [ -z "$version" ]; then
  echo "usage: release-notes.sh <version> [changelog-file]" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
changelog="${2:-$repo_root/CHANGELOG.md}"

if [ ! -f "$changelog" ]; then
  echo "release-notes: no such file: $changelog" >&2
  exit 2
fi

# The heading is matched with index() as a LITERAL string, never as a regex.
# `awk -v` runs escape processing on its assignments, so a pattern written as
# "## \[$version\]" arrives as "## [0.1.1]" -- which awk then reads as a
# character class matching a single 0, . or 1, and no heading ever matches.
# That silent mangling is what made every release run fail.
notes="$(
  awk \
    -v start="## [$version]" \
    'index($0, start) == 1 { found = 1; next } /^## \[/ { found = 0 } found { print }' \
    "$changelog"
)"

if [ -z "${notes//[[:space:]]/}" ]; then
  echo "release-notes: no '## [$version]' section in $changelog" >&2
  exit 1
fi

printf '%s\n' "$notes"
