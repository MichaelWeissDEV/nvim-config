# Git

`lua/plugins/git.lua` configures gitsigns.nvim: sign column glyphs for
add/change/delete/topdelete/changedelete, and a set of hunk-navigation and
staging keymaps.

## Keymaps

Group `Git`, all defined inside gitsigns' `on_attach` callback:

| Key | Action |
|---|---|
| `]h` | Next git hunk |
| `[h` | Previous git hunk |
| `<leader>ghs` | Stage hunk |
| `<leader>ghr` | Reset hunk |
| `<leader>ghp` | Preview hunk |
| `<leader>gb` | Blame line |
| `<leader>gB` | Toggle current-line blame virtual text |

## Buffer-local, git-tracked buffers only

`on_attach` is gitsigns' own hook, called once per buffer *if and only if*
that buffer is inside a Git-tracked file — gitsigns decides this itself by
attempting to attach to the buffer's Git context. Every keymap above is
registered with `buffer = bufnr` inside that callback, so they exist only
in buffers where they're meaningful; a scratch buffer or a file outside any
Git repository never gets them.

`:Gitsigns <subcommand>` is also available for anything not bound to a
key — it's gitsigns' own command, listed in {doc}`commands` as external
rather than redefined by this config.
