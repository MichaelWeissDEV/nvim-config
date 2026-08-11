# Installation

## Requirements

- **Neovim 0.11+** (0.12+ recommended; this config is developed and tested
  against 0.12). Check with `nvim --version`.
- **git** — for cloning and for the `git subtree`-based plugin vendoring
  scripts.
- Optional, but recommended: **ripgrep** (`rg`) and **fd** for faster
  Telescope search; a [Nerd Font](https://www.nerdfonts.com/) (e.g.
  JetBrainsMono Nerd Font) for icons in the statusline/file explorer/which-key.

Nothing else is required to get a working editor. Language servers,
formatters, linters and debuggers are all optional and installed later,
on purpose — see {doc}`offline`.

## Clone

```bash
git clone <this-repo-url> ~/.config/nvim
nvim
```

On Linux and macOS, Neovim reads its config from `$XDG_CONFIG_HOME/nvim`
(usually `~/.config/nvim`) via `stdpath('config')`. On Windows it's
`%LOCALAPPDATA%\nvim`. If you already keep this repository somewhere else,
symlink it into place instead of cloning twice:

```bash
git clone <this-repo-url> ~/git/nvim-config
ln -s ~/git/nvim-config ~/.config/nvim
```

`./scripts/install.sh` (`.\scripts\install.ps1` on Windows) automates
exactly that check-and-symlink step, plus generating `:help` tags — see
below.

## First launch

```bash
nvim
```

should start in well under a second, with:

- the Catppuccin Mocha theme and statusline active,
- no error messages and no notifications (a few informational ones the
  first time only if e.g. `ripgrep` truly isn't installed — see
  {doc}`troubleshooting` if you see anything alarming),
- Telescope, Oil, debugging, etc. all present but not yet loaded (they load
  the first time you actually use them — see {doc}`architecture`).

Run `:NvimConfigHealth` to see a full report of what's vendored and what
optional external tools are missing on this machine.

## Generating `:help` tags

The native help (`:help nvim-config`) needs a generated tag index. Either:

```bash
./scripts/install.sh
```

or manually:

```vim
:helptags ~/.config/nvim/doc
```

## Installing language tooling

Nothing above installs a single language server, formatter, linter or
debugger — that's entirely opt-in. Once Neovim itself is working, install
a **tool profile** for the languages you actually use:

```bash
./scripts/bootstrap.sh core      # always useful: lua_ls, stylua, shellcheck, ...
./scripts/bootstrap.sh systems   # clangd, rust-analyzer, gopls, codelldb, delve, ...
./scripts/bootstrap.sh python    # basedpyright, ruff, debugpy
./scripts/bootstrap.sh web       # TS/JS, HTML, CSS, eslint, prettier, ...
```

See {doc}`tools` for the full profile list and every tool it installs, and
{doc}`offline` for exactly what does and doesn't touch the network.

## Building the local documentation (optional)

This Sphinx site is built locally, from Markdown, with no external hosting:

```bash
./scripts/docs-build.sh
```

Output goes to `docs/_build/html/index.html` (gitignored — it's a build
artifact, not part of the repo). `:NvimDocs` opens it directly from inside
Neovim once built, falling back to `:help nvim-config` if it hasn't been
built yet.

## Building on Windows

Everything above works the same way with the `.ps1` counterparts:
`.\scripts\install.ps1`, `.\scripts\bootstrap.ps1 <profile>`,
`.\scripts\docs-build.ps1`. See {doc}`platform` for what differs under the
hood (shell, paths, clipboard).
