# Mason

## What's vendored, and what isn't

`lua/plugins/mason.lua` vendors `mason.nvim` itself, for exactly one
purpose: the installer UI and its commands — `:Mason`, `:MasonInstall
<package>`, `:MasonUpdate`. Loading the plugin and calling `setup()` does
not contact the network or refresh the registry by itself; that only
happens when `:Mason`, `:MasonInstall`, `:MasonUpdate`, `:LangInstall`, or
`:ToolsInstall`/`:ToolsUpdate` are run explicitly.

**mason-lspconfig is deliberately not vendored.** Quoting the comment in
`plugins/mason.lua`: its `automatic_enable` defaults to on in 2.x, which
would start LSP servers based on whatever Mason happens to have installed
— duplicating and fighting `lsp/registry.lua`, which is the single source
of truth for "which server starts for which filetype" in this config. See
{doc}`lsp` for the full reasoning behind native `vim.lsp.config()`/
`vim.lsp.enable()` instead.

## `:LangInstall` — one language at a time

The quickest way to set a language up. Run `:LangInstall python`, or
press `<leader>tl` in a buffer of that language. It installs the language
server(s), formatter, linter and debugger that `lua/languages/<id>.lua`
uses, plus its Tree-sitter parsers. `:LangInfo` (`<leader>ti`) shows what
is there and what is missing. Details are in {doc}`languages`.

nvim-treesitter compiles parsers with the `tree-sitter` CLI. Mason
packages it as `tree-sitter-cli`, so `:LangInstall` (and
`./scripts/bootstrap.sh`) install it first whenever a parser has to be
built and the CLI is not on `PATH`. A C compiler is the only build
requirement left.

## `:ToolsInstall` / `:ToolsUpdate` — whole profiles

`lua/tools/install.lua` wraps Mason with this config's own profile
concept. Given a profile name (or `all`), it resolves `tools.registry`
entries belonging to that profile into two lists: Mason-installable
packages (deduplicated, since several languages can share one tool) and
tools with no Mason package at all (reported as a one-shot info
notification listing each one's name and manual-install note, e.g.
"install via: gem install debug" for `rdbg`).

- `:ToolsInstall <profile>` — installs every Mason-installable tool for
  that profile, then reports anything that needs manual installation.
- `:ToolsUpdate <profile>` — reinstalls the same package set, which also
  upgrades packages that are already installed.

`:ToolsInstall`, `:ToolsUpdate` and `:LangInstall` all go through one
function, `tools.install.install_packages()`. It talks to
`mason-registry` directly rather than through `:MasonInstall`, which
gives it a completion callback. When everything has finished, it sends
one notification naming what is ready and what failed (`:Mason`, then
`g?`, shows the log). It also fires `User NvimConfigToolsChanged` once.
LSP, formatting and linting react to that event, so new tools work
immediately.

Both commands validate the profile name against `tools.registry.profiles`
plus `"all"` and error out on an unknown one, with tab-completion offered
for the valid list. See {doc}`tools` for the full profile list.

## Nothing here runs automatically

`:Mason`, `:MasonInstall`, `:MasonUpdate`, `:LangInstall`, `:ToolsInstall`,
`:ToolsUpdate`, and `./scripts/bootstrap.sh` (which drives `:ToolsInstall` from the
command line) are the only things in this repository that talk to the
network, and every one of them requires the user to type the command. See
{doc}`offline` for the complete list of what does and doesn't touch the
network.
