# nvim-config

A from-scratch, fully documented Neovim configuration for practically every
commonly used programming language — fast, quiet, modular, portable, and
built entirely from configuration you can read and understand. No
distribution (LazyVim, NvChad, AstroNvim, LunarVim, SpaceVim) is used
anywhere in this repository.

:::{note}
**Part of the Arch Dotfiles Ecosystem**: Built for **Arch Linux** as part of [`arch-dotfiles`](https://arch-dotfiles.readthedocs.io/en/latest/),
this Neovim configuration is designed to be completely modular and beginner-friendly, with every setting,
keymap, and custom command documented so that anyone can install it on Arch Linux
or run it standalone on any Linux distribution, macOS, or Windows.
:::

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
python
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

```{toctree}
:caption: Related documentation
:hidden:

Arch Dotfiles (main hub) <https://arch-dotfiles.readthedocs.io/en/latest/>
tmux (tmux-config) <https://tmux-config.readthedocs.io/en/latest/>
Ghostty (ghostty-config) <https://ghostty-config.readthedocs.io/en/latest/>
Kitty (kitty-config) <https://kitty-config.readthedocs.io/en/latest/>
Vim (vim-config) <https://vim-config.readthedocs.io/en/latest/>
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

## Connected Dotfiles Ecosystem

This Neovim setup is built to integrate seamlessly with the sibling configurations:

- **[Arch Dotfiles Hub (`arch-dotfiles`)](https://arch-dotfiles.readthedocs.io/en/latest/)**: Central repository uniting the Arch Linux + Hyprland desktop, window manager, and shell environments (managed via `adot update`, `adot update nvim`, `adot status`).
- **[tmux-config](https://tmux-config.readthedocs.io/en/latest/)**: Navigates panes seamlessly with Neovim splits using `Ctrl+h/j/k/l`.
- **[ghostty-config](https://ghostty-config.readthedocs.io/en/latest/)** & **[kitty-config](https://kitty-config.readthedocs.io/en/latest/)**: Fast GPU terminals matching the Catppuccin Mocha theme.
- **[vim-config](https://vim-config.readthedocs.io/en/latest/)**: Zero-dependency standalone Vim configuration mirroring Neovim's leader keys and navigation.
