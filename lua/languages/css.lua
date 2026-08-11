---@type table
return {
  filetypes = { "css", "scss", "sass", "less" },
  extensions = { ".css", ".scss", ".sass", ".less" },
  treesitter = { "css", "scss" },
  root_markers = { ".git" },
  lsp = { tool = "css_lsp", extra = { cmd = { "vscode-css-language-server", "--stdio" } } },
  formatters = { "prettier" },
  linters = { "stylelint" },
}
