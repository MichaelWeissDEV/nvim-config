# Arch package and automatic updates

```bash
curl -fsSL https://raw.githubusercontent.com/MichaelWeissDEV/dotfiles/main/install.sh | bash -s -- nvim
```

This installs `arch-dotfiles-nvim`, Neovim and declared dependencies, backs up
existing settings, and activates editable user copies under `~/.config/nvim`.
Do not edit root-owned defaults under `/usr` or mix package activation with a Git
checkout in the same configuration path. Optional language tools remain opt-in.

Update with `sudo pacman -Syu`; the installed user timer synchronizes defaults,
or run `adot sync` immediately. Personal edits survive; merge `.pacnew` defaults
and reload the application. Develop in a separate checkout and push to `main`.
The registry checks sources every five minutes and publishes after passing tests;
GitHub may delay scheduled runs.

Removal: `arch-dotfiles-config deactivate nvim`, then
`sudo pacman -Rns arch-dotfiles-nvim`. Remove a dependent overall metapackage
first. Backups and edited user copies are retained.

[Complete installation and migration guide](https://arch-dotfiles.readthedocs.io/en/latest/arch-package/) ·
[Safety and verification](https://arch-dotfiles.readthedocs.io/en/latest/verification/).
For a separate standalone setup, see {doc}`installation`.
