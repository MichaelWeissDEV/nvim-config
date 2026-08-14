# nvim-config

A from-scratch, fully documented Neovim configuration for practically every
commonly used programming language — fast, quiet, modular, portable, and
built entirely from configuration you can read and understand. No
distribution (LazyVim, NvChad, AstroNvim, LunarVim, SpaceVim) is used
anywhere in this repository.

Start here if you're new:

- {doc}`installation` — clone, first launch, what to expect
- {doc}`quickstart` — the first five minutes
- {doc}`architecture` — how the pieces fit together and why

Then dig into whichever part you need:

```{toctree}
:maxdepth: 1
:caption: Getting started

installation
quickstart
architecture
platform
offline
```

```{toctree}
:maxdepth: 1
:caption: Reference

keymaps
commands
plugins
languages
tools
```

```{toctree}
:maxdepth: 1
:caption: Subsystems

lsp
completion
formatting
linting
diagnostics
debugging
git
files
telescope
treesitter
mason
ui
```

```{toctree}
:maxdepth: 1
:caption: Maintaining this config

plugin-updates
troubleshooting
faq
development
changelog
license
```

## The five-second version

```bash
git clone https://github.com/MichaelWeissDEV/nvim-config.git ~/.config/nvim
nvim
```

That's it — no download step, no `:PluginInstall`, no first-run setup
wizard. Every plugin is already vendored in `pack/vendor/`. Optional
external tools (language servers, formatters, linters, debuggers) are
detected, never assumed; run `:NvimConfigHealth` any time to see what's
present on your machine and `./scripts/bootstrap.sh <profile>` to install
what's missing.
