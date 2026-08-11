#!/usr/bin/env bash
# Real, headless test suite. No test framework -- each tests/test_*.lua is
# a standalone script run via `nvim --headless -l`, exiting 0/1 (see
# tests/lib.lua). This script just orchestrates them, isolates each run's
# XDG state so no test can see another's, and for test_missing_deps.lua
# specifically strips PATH down to nvim/git/sh only, so "missing optional
# tool" is genuinely true rather than merely assumed.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

pass=0
fail=0
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

run_test() {
  local label="$1"
  shift
  local data state cache
  data="$work/$label-data"
  state="$work/$label-state"
  cache="$work/$label-cache"
  mkdir -p "$data" "$state" "$cache"

  if env XDG_DATA_HOME="$data" XDG_STATE_HOME="$state" XDG_CACHE_HOME="$cache" "$@"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "---- ($label) command: $* ----"
  fi
}

echo "== headless startup (exit code) =="
run_test "exitcode" nvim -u init.lua --headless "+qa"

echo "== test_startup.lua =="
run_test "startup" nvim -u init.lua --headless -l tests/test_startup.lua

echo "== test_lazy_load.lua =="
run_test "lazyload" nvim -u init.lua --headless -l tests/test_lazy_load.lua

echo "== test_commands.lua =="
run_test "commands" nvim -u init.lua --headless -l tests/test_commands.lua

echo "== test_missing_deps.lua (PATH stripped to nvim/git/sh/bash only) =="
restricted_bin="$work/bin"
mkdir -p "$restricted_bin"
for tool in nvim git sh bash env; do
  src="$(command -v "$tool" 2>/dev/null || true)"
  [ -n "$src" ] && ln -sf "$src" "$restricted_bin/$tool"
done
data="$work/missingdeps-data"
state="$work/missingdeps-state"
cache="$work/missingdeps-cache"
mkdir -p "$data" "$state" "$cache"
if env -i PATH="$restricted_bin" HOME="$HOME" XDG_DATA_HOME="$data" XDG_STATE_HOME="$state" XDG_CACHE_HOME="$cache" \
  nvim -u init.lua --headless -l tests/test_missing_deps.lua; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  echo "---- (missingdeps) failed ----"
fi

echo
echo "== Clean-state test (no prior Mason/Tree-sitter/Neovim data, existing repo) =="
run_test "cleanstate" nvim -u init.lua --headless "+qa"

echo
echo "=================================="
echo "PASS: $pass  FAIL: $fail"
echo "=================================="
[ "$fail" -eq 0 ]
