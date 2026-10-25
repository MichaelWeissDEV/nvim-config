# Installation

## Requirements

- **Neovim 0.12.0 or newer.** Check with `nvim --version`. This is a hard
  minimum: the vendored nvim-treesitter is its `main` branch, which
  requires 0.12+ (the frozen `master` branch is the one that supports
  0.11, and this config deliberately does not use it).
  `./scripts/install.sh` verifies the version and refuses to continue on
  anything older, so you get a clear message rather than a broken editor.
- **git** — for cloning and for the `git subtree`-based plugin vendoring
  scripts.
- Optional, but recommended: **ripgrep** (`rg`) and **fd** for faster
  Telescope search; a [Nerd Font](https://www.nerdfonts.com/) (e.g.
  JetBrainsMonoNL Nerd Font) for icons in the statusline/file explorer/which-key.

Nothing else is required to get a working editor. Language servers,
formatters, linters and debuggers are all optional and installed later,
on purpose — see {doc}`offline`.

## If you already have a Neovim configuration

Read this first — cloning straight into `~/.config/nvim` only works if
that directory does not exist yet.

Back up whatever is there before doing anything else:

```bash
mv ~/.config/nvim ~/.config/nvim.backup
```

For a genuinely clean slate, also move Neovim's data and state
directories aside (plugins, Mason downloads, shada, undo history live
there, not in your config):

```bash
mv ~/.local/share/nvim ~/.local/share/nvim.backup
mv ~/.local/state/nvim ~/.local/state/nvim.backup
```

`./scripts/install.sh` never deletes or overwrites an existing
configuration. If it finds one that isn't this repository it refuses and
tells you what to do; `./scripts/install.sh --backup` makes it move the
existing config to a timestamped directory first. Nothing in either mode
touches your data or state directories.

## Clone

```bash
git clone https://github.com/MichaelWeissDEV/nvim-config.git ~/.config/nvim
nvim
```

Over SSH instead:

```bash
git clone git@github.com:MichaelWeissDEV/nvim-config.git ~/.config/nvim
```

On Linux and macOS, Neovim reads its config from `$XDG_CONFIG_HOME/nvim`
(usually `~/.config/nvim`) via `stdpath('config')`. On Windows it's
`%LOCALAPPDATA%\nvim`. If you already keep this repository somewhere else,
symlink it into place instead of cloning twice:

```bash
git clone https://github.com/MichaelWeissDEV/nvim-config.git ~/git/nvim-config
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
debugger — that's entirely opt-in. The quickest way is **per language,
from inside Neovim**: open a file and press `<leader>tl`, or run

```vim
:LangInstall python
:LangInstall rust
```

This installs that language's server(s), formatter, linter, debugger and
Tree-sitter parsers through Mason, in the background. `:LangInfo`
(`<leader>ti`) shows what a language uses and what is still missing (see
{doc}`languages`).

To set up whole groups at once, including from a shell on a fresh
machine, install a **tool profile**:

```bash
./scripts/bootstrap.sh core      # always useful: lua_ls, stylua, shellcheck, ...
./scripts/bootstrap.sh systems   # clangd, rust-analyzer, gopls, codelldb, delve, ...
./scripts/bootstrap.sh python    # ty, ruff, basedpyright, debugpy
./scripts/bootstrap.sh web       # TS/JS, HTML, CSS, eslint, prettier, ...
```

See {doc}`tools` for the full profile list and every tool it installs, and
{doc}`offline` for exactly what does and doesn't touch the network.

## Personal settings: `lua/config/local.lua`

Machine-specific settings go in `lua/config/local.lua`. The file is
gitignored, so `git pull` never conflicts with it. Copy the template,
which lists every supported switch:

```bash
cp lua/config/local.example.lua lua/config/local.lua
```

For example, choose basedpyright over ty
(`vim.g.nvim_config_python_lsp`), render markdown automatically
(`vim.g.nvim_config_markdown_render`), or turn off format-on-save. The
file is loaded right after `config/options.lua`, before any plugin or
language module. If it fails to load, you get a loud error at startup; it
is never silently ignored.

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
