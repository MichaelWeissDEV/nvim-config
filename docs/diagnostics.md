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
buffer stays uncluttered while a `ruff` + `ty` buffer tells you which one
is complaining.

**`virtual_lines = false`** — **off by default**, and it is the one setting
here worth understanding, because it is the only one that changes the
*layout* of the buffer. With it on, the full multi-line message is rendered
as extra screen lines beneath the code, so the file visibly reflows as the
cursor moves: the line you are reading is pushed down, then springs back
when you move away. On a file with several diagnostics that is constant
motion for information you did not ask for.

Nothing is lost by having it off. The underline, the sign and the
end-of-line virtual text all still mark the problem exactly where it is,
without moving a single character. The full text is one keypress away in a
floating window (`<leader>xl`, below), and `<leader>xv` switches the inline
form back on for as long as a particular buffer warrants it.

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
| `<leader>xv` | toggle inline detail (`virtual_lines`) — off by default |
| `<leader>xt` | toggle diagnostics in **this buffer** on/off |
| `<leader>xx` | toggle the Trouble list, all buffers (loads trouble.nvim on first press) |
| `<leader>xX` | Trouble list for **this buffer** only |
| `<leader>xs` | symbols outline (Trouble) |
| `<leader>xr` | LSP definitions/references for the symbol under the cursor (Trouble, right side) |
| `<leader>xQ` | the quickfix list in Trouble |

`[d` / `]d` use `vim.diagnostic.jump({ count = ±1, float = true })` — the
modern API; the old `goto_prev`/`goto_next` functions are deprecated in
Neovim 0.11+ and removed in 0.12, which is one of the reasons this config
requires 0.12.0 (see {doc}`installation`).

`<leader>xv` and `<leader>xt` both print what they just did
(`"Inline diagnostic details: off"`, `"Diagnostics in this buffer: on"`) —
a toggle whose only feedback is the absence of something is a toggle you
lose track of. Both are exported as `config.diagnostics.toggle_virtual_lines()`
and `.toggle_buffer()` so `tests/test_diagnostics_display.lua` can assert
they move in *both* directions, which an earlier one-liner version did not.

## Reading a diagnostic without changing the layout

This is the intended everyday flow, given `virtual_lines` is off:

- the **sign** and the **underline** tell you a line has a problem,
- the **end-of-line text** gives you the gist,
- `<leader>xl` opens a **floating window** over the buffer with the full
  message and the tool that produced it — it overlays, so nothing below it
  moves. Press it a second time to step into the float and scroll a long
  message; `q` or any cursor movement dismisses it.
- `K` does the same for LSP hover information (types, signatures,
  documentation) — see {doc}`lsp`.

`<leader>xv` is there for the case where you want the messages permanently
in view while working through them, and `<leader>xx` opens the Trouble list
when you would rather walk a whole project's worth.

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

- **Language servers** — semantic errors, type errors, unresolved imports,
  and for Python also ruff's lint results (ruff runs as a language server,
  see {doc}`python`). Arrive automatically once a server attaches; see
  {doc}`lsp`.
- **Linters** via `nvim-lint` — style and correctness checks a language
  server does not do (`shellcheck`, `markdownlint`, `yamllint`, …). Re-checked live
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
