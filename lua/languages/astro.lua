---@type table
return {
  filetypes = { "astro" },
  extensions = { ".astro" },
  treesitter = { "astro" },
  root_markers = { "astro.config.mjs", "astro.config.ts", "package.json", ".git" },
  lsp = { tool = "astro_ls", extra = { cmd = { "astro-ls", "--stdio" } } },
  formatters = { "prettier" },
}
