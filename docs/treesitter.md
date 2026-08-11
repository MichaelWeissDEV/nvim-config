# Tree-sitter

## `main` branch, not `master`

`scripts/plugins.tsv` vendors nvim-treesitter from its `main` branch. This
matters: nvim-treesitter's own upstream README states the `main` branch
requires Neovim 0.12+ (the `master` branch is the legacy, Neovim
0.9-compatible line) — consistent with this config's own recommendation to
run 0.12+ (see {doc}`installation`).

## Always loaded, no parsers bundled

nvim-treesitter's README is explicit that it does not support
lazy-loading, which is why it lives in `pack/vendor/start/` rather than
`opt/` (see {doc}`architecture`) and its `setup({})` always runs.

That's the only thing that's automatic. No parser beyond Neovim's own
built-ins (`c`, `lua`, `markdown`, `markdown_inline`, `query`, `vim`,
`vimdoc`) is bundled or auto-installed. `plugins/treesitter.lua` registers
one `FileType` autocommand that runs:

```lua
pcall(vim.treesitter.start, args.buf)
```

for every buffer, unconditionally. If a parser for that filetype isn't
installed, `vim.treesitter.start` errors and the `pcall` just swallows
it — no error surfaces to the user, the buffer simply has no Tree-sitter
highlighting. There's no per-filetype branching or allowlist here; it's
the same generic call for every filetype, which is what makes "no error
for a missing parser" true by construction rather than by a maintained
list.

## Installing a parser

`:TSInstall <language>` / `:TSUpdate` are the explicit opt-in — the one
deliberate exception to "no network at runtime" in this whole config (see
{doc}`offline`). `./scripts/bootstrap.sh <profile>` installs a default
parser set per profile at the same time it installs that profile's Mason
tools.

Parser compilation depends on the external `tree-sitter` CLI and a C
compiler, neither of which ships with Neovim — see {doc}`offline` for the
exact failure mode and install commands if `tree-sitter-cli` is missing;
it's not repeated here.
