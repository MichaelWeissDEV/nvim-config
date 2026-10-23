---@type table
return {
  filetypes = { "nu" },
  extensions = { ".nu" },
  treesitter = { "nu" },
  root_markers = { ".git" },
  lsp = { tool = "nuls", extra = { cmd = { "nu", "--lsp" } } },
  formatters = { "nufmt" },
  notes = "`nu --lsp` is built into the Nushell binary.",
}
