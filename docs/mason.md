# Mason

## What's vendored, and what isn't

`lua/plugins/mason.lua` vendors `mason.nvim` itself, for exactly one
purpose: the installer UI and its commands — `:Mason`, `:MasonInstall
<package>`, `:MasonUpdate`. Loading the plugin and calling `setup()` does
not contact the network or refresh the registry by itself; that only
happens when `:Mason`, `:MasonInstall`, `:MasonUpdate`, or `:ToolsInstall`/
`:ToolsUpdate` are run explicitly.

**mason-lspconfig is deliberately not vendored.** Quoting the comment in
`plugins/mason.lua`: its `automatic_enable` defaults to on in 2.x, which
would start LSP servers based on whatever Mason happens to have installed
— duplicating and fighting `lsp/registry.lua`, which is the single source
of truth for "which server starts for which filetype" in this config. See
{doc}`lsp` for the full reasoning behind native `vim.lsp.config()`/
`vim.lsp.enable()` instead.

## `:ToolsInstall` / `:ToolsUpdate`

`lua/tools/install.lua` wraps Mason with this config's own profile
concept. Given a profile name (or `all`), it resolves `tools.registry`
entries belonging to that profile into two lists: Mason-installable
packages (deduplicated, since several languages can share one tool) and
tools with no Mason package at all (reported as a one-shot info
notification listing each one's name and manual-install note, e.g.
"install via: gem install debug" for `rdbg`).

- `:ToolsInstall <profile>` — installs every Mason-installable tool for
  that profile via `:MasonInstall`, then reports anything that needs
  manual installation.
- `:ToolsUpdate <profile>` — re-runs `:MasonInstall` on the same package
  set, which also upgrades already-installed packages.

Both commands validate the profile name against `tools.registry.profiles`
plus `"all"` and error out on an unknown one, with tab-completion offered
for the valid list. See {doc}`tools` for the full profile list.

## Nothing here runs automatically

`:Mason`, `:MasonInstall`, `:MasonUpdate`, `:ToolsInstall`, `:ToolsUpdate`,
and `./scripts/bootstrap.sh` (which drives `:ToolsInstall` from the
command line) are the only things in this repository that talk to the
network, and every one of them requires the user to type the command. See
{doc}`offline` for the complete list of what does and doesn't touch the
network.
