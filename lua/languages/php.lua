---@type table
return {
  filetypes = { "php" },
  extensions = { ".php" },
  treesitter = { "php" },
  root_markers = { "composer.json", ".git" },
  lsp = { tool = "intelephense", extra = { cmd = { "intelephense", "--stdio" } } },
  formatters = { "php_cs_fixer" },
  linters = { "phpstan" },
}
