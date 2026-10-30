# Arch package

Package: `arch-dotfiles-nvim`. The recipe is in `packaging/arch/PKGBUILD`.
Edit this repository and push to `main`. The central registry checks main branches
every five minutes and publishes automatically versioned, signed packages after
a successful build. GitHub may delay scheduled runs.

Installation: https://github.com/MichaelWeissDEV/dotfiles#installation

With sibling checkouts, build using:
`bash ../dotfiles/packaging/arch/build.sh arch-dotfiles-nvim`.
To request an immediate registry build: `gh workflow run packages.yml -R MichaelWeissDEV/dotfiles`.
