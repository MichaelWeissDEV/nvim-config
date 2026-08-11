---@type table
return {
  filetypes = { "yaml" },
  extensions = { ".yaml", ".yml" },
  treesitter = { "yaml" },
  root_markers = { ".git" },
  lsp = { tool = "yamlls", extra = { cmd = { "yaml-language-server", "--stdio" } } },
  formatters = { "prettier" },
  linters = { "yamllint" },
}
