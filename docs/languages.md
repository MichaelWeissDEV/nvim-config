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

The table below is generated from `lua/languages/registry.lua` by
`scripts/generate-docs.lua`, identical to `LANGUAGES.md` at the repo root.

```{include} ../LANGUAGES.md
:start-line: 3
```
