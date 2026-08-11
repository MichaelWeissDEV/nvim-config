---@type table
return {
  filetypes = { "svelte" },
  extensions = { ".svelte" },
  treesitter = { "svelte" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  lsp = { tool = "svelte_ls", extra = { cmd = { "svelteserver", "--stdio" } } },
  formatters = { "prettier" },
  linters = { "eslint" },
}
