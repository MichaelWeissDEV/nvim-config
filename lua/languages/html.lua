---@type table
return {
  filetypes = { "html" },
  extensions = { ".html", ".htm" },
  treesitter = { "html" },
  root_markers = { "index.html", ".git" },
  -- vscode-html-language-server requires an explicit transport flag (same
  -- vscode-langservers-extracted family as css/json below).
  lsp = { tool = "html_lsp", extra = { cmd = { "vscode-html-language-server", "--stdio" } } },
  formatters = { "prettier" },
}
