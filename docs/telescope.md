# Telescope

## Lazy-load, direct dispatch

telescope.nvim is an `opt` package (see {doc}`architecture`). Each
`<leader>f*` mapping is registered once, normally, through
`util.keymap_registry` — its `rhs` is a small function that calls a local
`ensure()` (idempotent: `packadd`s the plugin and calls `setup()` only the
first time, guarded by a `ready` flag) and then invokes the specific
Telescope builtin it wants.

This is simpler than the generic `config.lazyload.on_key()` helper used
elsewhere (e.g. `plugins/files.lua` for oil.nvim, `plugins/diagnostics.lua`
for trouble.nvim): `on_key` has to register a stub keymap, delete it on
first press, then set the real one, because it doesn't know in advance
which action the caller wants. Telescope's keymaps already know exactly
which picker they want, so there's no stub to swap out — `ensure()` being
safe to call on every press (not just the first) is what makes the
straight-through function work.

## Keymaps

Group `Find`:

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fk` | Keymaps (all of Neovim's, not just this config's) |
| `<leader>fc` | Commands (all of Neovim's) |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | Document symbols |
| `<leader>fG` | Git files |

`:Telescope <picker>` opens any picker by name directly.

## Graceful degradation without `rg`/`fd`

Telescope's `setup()` sets no explicit finder command, so with neither `rg`
nor `fd` on `PATH` it falls back to its own `vim.fn.glob`-based finder —
slower, not an error (see the comment in `plugins/telescope.lua`). Two
pickers go further and change behavior outright, each backed by an actual
`pcall`/existence check rather than just hoping the fallback is good
enough:

- **`live_grep`** (`<leader>fg`): if `rg` isn't found via
  `util.executable.exists`, a one-shot notification fires
  (`"Telescope live_grep needs ripgrep ('rg'); falling back to
  grep_string."`) and it runs `grep_string` with a manually prompted search
  term instead of `live_grep`.
- **`git_files`** (`<leader>fG`): if the current directory isn't inside a
  Git repository, `telescope.builtin.git_files` errors and is caught with
  `pcall`; a one-shot info notification (`"Not inside a git repository;
  showing all files instead."`) fires and it falls back to `find_files`.

## Related

{doc}`installation` for the recommended `rg`/`fd` install commands,
{doc}`troubleshooting` for what `:checkhealth nvim-config` reports about
them.
