# FAQ

Short answers with a pointer to the page that explains properly. If your
question is "why is X broken", start at {doc}`troubleshooting` instead —
that page is organised by symptom.

## Getting started

### Do I need an internet connection?

Not to *use* it. Every plugin is vendored in `pack/vendor/`, so a clone and
`nvim` is the whole install — nothing is downloaded at startup, ever. You
need the network only for three explicit, opt-in actions: installing
external tools (`:ToolsInstall`, `:Mason`), installing Tree-sitter parsers
(`:TSInstall`), and updating vendored plugins. See {doc}`offline`.

### Will this overwrite my existing Neovim config?

`./scripts/install.sh` refuses to clobber an existing `~/.config/nvim` — it
tells you what it found and stops. Pass `--backup` (or `-Backup` for
`install.ps1` on Windows) to have it move the existing configuration aside
first. {doc}`installation` shows the manual `mv` commands too, including
the data and state directories.

### Why does it require Neovim 0.12.0?

Not a preference — a hard requirement, enforced by
`lua/util/version.lua`, the installers and `:NvimConfigHealth`. This config
uses native `vim.lsp.config()`/`vim.lsp.enable()`, `vim.diagnostic.jump()`,
`vim.opt.winborder` and `vim.fn.jobstart(…, { term = true })`, and the
Tree-sitter setup that supports it. On an older Neovim it would not fail
cleanly, it would fail confusingly.

### I see boxes instead of icons.

