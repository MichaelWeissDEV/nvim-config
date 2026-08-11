# Offline Mode

## The rule

A normal `nvim` session — opening files, editing, using LSP/completion/
formatting/linting/debugging for whatever tools are already installed —
never touches the network. Nothing in `init.lua` or anything it
transitively requires performs a `git clone`, `curl`, `wget`, npm/pip/cargo
install, or Mason registry refresh as a side effect of starting up or
opening a file.

## What's vendored vs. what stays external

Every **plugin** is vendored in `pack/vendor/{start,opt}/` via `git
subtree` (see {doc}`plugins` and {doc}`plugin-updates`). Cloning this repo
is enough to have every plugin's source already present — there is no
plugin-manager download step, ever.

**Language tooling** (language servers, formatters, linters, debuggers) is
different by design: these are large, per-language, often per-OS binaries
that most users only need a handful of. They are never vendored, never
auto-installed, and their absence is never an error — see
{doc}`troubleshooting` for exactly how a missing tool degrades. You install
what you need, explicitly, with `./scripts/bootstrap.sh <profile>` or
`:ToolsInstall <profile>` (both wrap Mason).

## The one explicit exception: Tree-sitter parsers

Neovim ships a handful of Tree-sitter parsers built in (`c`, `lua`,
`markdown`, `markdown_inline`, `query`, `vim`, `vimdoc` — check
`:lua =vim.tbl_keys(vim.treesitter.language.get_lang and {} or {})` or
simply try `:TSInstall! <lang>` and see if it's already there). Every other
language's parser is **not** bundled or auto-installed. Opening a Python
file with no Python parser installed just means no Tree-sitter
highlighting for that buffer — no error (see `plugins/treesitter.lua`,
which wraps `vim.treesitter.start()` in `pcall`). To get a parser, run
`:TSInstall <language>` yourself. This is the one deliberate,
always-explicit exception to "no network at runtime," and
`./scripts/bootstrap.sh <profile>` installs a sane default parser set per
profile at the same time it installs that profile's Mason tools.

nvim-treesitter's own README is explicit that it "does not support
lazy-loading," which is why it lives in `pack/vendor/start/` rather than
`opt/` — but *using* it (beyond the handful of built-in parsers) still
requires the explicit `:TSInstall` step above.

### `tree-sitter-cli` is a real system requirement

`:TSInstall`/`:TSUpdate`/`./scripts/bootstrap.sh` compile parsers using the
external `tree-sitter` CLI (0.26.1+) and a C compiler — both installed
separately from Neovim, per
[nvim-treesitter's own requirements](https://github.com/nvim-treesitter/nvim-treesitter#requirements).
Without it, parser installation fails with an `ENOENT: no such file or
directory (cmd): 'tree-sitter'` error (logged, not fatal — the rest of a
`bootstrap.sh` run still completes). Install it via:

```bash
# macOS
brew install tree-sitter-cli
# Arch
sudo pacman -S tree-sitter-cli
# Debian/Ubuntu
sudo apt install tree-sitter-cli   # or: cargo install tree-sitter-cli
```

This was caught during real testing on the primary development Mac, which
did not have `tree-sitter-cli` installed — Mason tool installation still
succeeded in full; only parser compilation was skipped. See the Known
Limitations section of the project's final report for the exact
transcript.

## What `bootstrap.sh`/`bootstrap.ps1` and Mason commands do

These are the **only** things in this repository that talk to the network,
and only when run explicitly:

- `./scripts/bootstrap.sh <profile>` / `.ps1` — installs that profile's
  Mason packages and a default Tree-sitter parser set. Never runs on its
  own; you type the command.
- `:ToolsInstall <profile>` / `:ToolsUpdate <profile>` — the in-editor
  equivalent, via `mason.nvim`.
- `:Mason`, `:MasonInstall <pkg>`, `:MasonUpdate` — Mason's own commands,
  documented (but not redefined) in {doc}`mason`.
- `:TSInstall <lang>`, `:TSUpdate` — Tree-sitter parser installation.
- `scripts/plugin-add.sh` / `plugin-update.sh` / `plugin-update-all.sh` —
  maintainer-only, fetch a plugin's upstream git history for vendoring
  (see {doc}`plugin-updates`). Never run by Neovim itself.
- `./scripts/docs-build.sh` — the *first* run creates `docs/.venv` and
  `pip install`s Sphinx; every run after that is fully local.

Nothing else — no autocommand, no plugin's own startup code, no `FileType`
handler — performs a network operation.

## Verifying this yourself

```bash
# Simulate no network at all and confirm a normal session still starts:
nvim --headless "+qa"; echo "exit: $?"
```

See `tests/` for the actual automated offline and missing-dependency
checks this repository runs against itself.
