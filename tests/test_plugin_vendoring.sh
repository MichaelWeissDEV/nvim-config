#!/usr/bin/env bash
# Plugin vendoring must be atomic: the commit recorded in plugins.lock has
# to be the commit that was actually vendored.
#
# The defect this guards: plugin-add/update used to pass the *branch name*
# to `git subtree`, then separately ask `git ls-remote` for that branch's
# head afterwards. If upstream published between those two steps, the
# lockfile recorded a commit that was never vendored -- the lockfile would
# describe a tree that does not exist in the repository.
#
# Entirely local: a temporary upstream repository on disk, a temporary
# consumer repository. No GitHub, no network.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail=0
check() {
  if [ "$2" = "$3" ]; then
    echo "  OK   $1"
  else
    echo "  FAIL $1"
    echo "       expected: $3"
    echo "       actual:   $2"
    fail=$((fail + 1))
  fi
}

# Identity for the throwaway repositories. Exported rather than passed as
# `git -c ...` because the scripts under test invoke git themselves.
export GIT_AUTHOR_NAME=nvim-config-test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=nvim-config-test GIT_COMMITTER_EMAIL=test@example.invalid
git_quiet() { git "$@" >/dev/null 2>&1; }

# ------------------------------------------------------------ upstream
upstream="$work/upstream"
mkdir -p "$upstream"
git -C "$upstream" init -q -b main
echo "content A" > "$upstream/file.lua"
git -C "$upstream" add -A
git_quiet -C "$upstream" commit -m "A"
sha_a="$(git -C "$upstream" rev-parse HEAD)"

# ------------------------------------------------------------ consumer
consumer="$work/consumer"
mkdir -p "$consumer/scripts" "$consumer/pack/vendor/start" "$consumer/pack/vendor/opt"
cp "$repo_root/scripts/plugin-add.sh" "$repo_root/scripts/plugin-update.sh" \
  "$repo_root/scripts/plugin-status.sh" "$repo_root/scripts/plugin-verify.sh" "$consumer/scripts/"
printf 'name\turl\tbranch\tprefix\tload_type\ttrigger\n' > "$consumer/scripts/plugins.tsv"
printf 'fixture\tfile://%s\tmain\tpack/vendor/opt/fixture\topt\ttest fixture\n' "$upstream" >> "$consumer/scripts/plugins.tsv"
printf 'name\turl\tbranch\tsha\tprefix\tload_type\n' > "$consumer/plugins.lock"

git -C "$consumer" init -q -b main
git -C "$consumer" add -A
git_quiet -C "$consumer" commit -m "init"

lock_sha() {
  awk -F'\t' 'NR>1 && $1=="fixture" {print $4}' "$consumer/plugins.lock"
}

echo "== plugin-add locks the commit it vendored =="
add_out="$( cd "$consumer" && bash scripts/plugin-add.sh fixture 2>&1 )" || echo "$add_out"
check "lock records commit A" "$(lock_sha)" "$sha_a"
check "vendored content is A" "$(cat "$consumer/pack/vendor/opt/fixture/file.lua" 2>/dev/null)" "content A"

echo "== plugin-update moves both the tree and the lock to B =="
echo "content B" > "$upstream/file.lua"
git -C "$upstream" add -A
git_quiet -C "$upstream" commit -m "B"
sha_b="$(git -C "$upstream" rev-parse HEAD)"

upd_out="$( cd "$consumer" && bash scripts/plugin-update.sh fixture 2>&1 )" || echo "$upd_out"
check "lock records commit B" "$(lock_sha)" "$sha_b"
check "vendored content is B" "$(cat "$consumer/pack/vendor/opt/fixture/file.lua" 2>/dev/null)" "content B"

echo "== the lock never points at a commit that was not vendored =="
# Move the branch forward *after* the update. The lock must still describe
# the commit actually sitting in pack/vendor, not the new upstream head.
echo "content C" > "$upstream/file.lua"
git -C "$upstream" add -A
git_quiet -C "$upstream" commit -m "C"
sha_c="$(git -C "$upstream" rev-parse HEAD)"
check "lock still on B, not the newer C" "$(lock_sha)" "$sha_b"
check "upstream really did move" "$([ "$sha_c" != "$sha_b" ] && echo moved)" "moved"

echo "== re-running update when already current is a no-op =="
upd_out="$( cd "$consumer" && bash scripts/plugin-update.sh fixture 2>&1 )" || echo "$upd_out"
check "lock now on C" "$(lock_sha)" "$sha_c"
before="$(git -C "$consumer" rev-parse HEAD)"
upd_out="$( cd "$consumer" && bash scripts/plugin-update.sh fixture 2>&1 )" || echo "$upd_out"
check "second update creates no commit" "$(git -C "$consumer" rev-parse HEAD)" "$before"

echo "== plugin-verify accepts the resulting state =="
verify_out="$(cd "$consumer" && bash scripts/plugin-verify.sh 2>&1)"
verify_rc=$?
check "plugin-verify exits 0" "$verify_rc" "0"
if [ "$verify_rc" -ne 0 ]; then
  echo "$verify_out"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "PASS: plugin vendoring is atomic"
  exit 0
fi
echo "FAIL: $fail assertion(s) failed"
exit 1