Your terminal is not using a [Nerd Font](https://www.nerdfonts.com/).
Neovim only prints codepoints; the font is a terminal setting. Install e.g.
JetBrainsMono Nerd Font and select it in your terminal profile. Nothing is
broken in the meantime — see {doc}`ui`.

## Daily use

### How do I find out what a key does?

Three ways, all reading the same registry: press `<leader>` and wait for
the which-key popup, run `:NvimKeymaps` for the full grouped list, or read
{doc}`keymaps`. Commands have the same treatment: `:NvimCommands` and
{doc}`commands`.

### How do I open the file tree?

`<leader>e` toggles the nvim-tree sidebar; `<leader>o` (or `-`) opens Oil,
which edits a directory as if it were a buffer. Neither is loaded until
you press the key. `nvim .` changes into the directory but deliberately
does **not** pop the sidebar open. See {doc}`files`.

### Nothing autocompletes / no hover / no go-to-definition.

Almost always a missing language server binary rather than a
misconfiguration. Run `:LspStatus` — if the server is not listed under
"Configured servers (binary found on PATH)", install it with
`:ToolsInstall <profile>`. {doc}`troubleshooting` has the full five-step
diagnosis, including the root-marker case where the server is installed but
correctly refuses to start.

### I installed a tool but Neovim still says it is missing.

It should not: `:ToolsInstall`/`:ToolsUpdate` reset the executable cache
and fire a `User NvimConfigToolsChanged` event when every package finishes,
and formatters, linters and the LSP registry all re-check on it. The one
exception is a buffer that was **already open** when the language server
arrived — that buffer needs `:e` before the new client attaches. See
{doc}`tools`.

### Why is my huge log file not highlighted?

Because it is huge. Files over 5 MiB, or with any sampled line longer than
20 000 characters, get Tree-sitter, diagnostics, LSP, folds, spell, swap
and undo switched off so they open at normal speed. Confirm with
`:lua = vim.b.large_file`; details in {doc}`ui`.

### Format on save is doing something I do not want.

`<leader>uf` toggles it for the current buffer, `<leader>uF` globally, and
`:FormatStatus` tells you whether it is active **and why**. {doc}`formatting`
covers the formatter selection order.

## Design questions

### Why no plugin manager (lazy.nvim, packer, …)?

Because their two real jobs are already solved here at the layers where
they need solving. `git subtree` replaces cloning — with the side benefit
that plugin source lives in this repository's own history, so a tag pins
the config *and* every plugin version together. Neovim's native package
system (`:h packages`) plus one small module,
`lua/config/lazyload.lua`, replaces the lazy-loading engine. Adding a
manager on top would be one more moving part with its own configuration
surface. {doc}`architecture` argues it at length; {doc}`plugin-updates`
shows how updating works without one.

### Why no nvim-lspconfig or mason-lspconfig?

nvim-lspconfig's per-server defaults would be overridden by the language
registry anyway — filetypes and root markers are already written down once
per language. mason-lspconfig's `automatic_enable` would start servers
based on what Mason happens to have installed, which duplicates and can
fight the registry as the single source of truth. Native
`vim.lsp.config()`/`vim.lsp.enable()` already gives per-filetype lazy client
start. See the comment at the top of `lua/lsp/registry.lua`, and
{doc}`lsp`.

### Is this a distribution?

No, and deliberately not. No LazyVim, NvChad, AstroNvim, LunarVim or
SpaceVim is used anywhere. Everything is configuration you can read; there
is no framework layer whose behaviour you would have to reverse-engineer
before changing something.

### Why is the startup so quiet?

Because a missing optional tool is not an error. Anything optional is
detected, never assumed, and reports **at most one** message — and only
when you actually use the feature whose dependency is missing, never at
startup. A clean session notifies nothing at all. If you do see an
`[nvim-config] … failed to load:` popup, that is a real bug rather than a
missing tool; {doc}`troubleshooting` explains the difference.

## Changing things

### How do I add a language?

Add one data file under `lua/languages/`, referencing tools by id. Nothing
else: LSP, formatting, linting, debugging, the documentation tables and
`:NvimKeymaps` all read that same registry. {doc}`languages` has the schema
and {doc}`development` the walkthrough. `lua/config/integrity.lua` will
tell you immediately if the new entry contradicts an existing one.

### How do I add a plugin?

`./scripts/plugin-add.sh` vendors it via `git subtree` into
`pack/vendor/start` or `pack/vendor/opt` and records the exact commit in
`plugins.lock`; then write its `setup()` in a file under `lua/plugins/`.
{doc}`plugin-updates` covers add, update and remove, including why the
lockfile and the manifest are cross-validated in CI.

### How do I change the colour scheme?

`lua/plugins/theme.lua` for the scheme, `lua/plugins/statusline.lua` for
lualine's matching theme name. Nothing else reads the theme. {doc}`ui`.

### Where do per-filetype indent settings live?

`after/ftplugin/<filetype>.lua`, one small file per filetype, each setting
`shiftwidth`/`tabstop`/`softtabstop` with `vim.opt_local`. They are kept
deliberately in step with the formatter for that language — `lua.lua`
matches `.stylua.toml`'s `indent_width = 2`, so format-on-save does not
fight what you just typed. Neovim sources `after/` last, which is exactly
why the setting survives whatever a plugin did earlier.

### How do I keep my own tweaks?

This repository is meant to be cloned and edited — there is no separate
"user config" layer, because everything is already the readable layer.
Keymaps go through `util.keymap_registry` and commands through
`util.command_registry` (see {doc}`development`), which keeps them in
`:NvimKeymaps` and the docs rather than becoming invisible local edits. If
you intend to pull updates from upstream later, keep your changes in the
registry files and in `after/ftplugin/` where merges stay
straightforward.

## Documentation

### Where is the documentation offline?

Two copies, both from the same registries. `:help nvim-config` is generated
into `doc/nvim-config.txt` and always available inside Neovim.
`./scripts/docs-build.sh` builds this Sphinx site locally, and `:NvimDocs`
opens it if it has been built, falling back to `:help` if not.

### The reference tables look generated. Can I edit them?

No — everything under `docs/_generated/` is written by
`scripts/generate-docs.lua` from the four registries, and CI fails if the
committed output drifts from what the registries currently produce. Edit
the registry; the table follows. That is the whole point of
{doc}`architecture`'s single-source-of-truth rule.
