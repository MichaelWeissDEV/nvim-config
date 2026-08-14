# Diagnostics

Diagnostics are the squiggles, signs and messages describing what is wrong
with the code in a buffer. In Neovim they are a **core feature**
(`vim.diagnostic`), not an LSP feature: a language server is one possible
producer, `nvim-lint` ({doc}`linting`) is another, and everything on this
page works identically whichever of them produced the entry — including in
a buffer with no language server attached at all.

All of it is configured in one file, `lua/config/diagnostics.lua`, which is
loaded at startup before any plugin.

## How diagnostics are presented

`vim.diagnostic.config()` is called once, with these decisions:

**`severity_sort = true`** — when several diagnostics share a line, the
most severe one wins the sign column and the virtual text. Without this you
get whichever arrived first, which is effectively random.

**`underline = true`** — the offending range is underlined in the buffer.

**`update_in_insert = false`** — diagnostics are *not* re-rendered while
you type. This is the single most important setting on this page for
perceived speed: re-laying-out virtual text on every keystroke is the same
class of problem that made inlay hints feel laggy (see {doc}`lsp`). You get
the update as soon as you leave insert mode.

**`virtual_text`** — a short message at the end of the line, prefixed with
`●` (`U+25CF`, plain Unicode — no Nerd Font needed), two columns of
spacing, and `source = "if_many"`: the producing tool's name is appended
only when more than one tool reports on that buffer, so a single-linter
buffer stays uncluttered while a `ruff` + `basedpyright` buffer tells you
which one is complaining.

**`virtual_lines = { current_line = true }`** — the *full*, multi-line
message, rendered below the cursor's line only. Plain `virtual_lines = true`
would expand every diagnostic in the buffer and push the code around as you
move; restricting it to the current line gives you the complete text of long
type errors (the kind Rust and TypeScript produce) without the buffer
dancing. Toggle it with `<leader>xv`.

**`signs`** — Nerd Font glyphs in the sign column, one per severity:

| Severity | Glyph | Codepoint |
| --- | --- | --- |
| ERROR | times-circle | `\u{f057}` |
| WARN | exclamation-triangle | `\u{f071}` |
| HINT | lightbulb | `\u{f0eb}` |
| INFO | info-circle | `\u{f05a}` |

They are written as `\u{…}` escapes in the source rather than pasted
literal characters, because literal glyphs get silently stripped by some
editors and tooling in transit — they were empty strings in that file for a
while, which is exactly the failure the escapes prevent. Without a Nerd
Font installed they render as boxes; see {doc}`ui`.

**`float`** — the popup opened by `<leader>xl` (and automatically by the
jump keymaps) uses a rounded border, prints the producing tool via
`source = true`, and drops the default header and per-entry prefix, which
in a single-diagnostic popup are pure noise.

## Keymaps

All registered under the `Diagnostics` group, so `:NvimKeymaps` and the
`<leader>x` which-key popup list them too:

| Keymap | Effect |
| --- | --- |
| `[d` | previous diagnostic, and open its float |
| `]d` | next diagnostic, and open its float |
| `<leader>xl` | show the float for the current line |
| `<leader>xq` | send all diagnostics to the quickfix list and open it |
| `<leader>xv` | toggle inline detail (`virtual_lines`) on/off |
| `<leader>xt` | toggle diagnostics in **this buffer** on/off |
| `<leader>xx` | toggle the Trouble list (loads trouble.nvim on first press) |

`[d` / `]d` use `vim.diagnostic.jump({ count = ±1, float = true })` — the
modern API; the old `goto_prev`/`goto_next` functions are deprecated in
Neovim 0.11+ and removed in 0.12, which is one of the reasons this config
requires 0.12.0 (see {doc}`installation`).

`<leader>xv` and `<leader>xt` both print what they just did
(`"Inline diagnostic details: off"`, `"Diagnostics in this buffer: on"`) —
a toggle whose only feedback is the absence of something is a toggle you
lose track of.

## Trouble: the list view

[trouble.nvim](https://github.com/folke/trouble.nvim) gives a proper
navigable list of every diagnostic in the workspace, grouped by file. It
lives in `pack/vendor/opt/` and loads on the **first press of
`<leader>xx`** or the first `:Trouble` command — a session in which you
never open the list never loads it. See {doc}`plugins` for how that lazy
loading works.

`vim.diagnostic.*` is fully functional without it: `<leader>xq` puts the
same information into the standard quickfix list, which needs no plugin at
all. Trouble is a nicer view of data Neovim already has, not the source of
that data.

Telescope has its own diagnostics picker on `<leader>fd` when you want to
*search* diagnostics rather than walk them — see {doc}`telescope`.

## Where diagnostics come from

Three independent producers, each documented on its own page:

- **Language servers** — semantic errors, type errors, unresolved imports.
  Arrive automatically once a server attaches; see {doc}`lsp`.
- **Linters** via `nvim-lint` — style and correctness checks a language
  server does not do (`ruff`, `shellcheck`, `eslint`, …). Re-checked live
  on every trigger, so a linter installed mid-session works without a
  restart; see {doc}`linting`.
- **Tree-sitter** — syntax errors for languages whose parser is installed;
  see {doc}`treesitter`.

If a buffer shows no diagnostics at all and you expected some, the question
is almost always which of those three is missing, not how diagnostics are
configured. `:LspStatus` and `:LinterStatus` answer it directly, and
{doc}`troubleshooting` walks through the whole chain.

## When diagnostics are switched off on purpose

Two cases, both deliberate and both worth recognising before you go
looking for a bug:

1. **Large files.** `lua/config/large_files.lua` disables diagnostics
   (along with Tree-sitter highlighting and any LSP client) for buffers
   over 5 MiB or with extremely long lines. Check with
   `:lua = vim.b.large_file` — see {doc}`ui`.
2. **You pressed `<leader>xt`.** It is buffer-local and survives until you
   press it again or reopen the buffer.
