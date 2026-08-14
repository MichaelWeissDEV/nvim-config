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

echo "== clean-state startup (fresh XDG dirs: no prior Mason/Tree-sitter/Neovim data, repo present) =="
run_test "cleanstate" nvim -u init.lua --headless "+qa"

echo "== test_bootstrap.lua (runtimepath/packpath, the CI startup failure) =="
run_test "bootstrap" nvim -u init.lua --headless -l tests/test_bootstrap.lua

echo "== test_version.lua (Neovim >= 0.12.0 contract) =="
run_test "version" nvim -u init.lua --headless -l tests/test_version.lua

echo "== test_startup.lua =="
run_test "startup" nvim -u init.lua --headless -l tests/test_startup.lua

echo "== test_lazyload_failure.lua (failed loads roll back + retry) =="
run_test "lazyloadfail" nvim -u init.lua --headless -l tests/test_lazyload_failure.lua

echo "== test_lazyload_command_context.lua (bang/args/range/mods preserved) =="
run_test "lazyloadctx" nvim -u init.lua --headless -l tests/test_lazyload_command_context.lua

echo "== test_lazy_load.lua =="
run_test "lazyload" nvim -u init.lua --headless -l tests/test_lazy_load.lua

echo "== test_lsp_registry.lua (marker order, shared-server conflicts) =="
run_test "lspregistry" nvim -u init.lua --headless -l tests/test_lsp_registry.lua

echo "== test_registry_integrity.lua (registry valid + breakage caught) =="
run_test "integrity" nvim -u init.lua --headless -l tests/test_registry_integrity.lua

echo "== test_tools_refresh.lua (NvimConfigToolsChanged, no downloads) =="
run_test "toolsrefresh" nvim -u init.lua --headless -l tests/test_tools_refresh.lua

echo "== test_process.lua (interpreter resolution, venv, spaces) =="
run_test "process" nvim -u init.lua --headless -l tests/test_process.lua

echo "== test_commands.lua =="
run_test "commands" nvim -u init.lua --headless -l tests/test_commands.lua

echo "== test_directory_arg.lua (nvim <dir> cds into it, tree stays closed) =="
dir_fixture="$work/a-directory-argument"
mkdir -p "$dir_fixture"
run_test "directoryarg" nvim -u init.lua --headless --cmd "source tests/test_directory_arg.lua" "$dir_fixture"

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

echo "== plugin-verify (manifest/lock/vendored directories agree) =="
if bash scripts/plugin-verify.sh; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
fi

echo "== test_plugin_vendoring.sh (atomic vendoring, local git only) =="
if bash tests/test_plugin_vendoring.sh >/dev/null 2>&1; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  echo "---- (plugin vendoring) failed; re-run for detail: bash tests/test_plugin_vendoring.sh ----"
fi

echo "== test_release_notes.sh (the release body extracts from CHANGELOG.md) =="
if bash tests/test_release_notes.sh; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
fi

echo
echo "== populated-state startup (existing Mason/Tree-sitter data present, not a fresh clone) =="
# Distinct from the clean-state check above: reuse a real, already-populated
# XDG data dir if this machine has one (e.g. from a prior ./scripts/bootstrap.sh
# run) to prove startup is equally quiet with real accumulated tool/parser
# data present, not just on an empty directory. Falls back to a synthetic
# populated-looking dir (empty mason/lazy-parser directories in the expected
# shape) so this test stays meaningful and self-contained on a fresh clone
# that has never run bootstrap.sh.
populated_data=""
for candidate in "$HOME/Library/Application Support/nvim" "$HOME/.local/share/nvim" "${XDG_DATA_HOME:-}/nvim"; do
  if [ -n "$candidate" ] && [ -d "$candidate/mason" ]; then
    populated_data="$candidate"
    break
  fi
done
if [ -n "$populated_data" ]; then
  echo "   (using real populated dir: $populated_data)"
  state="$work/populated-state"
  cache="$work/populated-cache"
  mkdir -p "$state" "$cache"
  if env XDG_DATA_HOME="$(dirname "$populated_data")" XDG_STATE_HOME="$state" XDG_CACHE_HOME="$cache" \
    nvim -u init.lua --headless -l tests/test_startup.lua; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "---- (populated-state, real dir) failed ----"
  fi
else
  echo "   (no real populated dir found on this machine; using a synthetic one)"
  data="$work/populated-data"
  state="$work/populated-state"
  cache="$work/populated-cache"
  mkdir -p "$data/nvim/mason/bin" "$data/nvim/mason/packages" "$data/nvim/site/parser" "$state" "$cache"
  if env XDG_DATA_HOME="$data" XDG_STATE_HOME="$state" XDG_CACHE_HOME="$cache" \
    nvim -u init.lua --headless -l tests/test_startup.lua; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "---- (populated-state, synthetic dir) failed ----"
  fi
fi

echo
echo "=================================="
echo "PASS: $pass  FAIL: $fail"
echo "=================================="
[ "$fail" -eq 0 ]
