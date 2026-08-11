---@type table
return {
  filetypes = { "markdown" },
  extensions = { ".md", ".markdown" },
  treesitter = { "markdown", "markdown_inline" },
  root_markers = { ".git" },
  lsp = { tool = "marksman", extra = { cmd = { "marksman", "server" } } },
  formatters = { "prettier" },
  linters = { "markdownlint" },
}
