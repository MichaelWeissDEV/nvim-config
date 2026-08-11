# Keymaps

Every keymap in this config is registered through `util.keymap_registry`
(see {doc}`architecture`), which is what makes the three ways of
discovering them below guaranteed to agree:

- Press `<space>` and wait — which-key shows the groups and mappings live.
- `<leader>fk` — Telescope's own picker over *all* of Neovim's keymaps
  (builtin and this config's), not just this config's registry.
- `:NvimKeymaps` — this config's own registered keymaps only, grouped by
  category, in a scratch buffer.

The table below is generated from the same registry by
`scripts/generate-docs.lua` and is identical to what `:NvimKeymaps` shows.

```{include} ../KEYMAPS.md
:start-line: 3
```
