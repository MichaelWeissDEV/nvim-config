---@type table
return {
  filetypes = { "vue" },
  extensions = { ".vue" },
  treesitter = { "vue" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  lsp = { tool = "vue_ls" },
  formatters = { "prettier" },
  linters = { "eslint" },
}
