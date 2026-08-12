# Git

Two complementary layers, deliberately not one — see the comment at the
top of `lua/plugins/git.lua`:

**gitsigns.nvim** (`start`, always loaded) is the in-buffer layer: what
changed in *this file*. Sign-column glyphs, hunk navigation, staging and
resetting individual hunks, inline blame. Cheap enough to always load, and
useless if it isn't.

**vim-fugitive** (`opt`, loaded on first use) is the porcelain: operations
on *the repository*. `:Git status`, `:Git commit`, `:Git push`, three-way
diffs, `:Git log`, `:Git blame`. A whole Git UI, only worth loading the
moment you actually run a Git command.

Neither replaces the other.

## gitsigns keymaps

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

### Buffer-local, git-tracked buffers only

`on_attach` is gitsigns' own hook, called once per buffer *if and only if*
that buffer is inside a Git-tracked file — gitsigns decides this itself by
attempting to attach to the buffer's Git context. Every keymap above is
therefore buffer-local: in a file that isn't in a repository they simply
don't exist, rather than existing and failing.

## fugitive keymaps and commands

| Key | Runs |
|---|---|
| `<leader>gg` | `:Git` — the interactive status buffer |
| `<leader>gc` | `:Git commit` |
| `<leader>gp` | `:Git push` |
| `<leader>gP` | `:Git pull` |
| `<leader>gd` | `:Gvdiffsplit` — vertical diff against the index |
| `<leader>gl` | `:Git log --oneline --decorate --graph` |

`:Git <anything>` runs any Git subcommand; bare `:Git` opens the status
buffer, where `s`/`u` stage and unstage, `=` expands a diff inline, and
`cc` starts a commit. See `:help fugitive` once it's loaded for the full
surface — this config adds shortcuts to fugitive, it doesn't reconfigure
it.

### How it loads

Fugitive is a Vimscript plugin that defines its commands in `plugin/`, so
there is no `setup()` to call — `packadd` *is* the activation. Two
triggers, both in `lua/plugins/git.lua`:

- `lazyload.on_command` registers stubs for `:Git`, `:G`, `:Gdiffsplit`,
  `:Gvdiffsplit`, `:Gread`, `:Gwrite`, `:Gedit`, `:GBrowse`, `:Gclog` and
  `:Glgrep`, each of which loads the real plugin and re-dispatches.
- The `<leader>g*` keymaps above call `packadd` then run their command.

Those keymaps intentionally do **not** use `lazyload.on_key`: that helper
shares one once-guard per plugin name, so the first key pressed would load
fugitive and every *other* key would then hit the already-fired guard and
silently do nothing. `lazyload.packadd()` is itself idempotent, so calling
it on each press is both correct and cheap — the plugin still loads
exactly once, on first use.

## Telescope

`<leader>fG` lists Git-tracked files (with untracked files included), and
falls back to a plain file search outside a repository rather than
erroring. See {doc}`telescope`.

## Related

{doc}`architecture` for the `start`/`opt` split these two plugins sit on
either side of, {doc}`keymaps` for the full generated keymap table.
