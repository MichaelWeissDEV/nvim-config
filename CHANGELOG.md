# Changelog

All notable changes to this configuration are documented here. The format
is loosely based on [Keep a Changelog](https://keepachangelog.com/1.1.0/)
and versions follow [Semantic Versioning](https://semver.org/).

Each release is a git tag, so `git checkout v0.1.0` gives you a known-good
combination of configuration *and* vendored plugin versions — which
matters more here than in most configs, because the plugins live in the
repository rather than being resolved at install time.

Vendored plugin updates (`git subtree pull`, recorded in `plugins.lock`)
are not listed individually — see `git log -- pack/vendor/` for those.

## [Unreleased]

Nothing yet.

## [0.1.0] - 2026-08-13

First tagged release. Everything below was built and verified before this
tag; the entries are grouped by what a reader coming to the project fresh
would care about rather than by commit order.

### Added

- Initial configuration: a from-scratch Neovim setup built around four
  central registries (languages, tools, keymaps, commands) that drive LSP,
  formatting, linting, debugging, documentation and interactive discovery
  from a single source of truth each.
- 48 language specifications covering systems, web, JVM, .NET, functional,
  scripting, data/config and documentation languages.
- 92 tool entries (language servers, formatters, linters, debug adapters)
  with per-tool Mason package names and install profiles.
- Plugin vendoring via `git subtree --squash` (`scripts/plugins.tsv`,
  `plugins.lock`) with add/update/status scripts — no plugin manager and
  no downloads at startup.
- On-demand plugin loading through Neovim's native `pack/vendor/opt` +
  `packadd`, driven by `lua/config/lazyload.lua`.
- LSP via native `vim.lsp.config()`/`vim.lsp.enable()`, gated on the
  server binary actually being installed; no nvim-lspconfig, no
  mason-lspconfig.
- `extra_lsp` schema field, letting a language attach additional LSP
  clients alongside its primary one — first used to run Astral's `ty`
  next to basedpyright for Python.
- Debugging via nvim-dap with lazily registered adapters; nvim-dap-ui and
  nvim-nio load only once a session actually starts.
- nvim-tree.lua sidebar file explorer on `<leader>e`; oil.nvim
  buffer-as-directory editing on `<leader>o` and `-`.
- Tool profiles (`core`, `systems`, `python`, `scripting`, `web`, `jvm`,
  `dotnet`, `functional`, `devops`, `docs`, `all`) installable via
  `./scripts/bootstrap.sh <profile>` or `:ToolsInstall <profile>`.
- Discovery commands: `:NvimConfigHealth`, `:ToolsStatus`, `:LspStatus`,
  `:FormatterStatus`, `:LinterStatus`, `:DebuggerStatus`, `:NvimCommands`,
  `:NvimKeymaps`, `:NvimDocs`.
- Sphinx documentation site (MyST/Markdown, Read the Docs theme) plus a
  native `:help nvim-config`, both generated from the same registries.
- Headless test suite (`tests/run.sh`): clean-state and populated-state
  startup, lazy-load triggers, custom commands, a genuine
  missing-dependency test with `PATH` stripped to a sandbox, and the
  directory-argument behavior.
- Command-line completion (`cmp-cmdline`): `:` completes commands and their
  arguments through Neovim's own `getcompletion()`, so every command
  registered in the command registry is completed automatically; `/` and
  `?` complete buffer words.
- Git: gitsigns.nvim for the in-buffer layer (hunks, staging, blame) plus
  vim-fugitive, lazily loaded, for repository operations (`:Git`,
  `:Gvdiffsplit`, `<leader>g*`).
- Diagnostics: `virtual_lines` showing the full message for the diagnostic
  under the cursor, toggles for inline details (`<leader>xv`) and
  per-buffer diagnostics (`<leader>xt`).
- Format-on-save toggles `<leader>uf` (buffer) and `<leader>uF` (global),
  plus `:FormatStatus`, which reports whether it is active and why not.
- Telescope shows hidden files while still excluding `.git` internals.
- `./scripts/install.sh --backup`: moves an existing Neovim configuration
  to a timestamped directory instead of refusing. Without the flag an
  existing config is never touched.
- CI (GitHub Actions): stylua, the full test suite on Linux and macOS, the
  platform-independent tests on Windows, a strict Sphinx build, and a check
  that the generated documentation is not stale.
- MIT license for this repository's own code, with a generated inventory of
  the vendored plugins' own licenses (20 MIT, 6 Apache-2.0, 3 GPL-3.0).

### Fixed

- **Typing lag in large projects.** Inlay hints were auto-enabled on every
  LSP attach; Neovim's built-in inlay-hint module re-requests hints from
  every capable client on every `textDocument/didChange`, i.e. on every
  keystroke. This also produced clangd's `-32001: invalid AST` on large
  C++ translation units. Hints are opt-in via `<leader>ci` now.
- **Module namespace collision.** This config's own DAP module was named
  `dap`, shadowing the vendored nvim-dap plugin's `require("dap")` in
  Lua's module cache. Renamed to `debugger`.
- **LSP launch commands.** 14 servers need an explicit transport flag or
  subcommand (`--stdio`, `start`, `server`, `serve`, `lsp stdio`,
  `--languageserver`) and silently failed to start without one; found by
  actually installing and attaching them.
- **Mason package names.** `clang-tidy` and `chktex` have no standalone
  Mason package (they ship with LLVM and TeX Live respectively);
  cross-checked all 71 other package names against the live registry.
- **Stale executable cache.** `util.executable.reset()` was never called,
  so a tool installed mid-session via `:ToolsInstall` kept reporting as
  missing until restart. `:ToolsInstall`/`:ToolsUpdate` now install
  through the mason-registry API with a real completion callback.
- **Inert filetypes.** `dotenv` and `yaml.ansible` language specs never
  matched, because nothing set those filetypes; added `vim.filetype.add()`
  rules for both.
- **`nvim -l` async exit.** `scripts/bootstrap.lua` exited before Mason's
  asynchronous installs finished; it now blocks on a real `vim.wait()`.
- **Missing `packadd` calls** in three lazy-load paths (markdown, files,
  diagnostics), which crashed on the very first trigger.
- **lualine theme name** (`catppuccin-mocha`, not `catppuccin`), which
  silently fell back to `auto` and emitted a startup notice.
- **Python DAP adapter key** mismatch that would have broken debugging.
- **Duplicate clean-state test** in `tests/run.sh` that ran the same
  command as the exit-code check; replaced with a real populated-state
  test.

### Changed

- Documentation consolidated under `docs/`: the generated reference tables
  moved from the repository root to `docs/_generated/`, so there is no
  longer markdown in two places. They stay committed so Read the Docs can
  build without Neovim.
- Sphinx theme switched from `alabaster` to `sphinx-rtd-theme`.
- `nvim <directory>` changes the working directory but no longer opens the
  file tree automatically — the sidebar stays closed until requested.
- Diagnostic sign glyphs are written as `\u{...}` escapes rather than
  literal characters, after the literals were found to have been silently
  stripped to empty strings.

[Unreleased]: https://github.com/MichaelWeissDEV/nvim-config/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/MichaelWeissDEV/nvim-config/releases/tag/v0.1.0
