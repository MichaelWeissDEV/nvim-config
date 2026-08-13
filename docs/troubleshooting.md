# Troubleshooting

## Reading `:NvimConfigHealth`

`:NvimConfigHealth` is an alias for `:checkhealth nvim-config` (see
`lua/config/commands.lua`). It aggregates several independent checks —
`lua/config/health.lua` (Neovim version, platform, core tools, docs/help
tags) plus `plugins/health.lua` (vendored plugin directories) and
`tools/status.lua` (LSP/formatter/linter/debugger install status). Reading
the source of those three files gives the exact severity rules, which are
narrower than they might look:

- **OK** (`vim.health.ok`) — present and working: Neovim version new
  enough, a vendored plugin directory found, `git`/`rg`/`fd` found on
  `PATH`, docs built, help tags generated, a tool installed.
- **WARNING** (`vim.health.warn`) — an *optional* thing is missing and
  degrades gracefully: `rg`/`fd` not found (Telescope falls back — see
  {doc}`telescope`), Sphinx docs not built, `:help` tags not generated, or
  any LSP/formatter/linter/debugger tool not installed (`tools/status.lua`
  emits one warning per missing tool, each with its own `:ToolsInstall
  <profile>` hint).
- **ERROR** (`vim.health.error`) — something is actually broken, not just
  absent-by-design: Neovim below 0.12.0 (`config/health.lua`, via the
  contract in `util.version`), or a vendored
  plugin directory missing from `pack/vendor/{start,opt}/`
  (`plugins/health.lua` — this means an incomplete clone/checkout, not a
  missing optional external tool; its hint points at
  `scripts/plugin-status.sh`).

A genuine Lua error while loading the config (a bad plugin `setup()` call,
a broken language file, etc.) does **not** go through `:checkhealth` at
all — it's routed through `util.notify.config_error`, which always fires
immediately as a loud `vim.notify` ERROR popup, never deduplicated, never
hidden behind a `pcall` that swallows it silently. If you see an
`[nvim-config] ... failed to load:` notification on startup, that's a real
bug to report/fix, not a missing-tool warning.

## What a normal session should notify

Zero. A clean session with everything you use installed produces no
notifications at all. If you deliberately exercise a feature whose
dependency is missing (try to debug a language with no debugger installed,
format with no formatter present, `live_grep` with no `rg`), you'll get
**at most one** notification for that specific gap, because every one of
these paths routes through `util.notify`'s dedup cache (`M.once`/
`M.missing_dependency` in `lua/util/notify.lua`) keyed by feature+tool —
trying the same missing thing again in the same session produces nothing
further.

The standard wording, quoted directly from `notify.missing_dependency`:

```
"%s not available: '%s' is not installed."
```

with, if an install hint was given:

```
" Install via %s."
```

appended — e.g. `"rust debugger not available: 'CodeLLDB' is not
installed. Install via :ToolsInstall systems."` Formatting and linting use
their own, differently-worded one-shot messages for the same "no tool"
situation — see {doc}`formatting` and {doc}`linting` for their exact
strings.

If you're seeing repeated notifications for the *same* gap within one
session, or notifications on a totally clean startup with nothing
triggered, that's itself worth reporting — it means the dedup key isn't
matching, or something is firing outside the `notify.once`/
`missing_dependency` path.

## The tree-sitter-cli caveat

`:TSInstall`/`:TSUpdate`/`bootstrap.sh` need the external `tree-sitter` CLI
(0.26.1+) and a C compiler, installed separately from Neovim. See
{doc}`offline` for the exact failure mode
(`ENOENT: no such file or directory (cmd): 'tree-sitter'`) and install
commands — not repeated here.

## Common `:checkhealth nvim-config` warnings and fixes

Straight from `lua/config/health.lua`'s own advice text:

- **`rg not found on PATH`** — improves Telescope `live_grep`/
  `grep_string` speed and accuracy.
  `macOS: brew install ripgrep` | `Debian/Ubuntu: apt install ripgrep` |
  `Arch: pacman -S ripgrep`
- **`fd not found on PATH`** — improves Telescope `find_files` speed;
  falls back to Neovim's own globbing otherwise.
  `macOS: brew install fd` | `Debian/Ubuntu: apt install fd-find` |
  `Arch: pacman -S fd`
- **`Local Sphinx docs not built`** — run `./scripts/docs-build.sh`.
- **`:help nvim-config tags missing`** — run `:helptags
  ~/.config/nvim/doc` (or re-run `./scripts/install.sh`).
- **any tool under Language Servers/Formatters/Linters/Debuggers marked
  "not installed"** — run `:ToolsInstall <profile>` for the profile shown
  in the hint (or the manual command in its note, for tools with no Mason
  package — see {doc}`tools`). `:ToolsInstall`/`:ToolsUpdate` reset
  `util.executable`'s cache once every package finishes installing (see
  {doc}`linting`), so formatters/linters/debuggers pick up a freshly
  installed tool on their very next trigger, no restart needed. Language
  servers are re-registered too: `lsp/registry.lua` subscribes to the same
  `User NvimConfigToolsChanged` event and re-runs its idempotent
  `refresh()`. A **buffer that was already open** still needs `:e` (or a
  restart) before the newly available server attaches to it.

## Diagnosing "a language server won't attach"

In order:

1. `:LspStatus` — check whether the server shows up under "Configured
   servers (binary found on PATH)" at all. If it's missing there, the
   binary genuinely isn't on `PATH`, or the language module's `lsp.tool`
   id doesn't resolve in `tools.registry` (which itself would show as a
   `config_error` notification, not silence — see above).
2. `:checkhealth nvim-config` (or `:NvimConfigHealth`), Language Servers
   section — confirms the same install status as `:LspStatus`, with the
   install hint if it's missing.
3. Confirm the binary really is on `PATH` in the same shell/environment
   Neovim was launched from: `which <binary>` (the exact binary name is in
   `tools.registry`'s `exe` field for that tool, shown in
   `:ToolsStatus`/`:checkhealth`).
4. Confirm a root marker is actually found: `lsp/registry.lua` only
   configures `root_markers` from the language spec, and native
   `vim.lsp.enable()` only starts a client when a buffer's ancestor
   directories contain one of them. Opening a file with no matching
   project marker nearby (e.g. no `Cargo.toml` anywhere above a stray
   `.rs` file) means the server is configured but genuinely won't start
   for that buffer — check the language's `root_markers` list in
   {doc}`languages`.
5. If the binary is installed and a root marker is present but the server
   still doesn't attach after opening the buffer, check `:messages` for a
   `config_error` notification (a malformed `lsp.extra`/`lsp.settings`
   table would surface there, from the `pcall(vim.lsp.config, ...)` in
   `lsp/registry.lua`) — that's a real bug, not a missing dependency.

Installing a server mid-session via `:ToolsInstall` re-registers it
immediately (`lsp/registry.lua` listens for `User NvimConfigToolsChanged`),
but a buffer that was already open when it arrived needs `:e` to pick it
up.
