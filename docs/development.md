# Development

For extending this config. Read {doc}`architecture` first for the four
registries this all revolves around.

## Adding a new language

One data file, `lua/languages/<id>.lua`, returning a plain table matching
the `LanguageSpec` schema documented as a comment at the top of
`lua/languages/registry.lua`:

```
@class LanguageSpec
  id            string                unique id, matches the filename
  filetypes     string[]              vim filetypes this spec applies to
  extensions    string[]?             file extensions, documentation only
  treesitter    string[]?             nvim-treesitter parser names
  root_markers  string[]?             files/dirs that mark a project root
  lsp           { tool: string, settings: table?, extra: table? }?
  formatters    string[]?             tool ids from tools.registry, in order
  linters       string[]?             tool ids from tools.registry
  debugger      { tool: string, adapter: fun():table, configurations: fun():table[] }?
  indent        { shiftwidth: integer, expandtab: boolean? }?  documentation;
                applied for real via after/ftplugin/<filetype>.lua
  keymaps       fun(bufnr: integer)?  buffer-local, filetype-scoped keymaps
  notes         string?
```

`lua/languages/rust.lua` is a good concrete example — LSP settings, a
formatter, an intentionally empty `linters` list (with a comment
explaining clippy runs through `rust-analyzer`'s `checkOnSave` instead),
a debugger built from the shared `debugger.adapters.codelldb` module, and
a buffer-local keymap.

Steps:

1. Add the new id to `LANGUAGE_IDS` in `lua/languages/registry.lua`.
2. Create `lua/languages/<id>.lua` with the fields above. Every `lsp.tool`/
   `formatters[]`/`linters[]`/`debugger.tool` value must already be an id
   in `lua/tools/registry.lua` — never invent a new tool id in a language
   file. If the tool doesn't exist yet there, add it first (see below).
3. `languages.registry`'s `validate()` asserts `filetypes` is non-empty,
   and that `lsp.tool`/`debugger.tool` are set if those tables exist at
   all. Two different failure modes if you get this wrong: a broken
   `require("languages.<id>")` (syntax error, bad `local` reference) is
   caught by `pcall` in `load_all()` and reported as a `config_error`
   notification, same as any other config error. A `validate()` assertion
   failure is **not** inside that `pcall` — it propagates as a raw Lua
   error out of `load_all()`, which is louder (a traceback, not a
   dedup'd/graceful notification) and worth knowing about before you rely
   on the gentler `config_error` path from step 2.
4. Run `./scripts/docs-build.sh` to regenerate `LANGUAGES.md` and the
   Sphinx docs.

## Adding a new tool

Add one `add({...})` call in `lua/tools/registry.lua` — `id`, `name`,
`category` (`"lsp"|"formatter"|"linter"|"debugger"`), `exe` (binary or
list of binaries checked via `util.executable.exists`), `mason` (package
name, or `nil` if not Mason-installable — add a `note` explaining the
manual install command instead), and `profiles` (which
`./scripts/bootstrap.sh <profile>` bundles it belongs to). `add()` asserts
the id isn't already taken. See {doc}`tools` for the full current list and
{doc}`mason` for how `mason`/`nil` affects `:ToolsInstall`.

## Adding a new keymap or command

Always through the registries — never a bare `vim.keymap.set()` or
`vim.api.nvim_create_user_command()`:

- `util.keymap_registry.map({...})` (or `.map_many({...})` for several at
  once) — `mode`, `lhs`, `rhs`, `desc`, `group` are required; `context` and
  `buffer` are optional. This single call applies the mapping *and*
  records it for which-key, `:NvimKeymaps`, Telescope, and generated
  `KEYMAPS.md`/Sphinx docs.
- `util.command_registry.command({...})` — `name`, `desc`, `category`,
  `fn` (plus optional `example`/`args`/`opts` passed through to
  `nvim_create_user_command`). For a command that belongs to a vendored
  plugin rather than this config (e.g. `:Gitsigns`, `:Telescope`),
  `command_registry.external({...})` documents it without redefining it.

Going around either registry means the mapping/command works but silently
falls out of `:NvimKeymaps`/`:NvimCommands`, which-key, and the generated
docs — the whole point of the registries is that there's exactly one place
that can drift.

## Code style

- Formatted with `stylua`; the project's `.stylua.toml`: 120-column width,
  2-space indent, `AutoPreferDouble` quote style, parentheses always
  required on function calls.
- Comments explain non-obvious *why*, not *what* — see any file under
  `lua/` for the convention in practice (e.g. the reasoning comments atop
  `lsp/registry.lua`, `plugins/mason.lua`, `plugins/completion.lua`).
  Don't add a comment that just restates the line below it.

## After changing a registry

```bash
./scripts/docs-build.sh
```

Regenerates `KEYMAPS.md`, `COMMANDS.md`, `LANGUAGES.md`, `TOOLS.md`,
`PLUGINS.md`, `doc/nvim-config.txt`, and rebuilds this Sphinx site from
`scripts/generate-docs.lua` reading the same four registries — so a
registry change and its documentation can never silently drift apart.
