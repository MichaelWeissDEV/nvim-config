# LSP

## Native `vim.lsp.config()` / `vim.lsp.enable()`, not nvim-lspconfig

This config does not vendor nvim-lspconfig or mason-lspconfig. The full
reasoning lives as a comment at the top of `lua/lsp/registry.lua` (and is
summarized in {doc}`architecture`): every server's `cmd`/`filetypes`/
`root_markers` is already known from `languages.registry` — written once,
per language, for docs anyway — so nvim-lspconfig's ~150 files of default
server configs would mostly just be overridden. mason-lspconfig is skipped
for a sharper reason: its `automatic_enable` defaults to on in 2.x and
would start servers based on whatever Mason happens to have installed,
bypassing `languages.registry` as the single source of truth for "which
server, for which filetype." Native `vim.lsp.config()`/`vim.lsp.enable()`
(stable since Neovim 0.11) already gives per-filetype, on-demand client
start for free — a server only spawns when a matching buffer opens *and* a
root marker is found nearby.

## How a server gets configured

`lsp/registry.lua`'s `M.setup()` walks every language in
`languages.registry.all()` that declares an `lsp` (or `extra_lsp`) field
and groups the entries **by tool id**. So `c` and `cpp` sharing `clangd`
produce one `vim.lsp.config("clangd", ...)` call with the union of both
languages' filetypes and root_markers. A server is configured and
`vim.lsp.enable()`d only when both of these hold:

- its binary is found by `tools.detection.installed()`. A missing one is
  skipped silently, with no startup warning, and never attempts to spawn;
- its optional `enabled` predicate returns true. Python uses this to
  choose between ty and basedpyright (see {doc}`python`).

`M.setup()` runs again whenever the set of installed tools changes
(`:LangInstall`, `:ToolsInstall`, see {doc}`mason`) and when `:PythonLsp`
switches servers. On each run, servers that are no longer chosen or no
longer installed are disabled with `vim.lsp.enable(name, false)`, which
also stops their clients. Since Neovim 0.12, `vim.lsp.enable()` also
re-runs its `FileType` hook over every open buffer. A server installed
mid-session therefore attaches to buffers that are already open, with no
`:e` and no restart.

`:LspStatus` (`<leader>tL`) shows every configured server (binary found)
and the clients attached to the current buffer. `:LangInfo` shows the
same per language, together with what is missing.

## Capabilities

`lsp/capabilities.lua` builds the client capabilities table sent to every
server: Neovim's own defaults, extended with `cmp_nvim_lsp`'s completion
capabilities when nvim-cmp is available (LSP has to keep working with
completion disabled too), plus explicit snippet support.

## Keymaps: buffer-local, set only on attach

`lsp/attach.lua` registers an `LspAttach` autocommand. Nothing is mapped
globally. As soon as a client attaches to a buffer, these keys become
active **in that buffer only**:

| Key | Action |
|---|---|
| `gd` | Go to definition (jumps straight there) |
| `gD` | Go to declaration |
| `gy` | Go to type definition |
| `gr` | References (Telescope picker) |
| `gi` | Implementations (Telescope picker) |
| `K` | Hover documentation |
| `gK` / `<C-k>` (insert mode) | Signature help |
| `<leader>lr` | Rename symbol |
| `<leader>la` (normal + visual) | Code action |
| `<leader>ls` / `<leader>lS` | Document / workspace symbols (Telescope) |
| `<leader>lI` / `<leader>lO` | Incoming / outgoing calls (Telescope) |
| `<leader>lR` | Restart the buffer's language servers (`:lsp restart`) |
| `<leader>li` | `:LspStatus` |
| `<leader>ci` | Toggle inlay hints (servers that support them) |

To get back after a jump, use `<C-o>`; `<C-i>` goes forward again. The
client sets `'tagfunc'`, so `<C-]>` also goes to the definition, and
`<C-w>]` opens it in a split.

A few of these choices need explaining:

- **`<C-k>` is insert-mode only.** It used to be mapped in normal mode as
  well, where it shadowed "go to the window above" (`<C-k>`, see
  {doc}`keymaps`) in every buffer with a language server. In normal mode,
  `gK` does the same.
- **`gr` is mapped with `nowait`.** Neovim's own `grr`/`grn`/`gra`/`gri`/
  `grt` defaults share the `gr` prefix. Without `nowait`, every `gr` would
  pause for `'timeoutlen'` to see whether another key follows. Each of
  those defaults has its own key above.
- **Pressing `gd` in a buffer with no attached client** falls through to
  Vim's normal `gd`. It never errors against a dead client, because the
  mapping was never registered in that buffer.

### Reference highlighting

When the cursor rests on a symbol (`'updatetime'`, 250 ms), other
occurrences in the buffer are highlighted (`textDocument/documentHighlight`).
The highlight clears as soon as the cursor moves. Only servers that
support it take part. To turn it off, set
`vim.g.nvim_config_reference_highlight = false` in
`lua/config/local.lua`.

## Inlay hints

Opt-in, not automatic: if the attaching client supports
`textDocument/inlayHint`, `lsp/attach.lua` registers a `<leader>ci` toggle
for that buffer, but does **not** enable hints itself. They used to be
auto-enabled on attach; that was changed after it turned out to be a real
source of typing lag on large files/projects. Neovim's built-in
`vim.lsp.inlay_hint` module re-requests hints from every capable attached
client on every `textDocument/didChange` notification (see
`vim/lsp/inlay_hint.lua`'s `LspNotify` autocommand in Neovim's own
runtime) — i.e. on every debounced keystroke while typing, once per
capable client. That's doubled for any buffer with two hint-capable clients
(Python with `:PythonLsp both`, see {doc}`python`), and for at least one
observed case (a large C++ translation unit) produced clangd's
`-32001: invalid AST` error, which clangd throws when a request outruns
its ability to keep the AST synchronized — exactly what frequent hint
requests do. Toggle hints on with `<leader>ci` when you want them for a
specific buffer.

## Related

{doc}`languages` for which servers are wired to which filetypes,
{doc}`python` for the ty / ruff / basedpyright setup,
{doc}`tools` for install profiles, {doc}`completion` for how LSP results
feed nvim-cmp, {doc}`troubleshooting` for diagnosing a server that won't
attach.
