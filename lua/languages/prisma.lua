---@type table
return {
  filetypes = { "prisma" },
  extensions = { ".prisma" },
  treesitter = { "prisma" },
  root_markers = { "schema.prisma", "package.json", ".git" },
  lsp = { tool = "prismals", extra = { cmd = { "prisma-language-server", "--stdio" } } },
}
