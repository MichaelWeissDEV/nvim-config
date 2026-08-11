---@type table
return {
  filetypes = { "json", "jsonc" },
  extensions = { ".json", ".jsonc" },
  treesitter = { "json", "jsonc" },
  root_markers = { ".git" },
  lsp = { tool = "jsonls", extra = { cmd = { "vscode-json-language-server", "--stdio" } } },
  formatters = { "prettier" },
}
