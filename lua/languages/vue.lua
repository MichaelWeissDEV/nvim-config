---@type table
return {
  filetypes = { "vue" },
  extensions = { ".vue" },
  treesitter = { "vue" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  lsp = { tool = "vue_ls", extra = { cmd = { "vue-language-server", "--stdio" } } },
  formatters = { "prettier" },
  linters = { "eslint" },
  notes = "Modern Volar-based vue-language-server setups often also need an "
    .. "`initializationOptions.typescript.tsdk` path to a TypeScript install; not "
    .. "wired here and unverified on real hardware -- see :LspStatus if it fails to "
    .. "attach on a real Vue project.",
}
