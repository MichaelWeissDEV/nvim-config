#!/usr/bin/env bash
# One-time, offline setup after cloning: generate :help tags and symlink
# this repo into place as your Neovim config. Never touches the network.
# Safe to re-run.
#
# An existing Neovim configuration is NEVER overwritten or deleted. Without
# --backup the script refuses and tells you what to do; with --backup it
# moves the existing config to a timestamped directory next to it first.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

do_backup=0
for arg in "$@"; do
  case "$arg" in
    --backup) do_backup=1 ;;
    -h | --help)
      cat <<EOF
Usage: $0 [--backup]

  --backup   If a different Neovim config already exists, move it to
             <config-dir>.backup.<timestamp> instead of refusing.

Never deletes anything. Without --backup an existing config is left
untouched and this script exits with an error.
EOF
      exit 0
      ;;
    *)
      echo "error: unknown argument '$arg' (try --help)" >&2
      exit 1
      ;;
  esac
done

if ! command -v nvim >/dev/null 2>&1; then
  echo "error: nvim not found on PATH (need Neovim 0.11+, 0.12+ recommended)" >&2
  exit 1
fi

echo "==> Generating :help tags"
# -u NONE: generating tags must not load *any* user config -- without it
# this picks up whatever config already lives in XDG_CONFIG_HOME and
# prints that config's errors, which is confusing when the whole point
# of the next step is that a foreign config is present.
nvim --headless -u NONE -c "helptags $repo_root/doc" -c "qa"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

link_it() {
  mkdir -p "$(dirname "$config_dir")"
  ln -s "$repo_root" "$config_dir"
  echo "==> Linked $config_dir -> $repo_root"
}

if [ -e "$config_dir" ] || [ -L "$config_dir" ]; then
  resolved="$(cd "$config_dir" 2>/dev/null && pwd -P || true)"
  if [ "$resolved" = "$repo_root" ]; then
    echo "==> $config_dir already points here, nothing to do."
  elif [ "$do_backup" -eq 1 ]; then
    backup="$config_dir.backup.$(date +%Y%m%d%H%M%S)"
    mv "$config_dir" "$backup"
    echo "==> Moved existing configuration to $backup"
    link_it
  else
    cat >&2 <<EOF

Existing Neovim configuration found:
  $config_dir

Refusing to overwrite it.

Either move it away yourself:
  mv "$config_dir" "$config_dir.backup"

or re-run with --backup to have this script move it for you:
  $0 --backup

Your Neovim data and state directories are never touched by this script;
if you want a completely clean slate you also need to move these aside:
  ${XDG_DATA_HOME:-$HOME/.local/share}/nvim
  ${XDG_STATE_HOME:-$HOME/.local/state}/nvim
EOF
    exit 1
  fi
else
  link_it
fi

echo "==> Done. Run 'nvim' to start, then :NvimConfigHealth to see what's missing,"
echo "    and ./scripts/bootstrap.sh <profile> to install LSPs/formatters/linters/debuggers."
