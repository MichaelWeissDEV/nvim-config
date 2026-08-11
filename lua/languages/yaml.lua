---@type table
return {
  filetypes = { "yaml" },
  extensions = { ".yaml", ".yml" },
  treesitter = { "yaml" },
  root_markers = { ".git" },
  lsp = { tool = "yamlls" },
  formatters = { "prettier" },
  linters = { "yamllint" },
}
