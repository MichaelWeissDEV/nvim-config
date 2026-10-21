# Languages

Every language this config knows about is one data file under
`lua/languages/*.lua`, returning a plain `LanguageSpec` table: filetypes,
Tree-sitter parser names, project root markers, which LSP server/
formatter(s)/linter(s)/debugger it uses (referenced by tool id, resolved
against {doc}`tools`), and optional buffer-local keymaps. Nothing in a
language file talks to a plugin API directly — `lsp/registry.lua`,
`plugins/formatting.lua`, `plugins/linting.lua` and `debugger/registry.lua`
each independently read this registry and drive their own plugin from it.
See {doc}`architecture` for the full picture and {doc}`development` for how
to add a new language.

## Getting a language ready: `:LangInstall` / `:LangInfo`

You never have to remember which server, formatter, linter or debugger a
language uses. Two commands work from the same registry:

| Command | Key | What it does |
|---|---|---|
| `:LangInfo [lang]` | `<leader>ti` | Lists each of the language's tools as installed, missing or inactive alternative, with the Mason package or manual-install note for every gap. Also shows its Tree-sitter parsers and the servers attached to the current buffer. |
| `:LangInstall [lang]` | `<leader>tl` | Installs everything missing through Mason: language server(s), formatter, linter, debugger. Then builds the Tree-sitter parsers, installing the `tree-sitter` CLI first if it is not there. |
| `:LangInstall! [lang]` | | Same, but also installs inactive alternatives (e.g. basedpyright next to ty). |

Without an argument, both commands use the current buffer's language, or
offer a picker. Tab-completion lists every language id. Installs run in
the background. When they finish, servers attach to the buffers already
open, with no restart. Tools Mason cannot install (e.g. `ocamllsp` via
opam) are listed with their install command instead.

Opening a file never installs anything and never nags about missing
tools. `:LangInstall` is the explicit action, and it is the only one of
these that uses the network. See {doc}`offline`.

To install whole groups of languages at once, use the profiles in
{doc}`tools` (`:ToolsInstall <profile>`, `./scripts/bootstrap.sh <profile>`).

## All languages

The table below is generated from `lua/languages/registry.lua` by
`scripts/generate-docs.lua` into `docs/_generated/languages.md`, which this
page includes verbatim.

```{include} _generated/languages.md
:start-line: 3
```
