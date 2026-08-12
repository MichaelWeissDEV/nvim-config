# Architecture

## Design goals, in priority order

Stability, speed, portability, offline-capability, maintainability,
extensibility, low visual noise, real IDE features, complete documentation
— in that order. Plugin count was never a goal; every plugin in this repo
earns its place by doing something Neovim itself genuinely can't.

## Layout

```text
init.lua              small, just requires everything below in order
lua/
  config/              editor settings, keymaps, autocmds, the two meta-
                       command modules, the lazy-load helper, health check
  util/                platform facts, executable detection, path helpers,
                       notification dedup, and the keymap/command registries
  tools/               registry of every external LSP/formatter/linter/
                       debugger this config knows about, + detection/status/install
  languages/           the central language registry -- one small data file
                       per language (see below)
  lsp/                 turns languages.registry into native vim.lsp.config()/
                       vim.lsp.enable() calls
  debugger/            DAP wiring -- named "debugger", not "dap", to avoid
                       colliding with the vendored nvim-dap plugin's own
                       require("dap") (see the note in init.lua)
  plugins/             one file per vendored plugin's setup code
pack/vendor/
  start/               plugins Neovim loads automatically at startup
  opt/                 plugins loaded on demand via :packadd
scripts/               vendoring, bootstrap, docs-build, install
docs/                  this Sphinx site
doc/nvim-config.txt    native :help, generated from the same data
```

## The four registries

Everything that would otherwise be duplicated across LSP setup, formatter
config, docs, and interactive discovery lives in exactly one of four
registries:

`lua/languages/registry.lua`
: One file per language (`lua/languages/rust.lua`, `.../python.lua`, ...),
  each returning a plain data table: filetypes, Tree-sitter parser names,
  project root markers, which LSP/formatters/linters/debugger it uses (by
  tool id), and optional buffer-local keymaps. Nothing in a language file
  talks to a plugin API directly -- see {doc}`languages`.

`lua/tools/registry.lua`
: One entry per external tool (a language server, formatter, linter or
  debugger): its display name, the binary to check for, its Mason package
  name (if any), and which install profile(s) it belongs to. Language
  files reference tools by id; nothing hardcodes a binary or Mason package
  name more than once. See {doc}`tools`.

`util.keymap_registry` / `util.command_registry`
: Every keymap and every custom command in this config is registered
  through `km.map(...)` / `cmdreg.command(...)` instead of calling
  `vim.keymap.set()` / `vim.api.nvim_create_user_command()` directly. That
  single call simultaneously applies the mapping/command, and records it
  for `:NvimKeymaps`, `:NvimCommands`, which-key, and the generated
  `KEYMAPS.md`/`COMMANDS.md`. See {doc}`keymaps` and {doc}`commands`.

Because `scripts/generate-docs.lua` reads these same four registries to
produce `KEYMAPS.md`, `COMMANDS.md`, `LANGUAGES.md`, `TOOLS.md` and
`doc/nvim-config.txt`, there is exactly one place to update when a keymap,
command, language or tool changes -- not three or four.

## Consumers of the language registry

`lsp/registry.lua`, `plugins/formatting.lua`, `plugins/linting.lua` and
`debugger/registry.lua` each independently read `languages.registry.all()`
and build their own plugin's configuration from it:

- **LSP**: grouped by tool id (so `c` and `cpp` sharing `clangd` produces
  one `vim.lsp.config("clangd", ...)` call with the union of both
  filetypes), gated on the binary actually being on `PATH`, then handed to
  native `vim.lsp.enable()`. See {doc}`lsp`.
- **Formatting**: `conform.nvim`'s `formatters_by_ft` is built from
  installed formatters only; missing ones are silently omitted from the
  table (no startup warning) and only reported when you actually try to
  format. See {doc}`formatting`.
- **Linting**: `nvim-lint`'s linter list is filtered the same way, and
  re-checked live on every trigger (not just once at startup) so a linter
  installed mid-session via `:ToolsInstall` works without restarting. See
  {doc}`linting`.
- **Debugging**: adapters/configurations are registered lazily, the first
  time you actually try to debug a given filetype -- not at startup. See
  {doc}`debugging`.

## Plugin loading: what's `start`, what's `opt`

Neovim's native package system (`:h packages`) is the plugin loader here.
There is no custom plugin-manager engine -- `lua/config/lazyload.lua` is
~90 lines wrapping `vim.cmd.packadd()` and autocommands, nothing more.

**`pack/vendor/start/`** — sourced automatically at startup. Reserved for
things genuinely needed immediately (or, in nvim-treesitter's case,
things that explicitly [don't support lazy-loading](https://github.com/nvim-treesitter/nvim-treesitter)):
theme, statusline, which-key, Tree-sitter, completion, Git signs, Mason
(commands only), conform, nvim-lint, autopairs/surround.

**`pack/vendor/opt/`** — loaded on first use via one of:

- a `FileType` autocommand (`render-markdown.nvim` on `markdown`, `vimtex`
  on `tex`/`plaintex`/`bib`, `rainbow_csv` on `csv`/`tsv`),
- the first press of a relevant keymap (`telescope.nvim` on any
  `<leader>f*`, `nvim-tree.lua` on `<leader>e`, `oil.nvim` on `<leader>o`
  or `-`, `trouble.nvim` on `<leader>xx`, `nvim-dap` on any `<leader>d*`),
  ({file}`nvim-dap-ui`/{file}`nvim-nio` load even later still -- only once
  a debug session is actually *started*, not merely when a breakpoint is
  set).
- an explicit command (`:NvimTreeToggle`, `:Oil`, `:Trouble`, `:Telescope`).
- `nvim-tree.lua` also loads at `VimEnter` if Neovim's sole startup
  argument is a directory (`nvim .`, `nvim some/project`) -- see the
  autocommand in `plugins/tree.lua` and `tests/test_directory_arg.lua`.

A plain `nvim` with no file argument loads **zero** `opt` packages. You can
verify this yourself: `:lua for k in pairs(package.loaded) do print(k) end`
before touching anything, or see {doc}`troubleshooting` for the same check
scripted in `tests/`.

## Why not a "real" plugin manager (lazy.nvim, packer, ...)?

They all do their real work -- cloning, updating, lazy-loading -- through
mechanisms Neovim now provides natively: `git subtree` replaces cloning
(with the added benefit of the plugin source actually living in this
repo's history), and `:h packages` + a couple dozen lines of autocommand
glue replaces the lazy-loading engine. Adding a plugin manager on top would
be one more moving part with its own config surface, for a problem this
repo already solves at the two layers (vendoring, loading) where it
actually needs solving. See {doc}`plugin-updates` for how updates work
without one.

## Why not nvim-lspconfig / mason-lspconfig?

See the comment at the top of `lua/lsp/registry.lua` for the full
reasoning; in short: nvim-lspconfig's per-server default configs would
mostly be overridden by `languages.registry` anyway (we already know each
server's filetypes and root markers, because we wrote them once for the
language file), and mason-lspconfig's `automatic_enable` would start
servers based on what Mason has installed -- duplicating and potentially
fighting the language registry as the single source of truth for "which
server, for which filetype." Native `vim.lsp.config()`/`vim.lsp.enable()`
(stable since Neovim 0.11) already gives the lazy, per-filetype client
start this config wants, for free.
