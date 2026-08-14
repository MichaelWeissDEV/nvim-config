#!/usr/bin/env bash
# Release-note extraction.
#
# scripts/release-notes.sh only ever ran during a release, so its failure
# mode was: tag pushed, quality gate green, release job dies. It had never
# once succeeded -- the awk pattern was mangled by `awk -v`'s own escape
# processing before awk saw it. This test runs the real script against the
# real CHANGELOG for every version it documents, so the next such break is
# caught on an ordinary push rather than at release time.
#
# No network, no git writes, no GitHub API.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

script="scripts/release-notes.sh"
changelog="CHANGELOG.md"
failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

versions="$(sed -n 's/^## \[\([0-9][0-9.]*\)\].*/\1/p' "$changelog")"
if [ -z "$versions" ]; then
  fail "CHANGELOG.md documents no released version at all -- the heading format must have changed"
  exit 1
fi

for version in $versions; do
  if ! notes="$(bash "$script" "$version" 2>/dev/null)"; then
    fail "no release notes extracted for $version (the release job would abort here)"
    continue
  fi

  # Must not be empty...
  if [ -z "${notes//[[:space:]]/}" ]; then
    fail "release notes for $version are blank"
  fi

  # ...and must not bleed into the next version's section.
  if printf '%s\n' "$notes" | grep -q '^## \['; then
    fail "release notes for $version contain another version heading"
  fi

  echo "  ok: $version ($(printf '%s\n' "$notes" | wc -l | tr -d ' ') lines)"
done

# A version that is not in the changelog must fail loudly rather than
# produce an empty release body.
if bash "$script" "99.99.99" >/dev/null 2>&1; then
  fail "an unknown version must exit non-zero, not return nothing"
fi

# The newest heading must match the newest annotated tag when one exists --
# tagging v0.1.1 while the changelog still says [Unreleased] is exactly how
# the release body ends up empty.
newest_heading="$(printf '%s\n' "$versions" | head -1)"
if newest_tag="$(git describe --tags --abbrev=0 2>/dev/null)"; then
  if [ "${newest_tag#v}" != "$newest_heading" ]; then
    echo "  note: newest tag $newest_tag, newest changelog section [$newest_heading]" >&2
  fi
fi

if [ "$failures" -gt 0 ]; then
  echo "release notes: $failures problem(s)" >&2
  exit 1
fi

echo "release notes: OK (every documented version extracts cleanly)"
