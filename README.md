# nvim-config

[![CI](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/ci.yml/badge.svg)](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/ci.yml)
[![Docs](https://app.readthedocs.org/projects/nvim-config/badge/?version=latest)](https://nvim-config.readthedocs.io/en/latest/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<!-- The Docs badge stays "unknown" until the project is imported on
     readthedocs.org. The repo is already RTD-ready (.readthedocs.yaml +
     docs/requirements.txt); see CONTRIBUTING.md for the one-time import.
     If you pick a project slug other than "nvim-config", update both the
     badge and its link above to match. -->

A reproducible, offline-capable, fully documented Neovim development
environment built directly on native Neovim mechanisms. Behaves like a
small distribution — fast, quiet, modular, portable — while remaining 100%
readable, hand-written configuration. No LazyVim, NvChad, AstroNvim,
LunarVim or SpaceVim anywhere in this repository.

<!-- HERO SCREENSHOT
     Drop one image here and this section becomes the five-second pitch.
     Only you can take it -- it depends on your terminal, font and colours.

     Suggested single shot (one image, not ten): a real source file open
     (Rust or C++ reads well), Telescope or the nvim-tree sidebar visible,
     a completion popup up, and one diagnostic showing. Then:

       1. save it as docs/_static/screenshot.png
       2. replace this comment with:
          ![nvim-config](docs/_static/screenshot.png)
       3. add the same image to docs/index.md so it appears on the docs site
          (docs/conf.py currently has html_static_path = []; set it to
          ["_static"] once that directory exists)
-->

## Features

- **Offline by default.** Every plugin is vendored in-repo via `git
  subtree` (`pack/vendor/`) — cloning this repo is enough, no plugin
  manager, no download step. Language tooling (LSP/formatter/linter/
  debugger) is opt-in and installed explicitly; see [Offline Usage](#offline-usage).
- **Quiet by default.** A missing optional tool never produces a startup
  warning, error, or repeated notification — see `:NvimConfigHealth` /
  `:ToolsStatus` instead. Real configuration bugs stay loud.
- **Demand-driven.** Language servers only start for filetypes whose
  binary is installed; most plugins (Telescope, nvim-tree, Oil, Trouble,
  the debugger UI, markdown/LaTeX/CSV support) load on first actual use, not
  at startup. A plain `nvim` loads zero optional plugins.
- **One source of truth per concept.** A central language registry
  (`lua/languages/*.lua`) and tool registry (`lua/tools/registry.lua`)
  drive LSP setup, formatting, linting and debugging alike — no
  copy-pasted per-language configuration. Keymaps and commands are
  registered through two small registries that simultaneously power
  which-key, `:NvimKeymaps`/`:NvimCommands`, and the generated docs below.
- **Broad language coverage**, from systems languages (C/C++/Rust/Go/Zig/
  Assembly) through web (JS/TS/Vue/Svelte/HTML/CSS), JVM (Java/Kotlin),
  functional (Haskell/OCaml/Elixir/Erlang), scripting (Python/Ruby/Perl/
  PowerShell/Bash), data/config formats (JSON/YAML/TOML/XML/SQL/...), and
  documentation (Markdown/LaTeX/reStructuredText). Full matrix: [docs/_generated/languages.md](docs/_generated/languages.md).
- **Real debugging**, not just LSP — `nvim-dap` + `nvim-dap-ui`, lazily
  loaded, with a documented keymap set and per-language adapter config.
- **Cross-platform architecture**: macOS, Linux and Windows all go
  through the same `lua/util/platform.lua` facts and
  `lua/config/platform.lua` settings — no hardcoded paths anywhere.

## Requirements

- Neovim **0.12.0 or newer** — a hard requirement, not a preference: this
  config vendors nvim-treesitter's `main` branch, which itself requires
  0.12+. `./scripts/install.sh` refuses to continue on anything older.
- `git` (for cloning and for the plugin-vendoring scripts).
- Recommended, optional: `ripgrep`, `fd`, a [Nerd Font](https://www.nerdfonts.com/).

Nothing else is required for a working editor — see [Offline Usage](#offline-usage).

## Installation

```bash
git clone https://github.com/MichaelWeissDEV/nvim-config.git ~/.config/nvim
nvim
```

or, if you keep the repo elsewhere:

```bash
git clone https://github.com/MichaelWeissDEV/nvim-config.git ~/git/nvim-config
./scripts/install.sh          # symlinks ~/.config/nvim -> the repo, generates :help tags
```

(`scripts/install.ps1` on Windows.) Full details: [docs/installation.md](docs/installation.md).

## Quick Start

- `<space>` (leader) opens which-key's group popup.
- `<leader>ff` / `<leader>fg` — find files / live grep (Telescope, loads on first use).
- `<leader>e` — file explorer sidebar (nvim-tree, loads on first use); `<leader>o` / `-` for Oil's buffer-as-directory editing instead.
- `gd`, `K`, `<leader>lr`, `<leader>la` — LSP go-to-definition, hover, rename, code action (once a server has attached).
- `<leader>lf` — format the current buffer.
- `<leader>db` / `<leader>dc` — toggle breakpoint / start-or-continue debugging.
- `:NvimConfigHealth` — full report of what's vendored and what optional tooling is missing.
- `:NvimKeymaps` / `:NvimCommands` — this config's own keymaps/commands, grouped.
- `:NvimDocs` — open the local Sphinx docs (or `:help nvim-config` if not built yet).

## Bootstrap (installing language tooling)

Nothing above installs a single language server, formatter, linter or
debugger. Install a **profile** for what you actually use:

```bash
./scripts/bootstrap.sh core      # lua_ls, stylua, shellcheck, shfmt, bash-language-server, selene, taplo
./scripts/bootstrap.sh systems   # clangd, rust-analyzer, gopls, codelldb, delve, zls, asm-lsp, ...
./scripts/bootstrap.sh python    # basedpyright, ruff, debugpy
./scripts/bootstrap.sh web       # TS/JS/Vue/Svelte LSPs, eslint, prettier, js-debug-adapter
./scripts/bootstrap.sh all       # everything (slow, large download)
```

Full profile list and every tool each one installs:
[docs/_generated/tools.md](docs/_generated/tools.md). This
is also the only script (besides the equivalent in-editor
`:ToolsInstall`/`:ToolsUpdate`/`:Mason*`/`:TSInstall`) that touches the
network — see [Offline Usage](#offline-usage).

## Key Bindings — Quick Reference

| Key | Action |
|---|---|
| `<leader>ff` / `<leader>fg` / `<leader>fb` | Find files / live grep / buffers |
| `<leader>e` | File explorer sidebar (nvim-tree) |
| `<leader>o` / `-` | File explorer as a buffer (Oil) |
| `gd` / `gr` / `K` | LSP definition / references / hover |
| `<leader>lr` / `<leader>la` | LSP rename / code action |
| `<leader>lf` | Format buffer |
| `[d` / `]d` / `<leader>xx` | Prev/next diagnostic / diagnostics list (Trouble) |
| `<leader>db` / `<leader>dc` | Toggle breakpoint / start-continue debugging |
| `<leader>gb` / `]h` / `[h` | Git blame line / next-prev hunk |
| `<C-h/j/k/l>` | Move between windows |

Full table, generated from the config's own keymap registry:
[docs/_generated/keymaps.md](docs/_generated/keymaps.md).
Interactive: press `<space>` for which-key, or run `:NvimKeymaps`.

## Commands

Full generated list: [docs/_generated/commands.md](docs/_generated/commands.md),
or run `:NvimCommands` inside Neovim.

## Offline Usage

A normal session — editing, LSP, completion, formatting, linting,
debugging with whatever's already installed — never touches the network.
The only things that do, and only when run explicitly, are:
`./scripts/bootstrap.sh`/`.ps1`, `:ToolsInstall`/`:ToolsUpdate`, `:Mason*`,
`:TSInstall`/`:TSUpdate`, the `scripts/plugin-*.sh` vendoring scripts, and
the first run of `./scripts/docs-build.sh` (to fetch Sphinx). Full
explanation, including a caveat found during real testing (missing
`tree-sitter-cli`): [docs/offline.md](docs/offline.md).

## Documentation

This README is the entry point; everything else lives under `docs/`:

- **Local Sphinx docs** (architecture, per-subsystem pages, platform notes,
  troubleshooting, development guide): build with `./scripts/docs-build.sh`
  (`.ps1` on Windows), then open `docs/_build/html/index.html` or run
  `:NvimDocs` inside Neovim.
- **Native `:help nvim-config`** — a fast, always-available subset,
  generated (like the files below) from the same registries the config
  itself reads.
- **[docs/_generated/](docs/_generated/)** — the reference tables
  (keymaps, commands, plugins, tools, languages) generated by
  `scripts/generate-docs.lua` from the config's own registries, so these
  can't drift from what's actually configured. They render as plain
  Markdown on GitHub and are `{include}`'d by the Sphinx pages above, so
  there is exactly one copy of each table. Regenerate with
  `./scripts/docs-build.sh` (which also refreshes the Sphinx site and
  `:help` tags) after changing a language/tool/keymap/command.

## Plugin Updates

All plugins are vendored via `git subtree --squash`. Manifest:
`scripts/plugins.tsv`; pinned commits: `plugins.lock`.

```bash
./scripts/plugin-status.sh         # what's vendored, start vs. opt
./scripts/plugin-add.sh <name>     # vendor a new plugin from the manifest
./scripts/plugin-update.sh <name>  # update one plugin
./scripts/plugin-update-all.sh     # update everything that's already vendored
```

Details: [docs/plugin-updates.md](docs/plugin-updates.md).

## Supported Languages

Lua, Python, Ruby, Go, Rust, C, C++, Java, Kotlin, Bash, Fish, PowerShell,
Assembly, JavaScript, TypeScript, HTML, CSS/SCSS/Sass/Less, Vue, Svelte,
JSON, YAML, TOML, XML, SQL, CSV/TSV, dotenv, INI, Dockerfile, Terraform,
Nix, Ansible, Markdown, reStructuredText, LaTeX, AsciiDoc, C#, F#,
Haskell, OCaml, Elixir, Erlang, PHP, Perl, Zig, CMake, Make, GraphQL,
Protobuf. Full matrix with LSP/formatter/linter/debugger/Tree-sitter per
language: [docs/_generated/languages.md](docs/_generated/languages.md).

## Supported Platforms

| Platform | Status |
|---|---|
| macOS | Primary development platform — real, interactive daily use |
| Linux | Full headless test suite runs on every push (`ubuntu-latest`) |
| Windows | Platform-independent tests run on every push (`windows-latest`); the POSIX-only missing-dependency sandbox test is skipped there |

See [docs/platform.md](docs/platform.md) for exactly what differs per OS.

## Troubleshooting

Start with `:NvimConfigHealth`. Common issues and their fixes:
[docs/troubleshooting.md](docs/troubleshooting.md).

## Contributing / Development

Adding a language, tool, keymap or command; code style; how the
registries fit together: [docs/development.md](docs/development.md) and
[docs/architecture.md](docs/architecture.md).
