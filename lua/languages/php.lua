---@type table
return {
  filetypes = { "php" },
  extensions = { ".php" },
  treesitter = { "php" },
  root_markers = { "composer.json", ".git" },
  lsp = { tool = "intelephense" },
  formatters = { "php_cs_fixer" },
  linters = { "phpstan" },
}
