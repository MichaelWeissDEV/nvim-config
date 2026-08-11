# Completion

## The stack

`lua/plugins/completion.lua` wires up nvim-cmp with four sources, in two
priority groups:

1. `nvim_lsp` — completions from whatever LSP client is attached
   (see {doc}`lsp`)
2. `luasnip` — snippet expansion, loaded from `friendly-snippets` via
   `luasnip.loaders.from_vscode`'s `lazy_load()`
3. `buffer` — words from the current buffer (`keyword_length = 3`)
4. `path` — filesystem paths

Groups 1–2 are tried before 3–4, so LSP/snippet matches rank above
buffer/path matches rather than being interleaved.

## Keymaps (insert mode)

| Key | Action |
|---|---|
| `<Tab>` | Next completion item if the menu is visible; otherwise expand/jump a snippet if one is expandable; otherwise fall through to normal `<Tab>` |
| `<S-Tab>` | Same, in reverse (previous item / jump back / fallback) |
| `<CR>` | Confirm the selected item (`select = false` — only confirms an item you actually selected, doesn't auto-pick the first one) |
| `<C-space>` | Manually trigger completion |
| `<C-e>` | Abort/close the completion menu |

## Why nvim-cmp, not blink.cmp

Documented directly in the file: blink.cmp's fuzzy matcher downloads a
prebuilt Rust binary (or needs a Rust toolchain to build one) on first use,
unless its `fuzzy.implementation` is forced to `"lua"` — which gives up its
main performance advantage anyway. For a config whose first requirement is
"no downloads, ever, unless explicit" (see {doc}`offline`), nvim-cmp
vendored as plain Lua is the defensible choice even though blink.cmp is
newer.

## Loading

nvim-cmp and its sources are `pack/vendor/start/` plugins — always loaded,
since insert-mode completion is needed immediately in any buffer. See
{doc}`architecture` for the full start/opt split.
