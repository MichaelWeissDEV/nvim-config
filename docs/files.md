# File Navigation

Two file explorers ship here, and that is deliberate. They are not
redundant — they answer different questions, and neither is loaded until
you ask for one.

## Netrw is disabled first, unconditionally

`lua/config/options.lua` sets:

```lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
```

at startup, not from either explorer's setup code. The comment there gives
the reason: both replacements are `opt` packages loaded on demand, so if
netrw were only disabled when one of them happened to load, `nvim
<a-directory>` could briefly flash netrw's raw listing before the
lazy-loaded plugin caught up. Disabling it up front removes that window
entirely.

## nvim-tree: the sidebar (`<leader>e`)

`lua/plugins/tree.lua`. The whole `setup()` call is five options:

| Option | Value | Why |
|---|---|---|
| `view.width` / `view.side` | `32`, `"left"` | Fixed-width left sidebar |
| `renderer.group_empty` | `true` | Collapses chains of single-child directories into one row |
| `filters.dotfiles` | `false` | Dotfiles are *shown* (`filters.dotfiles = true` would hide them) |
| `filters.git_ignored` | `false` | Git-ignored files are shown too |
| `git.enable` | `true` | Git status decoration in the tree |
| `update_focused_file.enable` | `true` | Tree follows the buffer you're actually editing |

The `update_focused_file` comment states the intent directly: keep the tree
in sync with the actual editing buffer instead of a separate, driftable
file list.

`<leader>e` calls `nvim-tree.api`'s `tree.toggle({ find_file = true, focus
= true })` — so toggling it open also reveals and focuses the current
file, rather than dropping you at the project root.

Commands: `:NvimTreeToggle` and `:NvimTreeFindFile` (open the tree and
reveal the current buffer's file). Both also work as load triggers.

## oil.nvim: the directory as a buffer (`<leader>o`, `-`)

`lua/plugins/files.lua`. Oil renders a directory as an ordinary,
editable buffer: you rename, delete and create entries by *editing the
text* and then `:w`. Two options are set — `default_file_explorer = true`
and `view_options.show_hidden = true`.

Two keys open it: `<leader>o`, and `-` for the classic Oil convention of
opening the parent directory of the current file. `:Oil` does the same and
is also a load trigger.

## Why both

A sidebar answers "where am I in this project, and what else is nearby" —
persistent, glanceable, git-decorated, following your current buffer. A
buffer-as-directory answers "restructure this directory" — bulk rename and
delete with the editing motions and macros you already know, reviewed as a
diff before you `:w`. Neither tool does the other's job well, and since
both are `opt` packages (see {doc}`architecture`), carrying both costs
nothing until you press a key.

## The shared once-guard in `files.lua`

`<leader>o` and `-` both register through `lazyload.on_key(...)` with the
*same* once-guard name, `"oil.nvim"`, and both point at the same
`first_use` function — which loads Oil, rebinds **both** keys to the real
`open` action, and then opens Oil.

Rebinding both is what makes the second key work at all. `lazyload.on_key`
deletes its own stub mapping before calling the guarded function
(`pcall(vim.keymap.del, ...)` in `lua/config/lazyload.lua`), and the guard
only ever fires once per name. So if `first_use` rebound only the key you
happened to press first, then pressing the *other* key later would delete
its stub, hit the already-fired guard, do nothing, and leave that key
unmapped for the rest of the session.

nvim-tree's `<leader>e` uses the same `on_key` mechanism with its own
separate guard name (`"nvim-tree.lua"`) — it has only one trigger key, so
it rebinds only that one.

## `nvim <directory>` does not open the tree

The `VimEnter` autocommand in `plugins/tree.lua` (augroup `cd_to_dir_arg`,
`once = true`) checks for exactly one startup argument, and `cd`s into it
if it's a directory. That's all it does — same as Neovim's own default
behavior for a directory argument.

It deliberately does **not** open the sidebar. The comment in the file is
explicit that an earlier version auto-opened the tree here and it was
removed by request, so that a plain `nvim .` never shows a sidebar you
didn't ask for — matching this config's "nothing visible until you ask"
rule for every other `opt` plugin. `tests/test_directory_arg.lua` covers
this.

## Related

{doc}`architecture` for the `start`/`opt` split and what triggers each
lazy-loaded plugin, {doc}`keymaps` for the full generated keymap table,
{doc}`telescope` for finding files by name rather than by browsing.
