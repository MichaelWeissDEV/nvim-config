# Platform

## Facts vs. settings: two modules, one direction

`lua/util/platform.lua` is pure fact-gathering: `is_mac`/`is_linux`/
`is_windows`/`is_wsl` (from `vim.uv.os_uname()` and `vim.fn.has()`),
`exe_suffix`, `path_sep`, `shell()`, and the four `stdpath()`-derived
directories (`config_dir`, `data_dir`, `cache_dir`, `state_dir`). Nothing
in this file changes editor behavior — every other module asks it instead
of checking `jit.os`/`vim.fn.has` directly, so platform quirks live in one
place.

`lua/config/platform.lua` is the only module allowed to branch on those
facts to change `vim.opt`. Today that branch is short: on Windows only.

## What actually differs per OS today

- **Windows shell**: `vim.o.shell` is set to `powershell`, with a specific
  `shellcmdflag` (`-NoLogo -NoProfile -ExecutionPolicy RemoteSigned
  -Command ...` plus a console-encoding fixup to UTF-8),
  `shellredir`/`shellpipe` tuned for PowerShell's redirection syntax, and
  empty `shellquote`/`shellxquote` — all guarded so it only applies if
  `platform.is_windows`, and it's a straight assignment (no attempt to
  respect a user's already-customized shell).
- **Directories**: every path used anywhere in this config goes through
  `vim.fn.stdpath()` (`config`/`data`/`cache`/`state`) — there is no
  hardcoded `~/.config` or `%LOCALAPPDATA%` path anywhere in the Lua
  source. This is what makes the config/data/cache split "just work" on
  each OS's own convention without an if-branch.
- **`python3_host_prog`/`node_host_prog`** are intentionally left unset on
  every platform — pinning them would hardcode a machine-specific path;
  `:checkhealth` reports it if a host provider is missing, and no plugin in
  this config depends on the Python or Node RPC hosts.

Everything else — LSP, formatting, linting, debugging, Tree-sitter,
Telescope's fallback behavior — runs through the exact same code path
regardless of OS; there's no per-platform branching in those modules.

## Testing honesty

macOS is the only platform this config has actually been run and
interactively exercised on during development (see the tree-sitter-cli
caveat in {doc}`offline`, which was caught this way). Linux and Windows are
architecturally supported — they go through the same `util.platform`/
`config.platform` code paths described above, with no macOS-specific
assumptions baked into the rest of the config — but they have not been
interactively verified on a real Linux or Windows machine as part of this
project. If something here turns out to be wrong on either platform, it's
an untested code path, not a hedge.
