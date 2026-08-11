---@type table
return {
  filetypes = { "lua" },
  extensions = { ".lua" },
  treesitter = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", "stylua.toml", ".stylua.toml", ".git" },
  lsp = {
    tool = "lua_ls",
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
        diagnostics = { globals = { "vim" } },
        hint = { enable = true },
      },
    },
  },
  formatters = { "stylua" },
  linters = { "selene" },
  notes = "A Lua debugger is intentionally not wired up: no local-lua-debugger "
    .. "integration was stable enough across platforms to include by default.",
}
