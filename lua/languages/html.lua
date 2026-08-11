---@type table
return {
  filetypes = { "html" },
  extensions = { ".html", ".htm" },
  treesitter = { "html" },
  root_markers = { "index.html", ".git" },
  lsp = { tool = "html_lsp" },
  formatters = { "prettier" },
}
