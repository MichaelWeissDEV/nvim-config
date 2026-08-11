#!/usr/bin/env bash
# Install a tool profile (LSPs/formatters/linters/debuggers via Mason, plus
# a default Tree-sitter parser set) for macOS/Linux. This is the ONE script
# meant to be run right after cloning, and the ONLY thing in this repo that
# talks to the network without being asked interactively inside Neovim --
# it is never invoked automatically by `nvim` itself.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
profile="${1:-}"

if [ -z "$profile" ]; then
  cat >&2 <<EOF
Usage: $0 <profile>
Profiles: core systems python scripting web jvm dotnet functional devops docs all

Examples:
  $0 core       # lua_ls, stylua, shellcheck, ... -- always useful
  $0 systems    # clangd, rust-analyzer, gopls, codelldb, delve, ...
  $0 all        # everything this config knows about (slow, large download)

This only installs tools via Mason + Tree-sitter -- it never installs
system packages. If a tool has no Mason package (e.g. ripgrep, fd, rustup
itself), :NvimConfigHealth / :ToolsStatus will tell you the manual install
command for your OS.
EOF
  exit 1
fi

if ! command -v nvim >/dev/null 2>&1; then
  echo "error: nvim not found on PATH" >&2
  exit 1
fi

echo "==> Bootstrapping tool profile '$profile' (this needs network access)"
nvim --headless -u "$repo_root/init.lua" -l "$repo_root/scripts/bootstrap.lua" "$profile"
