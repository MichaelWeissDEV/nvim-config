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

`lsp/registry.lua`'s `M.setup()` (called once at startup) walks every
language in `languages.registry.all()` that declares an `lsp` field,
groups entries **by tool id** (so `c` and `cpp` sharing `clangd` produce
one `vim.lsp.config("clangd", ...)` call with the union of both
filetypes' filetypes/root_markers), and skips any tool whose binary isn't
found by `tools.detection.installed()` — silently, no startup warning. Only
then is `vim.lsp.config()` called and `vim.lsp.enable()` invoked for that
server. This means: install `rust-analyzer` mid-session and it still won't
attach until Neovim restarts (`M.setup()` runs once), but a server your
machine doesn't have never even attempts to spawn.

`:LspStatus` shows two things: every server that *is* configured (binary
found), and which clients are actually attached to the current buffer.

## Capabilities

`lsp/capabilities.lua` builds the client capabilities table sent to every
server: Neovim's own defaults, extended with `cmp_nvim_lsp`'s completion
capabilities when nvim-cmp is available (LSP has to keep working with
completion disabled too), plus explicit snippet support.

## Keymaps: buffer-local, set only on attach

`lsp/attach.lua` registers an `LspAttach` autocommand — nothing is mapped
globally. The moment a client attaches to a buffer, these become active
**in that buffer only**:

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `<C-k>` (normal + insert) | Signature help |
| `<leader>lr` | Rename symbol |
| `<leader>la` (normal + visual) | Code action |
| `<leader>ls` | Document symbols |
| `<leader>li` | `:LspStatus` |

Pressing `gd` in a buffer with no attached client just falls through to
whatever non-LSP mapping/behavior `gd` otherwise has — it never errors
against a dead client, because the mapping was never registered there in
the first place.

## Inlay hints

If the attaching client supports `textDocument/inlayHint`, inlay hints are
enabled for that buffer automatically (`vim.lsp.inlay_hint.enable(true,
...)`). Some languages add their own toggle on top — e.g. Rust's
`<leader>ci` (see `lua/languages/rust.lua`, documented in {doc}`languages`).

## Related

{doc}`languages` for which servers are wired to which filetypes,
{doc}`tools` for install profiles, {doc}`completion` for how LSP results
feed nvim-cmp, {doc}`troubleshooting` for diagnosing a server that won't
attach.
