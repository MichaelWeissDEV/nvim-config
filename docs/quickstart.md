# Quickstart

The first five minutes, assuming you've already followed {doc}`installation`.

## Open it

```bash
nvim
```

Nothing to wait for — every plugin is vendored, so there's no install step
on first launch. See {doc}`architecture` for why.

## Discover keys as you go

Press `<space>` (the leader key) and hold: which-key pops up a menu of
groups (`Find`, `Buffer`, `Window`, `Git`, `LSP / Format`, `Debug`, `Tools`,
`UI`, `Code`, `Diagnostics`, `Help / Docs`). Keep pressing to drill in — you
don't need to memorize anything up front. The full list is
{doc}`keymaps`; `:NvimKeymaps` shows it from inside Neovim, and
`<leader>fk` opens Telescope's own (built-in Neovim) keymap picker.

## Find and grep

- `<leader>ff` — find files by name.
- `<leader>fg` — live grep across the project.

Both work without `ripgrep`/`fd` installed: `find_files` falls back to
Neovim's own globbing, and `live_grep` falls back to a single prompted
`grep_string` search instead of live incremental grep — see
{doc}`telescope` for the exact fallback behavior.

## Once a language server is attached

Open a file in a language you have tooling for (e.g. `.rs` with
`rust-analyzer` installed), inside a project with the right root marker
present (e.g. a `Cargo.toml` above the file). Once the LSP client attaches,
these become live in that buffer:

- `gd` — go to definition
- `K` — hover documentation
- `<leader>lf` — format the buffer

See {doc}`lsp` for the full keymap table and how server attachment works,
and {doc}`formatting` for what `<leader>lf` does when no formatter is
installed.

## Check what's there

```
:NvimConfigHealth
```

Reports Neovim version, platform, which vendored plugins are present, and
which optional external tools (LSP servers, formatters, linters, debug
adapters) are installed vs. missing on this machine. Nothing here is an
error unless it's a real problem — see {doc}`troubleshooting` for how to
read the output.

## Where to go next

- {doc}`architecture` — how the pieces fit together
- {doc}`languages` — what's supported for your language
- {doc}`tools` — installing language servers/formatters/linters/debuggers
- {doc}`troubleshooting` — if anything looks off
