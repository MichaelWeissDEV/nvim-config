# nvim-config

Modulare Neovim-IDE mit vendorten Plugins, nativer LSP-Anbindung und optionalen
Sprachwerkzeugen. Kein Plugin-Download beim ersten Start erforderlich.

**[Vollständige Dokumentation](https://nvim-config.readthedocs.io/en/latest/)** ·
[Arch-Paket](https://nvim-config.readthedocs.io/en/latest/packages/) ·
[Keymaps](https://nvim-config.readthedocs.io/en/latest/keymaps/) ·
[Entwicklung](https://nvim-config.readthedocs.io/en/latest/development/)

```bash
curl -fsSL https://raw.githubusercontent.com/MichaelWeissDEV/dotfiles/main/install.sh | bash -s -- nvim
```

Paket: `arch-dotfiles-nvim`. Einstieg: `~/.config/nvim/init.lua`.
Das Handbuch beschreibt auch Standalone-Installation, Plattformen und optionale
LSP-/Formatter-/Debugger-Werkzeuge. Diagnose: `:NvimConfigHealth`.

Dieses Repository wird unabhängig gepflegt. Auf `main` pushen; nach erfolgreichem
Registry-Build mit `sudo pacman -Syu` aktualisieren. [PACKAGING.md](PACKAGING.md).

[![CI](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/ci.yml/badge.svg)](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/ci.yml)
[![Package safety](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/package.yml/badge.svg)](https://github.com/MichaelWeissDEV/nvim-config/actions/workflows/package.yml)

[MIT-Lizenz](LICENSE); vendorte Plugins behalten ihre jeweiligen Lizenzen.
