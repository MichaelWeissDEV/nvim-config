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
groups (`Find`, `Buffer`, `Window`, `Git`, `LSP / Format`, `Debug`,
`Tools / Terminal`, `UI`, `Code`, `Diagnostics`, `Quit`, `Help / Docs`). Keep pressing to drill in — you
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

## Set up a language

Open a file and press `<leader>tl` (`:LangInstall`). This installs the
language server, formatter, linter, debugger and Tree-sitter parser for
that language through Mason, in the background. When it finishes, the
server attaches to the open buffer; no restart is needed.
`<leader>ti` (`:LangInfo`) shows what the language uses and what is
missing. Python has its own page: {doc}`python`.

## Once a language server is attached

These keys become live in that buffer (the statusline shows which servers
are attached):

- `gd` / `gy` — go to definition / type definition; `<C-o>` jumps back
- `gr` / `gi` — references / implementations (picker)
- `K` — hover documentation
- `<leader>lr` — rename, `<leader>la` — code action
- `<leader>ls` / `<leader>lS` — document / workspace symbols
- `<leader>lf` — format the buffer (also runs on save)
- `]d` / `[d` — next / previous diagnostic, `<leader>xx` — all of them

See {doc}`lsp` for the full keymap table and how server attachment works,
and {doc}`formatting` for what `<leader>lf` does when no formatter is
installed.

## Everyday keys

- `<C-s>` — save; `<leader>qq` — quit (asks about unsaved changes)
- `<C-/>` or `<leader>tt` — toggle a terminal at the bottom
- `<leader>cr` — run the current file; in Python `<leader>ct` / `<leader>cT`
  run pytest for the file / the test under the cursor
- `<leader><space>` — find files, `<leader>/` — search in the buffer,
  `<leader>fw` — grep the word under the cursor
- `<leader>um` — render markdown (off by default: markdown is shown as
  plain text)

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
