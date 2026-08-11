# Tools

Every external LSP server, formatter, linter and debug adapter this config
knows how to use is one entry in `lua/tools/registry.lua`: display name,
binary to check for, Mason package name (if any), and which install
profile(s) it belongs to. Language files (`lua/languages/*.lua`) reference
tools by id only — nothing hardcodes a binary or Mason package name more
than once. See {doc}`architecture`.

Tools are grouped into install profiles, matching `M.profiles` in the
registry plus the special `all`:

`core`, `systems`, `python`, `scripting`, `web`, `jvm`, `dotnet`,
`functional`, `devops`, `docs`, `all`

Install a profile with:

```bash
./scripts/bootstrap.sh <profile>
```

or from inside Neovim with `:ToolsInstall <profile>` / `:ToolsUpdate
<profile>` — both wrap `mason.nvim`; see {doc}`mason`. Neither runs on its
own; nothing here is installed automatically. Run `:ToolsStatus` or
`:NvimConfigHealth` to see what's actually present on your machine.

The table below is generated from `lua/tools/registry.lua` by
`scripts/generate-docs.lua`, identical to `TOOLS.md` at the repo root.

```{include} ../TOOLS.md
:start-line: 3
```
