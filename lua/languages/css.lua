---@type table
return {
  filetypes = { "css", "scss", "sass", "less" },
  extensions = { ".css", ".scss", ".sass", ".less" },
  treesitter = { "css", "scss" },
  root_markers = { ".git" },
  lsp = { tool = "css_lsp" },
  formatters = { "prettier" },
  linters = { "stylelint" },
}
