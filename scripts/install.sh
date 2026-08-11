#!/usr/bin/env bash
# One-time, offline setup after cloning: generate :help tags and (if no
# Neovim config exists yet) symlink this repo into place. Never touches the
# network. Safe to re-run.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v nvim >/dev/null 2>&1; then
  echo "error: nvim not found on PATH (need Neovim 0.11+, 0.12+ recommended)" >&2
  exit 1
fi

echo "==> Generating :help tags"
nvim --headless -c "helptags $repo_root/doc" -c "qa"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
  resolved="$(cd "$config_dir" 2>/dev/null && pwd -P || true)"
  if [ "$resolved" = "$repo_root" ]; then
    echo "==> $config_dir already points here."
  else
    echo "==> $config_dir already exists and is NOT this repo -- leaving it alone."
    echo "    To use this config instead, move it aside and re-run this script, e.g.:"
    echo "      mv \"$config_dir\" \"$config_dir.bak\" && ln -s \"$repo_root\" \"$config_dir\""
  fi
else
  mkdir -p "$(dirname "$config_dir")"
  ln -s "$repo_root" "$config_dir"
  echo "==> Linked $config_dir -> $repo_root"
fi

echo "==> Done. Run 'nvim' to start, then :NvimConfigHealth to see what's missing,"
echo "    and ./scripts/bootstrap.sh <profile> to install LSPs/formatters/linters/debuggers."
