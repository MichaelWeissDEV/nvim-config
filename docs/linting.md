# Linting

`lua/plugins/linting.lua` drives nvim-lint from `languages.registry` (see
{doc}`languages`), the same way `plugins/formatting.lua` drives conform.nvim
— but with one deliberate difference, explained below.

## Building `linters_by_ft`

At startup, for every language with `linters` entries, each tool id is
resolved to its `tools.registry` spec. Two adjustments happen along the
way:

- **`ENGINE_ALIAS`** — nvim-lint's built-in linter module names (verified
  against upstream `mfussenegger/nvim-lint`'s `lua/lint/linters/*.lua`)
  sometimes differ from this config's tool ids: `golangci_lint` maps to the
  engine name `golangcilint`, and `clang_tidy` maps to `clangtidy`.
- **`UNSUPPORTED`** — `doc8` has no nvim-lint module at all, so it's
  filtered out entirely; RST linting is left to esbonio's own LSP
  diagnostics instead.

## Live re-checking, not a startup snapshot

Unlike formatting's `formatters_by_ft` (built once and used as-is),
linting re-checks each linter's installed status **on every trigger** via
`installed_engine_names()`, which is called from a `BufWritePost` /
`InsertLeave` / `BufEnter` autocommand — formatting doesn't have this
property, because its filter runs once and its result table is fixed for
the session.

One caveat worth knowing: `detection.installed()` ultimately calls
`util.executable.exists()`, which caches its result per binary name for
the rest of the session (see the comment in `lua/util/executable.lua`).
`:ToolsInstall`/`:ToolsUpdate` (`lua/tools/install.lua`) call `M.reset()`
once every requested package has finished installing, via a real
mason-registry completion callback (not the fire-and-forget `:MasonInstall`
command) — so a linter installed mid-session starts firing on the very
next trigger, even if it was already checked and cached as missing earlier
in the same session. Verified end-to-end: install a previously-uninstalled
tool via `:ToolsInstall <profile>` and `util.executable.exists()` flips
from `false` to `true` without restarting Neovim.

## `:LinterStatus`

Opens a scratch buffer listing every filetype with configured linters and,
for each, whether it's currently installed (appending `" (missing)"` to
the display name when it isn't).

## Related

{doc}`formatting` for the parallel (startup-snapshot) design,
{doc}`tools` for installing a missing linter, {doc}`troubleshooting` for
diagnosing why a linter isn't firing.
