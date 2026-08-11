# Debugging

## Why the module is named "debugger", not "dap"

`lua/debugger/` (not `lua/dap/`) wires up nvim-dap. The vendored plugin
itself is `require("dap")` — reusing that module name in this config's own
tree would let whichever one loads first shadow the other in
`package.loaded`. This is called out explicitly at the point of use, in
`init.lua`:

```
require("debugger") -- DAP core (adapters + UI load lazily on first debug action); named
-- "debugger", not "dap", because the vendored nvim-dap plugin itself is require("dap") --
-- reusing that name would let whichever module loads first shadow the other in package.loaded.
```

See also {doc}`architecture`, which documents the same reasoning for the
`lua/` layout as a whole.

## Lazy-load chain

Three separate load points, each later than the last:

1. **nvim-dap itself** (an `opt` package) loads the first time any
   `<leader>d*` keymap is pressed — `lua/debugger/init.lua`'s `ensure_core()`
   calls `lazyload.packadd("nvim-dap")`. Setting a breakpoint alone is
   enough to trigger this.
2. **nvim-dap-ui and nvim-nio** load only when the UI is actually needed —
   either `<leader>dc` (Start/Continue) or `<leader>du` (Toggle debug UI)
   call `ensure_ui()` — never on a mere breakpoint. `ensure_ui()` wires
   `dapui.open()`/`close()` to nvim-dap's
   `event_initialized`/`event_terminated`/`event_exited` listeners and
   only does this setup once (`dapui_ready` flag), so pressing `<leader>du`
   before ever starting a session still loads nvim-dap-ui/nvim-nio on its
   own, without a session running.
3. **Per-language adapter/configuration registration** happens the first
   time `debugger.registry.ensure_for_filetype()` runs for a given
   filetype (also triggered by `<leader>dc`), not at startup — nvim-dap has
   no native "lazy register" concept, so `debugger/registry.lua` just
   tracks which tool ids and filetypes it's already registered
   (`registered_adapters`, `registered_filetypes`) and skips re-registering.

## Keymaps

All defined in `lua/debugger/init.lua`, group `Debug`:

| Key | Action |
|---|---|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint (prompts for a condition) |
| `<leader>dc` | Start / Continue |
| `<leader>di` | Step into |
| `<leader>do` | Step over |
| `<leader>dO` | Step out |
| `<leader>dr` | Toggle REPL |
| `<leader>du` | Toggle debug UI |
| `<leader>dt` | Terminate session |
| `<leader>dl` | Run last configuration |

## `:DebuggerStatus`

Lists every language with a `debugger` entry in its language spec, and
whether that debugger's adapter binary is installed, e.g. `[OK]
rust -> CodeLLDB` or `[MISSING] go -> delve`.

## What's real vs. a placeholder

Most debuggers in `languages/registry.lua` are fully wired: C, C++, Rust
and Assembly share `debugger.adapters.codelldb`'s adapter/configuration
builder (one CodeLLDB launch-config boilerplate, reused instead of
duplicated per language).

**Java is a documented placeholder.** `lua/languages/java.lua` sets
`debugger.tool = "java_debug"` but both `adapter()` and `configurations()`
return empty tables (`{}`). Its `notes` field explains why: the real
debugger integration for Java goes through jdtls's own DAP bridge, not a
standalone adapter binary — `lsp/registry.lua` currently merges `lsp.extra`
directly into the `vim.lsp.config()` call, and jdtls needs a
project-specific workspace-directory formula that doesn't fit that
mechanism as plain data. The note names `lsp/dap/java.lua` (Phase 6/7) as
where this gets a proper code path. Until then, trying to debug a Java
file hits the "0 configurations" branch in `debugger/registry.lua` and
reports "Debugging for 'java' is not implemented yet" rather than silently
failing.

## Related

{doc}`architecture` for the vendor-loading model this lazy-load chain sits
on top of, {doc}`languages` for the full `LanguageSpec.debugger` schema,
{doc}`tools` for installing a missing debug adapter.
