# The user interface

Everything on this page comes from three small files: `lua/config/options.lua`
(Neovim's own options), `lua/plugins/theme.lua` and
`lua/plugins/statusline.lua` (the two plugins that change how the editor
looks), plus `lua/plugins/whichkey.lua` for the keymap popup. There is no
"UI framework" layer in between — every setting below is a plain
`vim.opt.*` assignment or a plugin's `setup()` table you can read in under
a minute.

## What the editor looks like out of the box

**Colour scheme: [catppuccin](https://github.com/catppuccin/nvim), flavour
`mocha`** (`plugins/theme.lua`). It is vendored under
`pack/vendor/start/`, so it applies at startup with no download and no
flash of the default colours. Its integrations are enabled explicitly —
`cmp`, `gitsigns`, `telescope`, `treesitter`, `which_key`, `mason`, `dap`,
`dap_ui` and `native_lsp` — rather than left on "auto", so a plugin that
gets added later does not silently start theming itself differently.

**Statusline: [lualine](https://github.com/nvim-lualine/lualine.nvim)**
(`plugins/statusline.lua`), with `globalstatus = true`. Combined with
`opt.laststatus = 3` that means **one** statusline for the whole editor
rather than one per split — splits stay visually quiet, and the line
never jumps as you change window layout. Its right-hand section shows
diagnostics, file encoding and filetype; the centre shows the filename
with one level of parent directory (`path = 1`), which is enough to tell
`src/main.rs` from `tests/main.rs` without printing the whole path.

```{note}
lualine's theme is set to `"catppuccin-mocha"`, not `"catppuccin"`. The
short name does not error — lualine silently falls back to `auto` and
emits a one-time `:LualineNotices` warning. If you change the flavour in
`plugins/theme.lua`, change it here too.
```

**Keymap popup: [which-key](https://github.com/folke/which-key.nvim)**
(`plugins/whichkey.lua`). Press `<leader>` (Space) and wait — the popup
lists what is available. which-key is *purely presentational* here: it
never defines a mapping, it only names the leader groups:

| Prefix | Group |
| --- | --- |
| `<leader>f` | Find |
| `<leader>b` | Buffer |
| `<leader>w` | Window |
| `<leader>g` / `<leader>gh` | Git / Git Hunk |
| `<leader>l` | LSP / Format |
| `<leader>d` | Debug |
| `<leader>t` | Tools |
| `<leader>u` | UI |
| `<leader>c` | Code |
| `<leader>x` | Diagnostics |
| `<leader>h` | Help / Docs |

Every entry inside those groups comes from `util.keymap_registry` — the
same source as {doc}`keymaps` and `:NvimKeymaps`. Adding a keymap through
the registry makes it appear in the popup and in the documentation at
once; see {doc}`development`.

## The display options that actually matter

From `lua/config/options.lua`:

| Option | Value | Why |
| --- | --- | --- |
| `number` + `relativenumber` | both on | absolute number on the cursor line, relative elsewhere — `5j` without counting |
| `cursorline` | on | the cursor stays findable in a large window |
| `signcolumn` | `"yes"` | always reserved, so diagnostics and Git signs never shift the text sideways as they appear |
| `scrolloff` / `sidescrolloff` | `8` | never edit on the very last visible line |
| `laststatus` | `3` | one global statusline (see lualine above) |
| `winborder` | `"rounded"` | Neovim ≥ 0.11 applies this to *all* floating windows — hover, signature help, diagnostics floats — without every plugin needing its own border setting |
| `list` + `listchars` | `» `, `·`, `␣` | tabs, trailing whitespace and non-breaking spaces are visible rather than invisible bugs |
| `wrap` | off | long lines scroll instead of reflowing; toggle per window with `<leader>uw` |
| `pumheight` | `12` | the completion popup cannot swallow the screen |
| `splitbelow` / `splitright` | on | new splits appear where the eye already is |
| `inccommand` | `"split"` | `:%s/…` previews its own result live in a split |
| `termguicolors` | on | 24-bit colour, required by catppuccin |

`signcolumn = "yes"` is the one people most often turn off and then regret:
with `"auto"` the whole buffer jumps one column to the right the instant a
linter reports something, which is far more distracting than an empty
column.

## Toggling things at runtime

All registered in `lua/config/keymaps.lua` under the `UI` group, so they
are also listed by `:NvimKeymaps`:

| Keymap | Effect |
| --- | --- |
| `<leader>un` | relative ↔ absolute line numbers (current window) |
| `<leader>uN` | line numbers on/off entirely |
| `<leader>uw` | line wrap on/off |
| `<leader>ul` | whitespace display (`list`) on/off |
| `<leader>uf` / `<leader>uF` | format on save, buffer / global — see {doc}`formatting` |

There is one command in the same family, `:RelativeNumbersToggle`, doing
what `<leader>un` does — useful when you want it from a script or a
`:normal` sequence.

These are all window-local (`vim.wo`), deliberately: toggling wrap to read
one long log line should not reformat every other split.

## Icons and the Nerd Font question

Icons come from
[nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) and are
used by lualine, nvim-tree ({doc}`files`), Telescope ({doc}`telescope`) and
which-key. They need a [Nerd Font](https://www.nerdfonts.com/) in your
**terminal**, not in Neovim — Neovim only prints the codepoints. Without
one you get replacement boxes; nothing breaks, it just looks wrong.

The diagnostic sign glyphs in `lua/config/diagnostics.lua` are written as
`\u{f057}`-style escapes rather than pasted literal characters, because
literal Nerd Font glyphs have a habit of being silently stripped by
editors and tooling in transit — they were empty strings in that file for
a while, which is exactly the failure that escaping avoids. The virtual
text prefix (`●`, `U+25CF`) is plain Unicode on purpose and renders in any
font.

## Large files turn the UI down on their own

`lua/config/large_files.lua` watches `BufReadPre` and, for files over
**5 MiB** or with any sampled line longer than **20 000 characters**,
disables Tree-sitter highlighting, diagnostics, spell check, folds, swap
and undo files for that buffer and detaches any LSP client. A 200 MB log
opens at normal speed instead of freezing the editor. The buffer gets
`b:large_file = true`, so you can check whether that is what happened:

```vim
:lua = vim.b.large_file
```

Only the sampled first, middle and last line lengths are measured —
scanning the entire buffer to decide whether the buffer is too big to scan
would defeat the purpose.

## Changing the look

Change the flavour, or the whole colour scheme, in
`lua/plugins/theme.lua` — and lualine's `theme` in
`lua/plugins/statusline.lua` alongside it. To use a colour scheme that is
not vendored yet, add it as a `start` plugin the normal way
({doc}`plugin-updates`) and swap the `vim.cmd.colorscheme()` call. Nothing
else in the configuration reads the theme name, so that is the entire
change.
