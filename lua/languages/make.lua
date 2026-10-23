---@type table
return {
  filetypes = { "make" },
  extensions = { ".mk" },
  treesitter = { "make" },
  root_markers = { "Makefile", ".git" },
  lsp = { tool = "autotools_ls" },
  linters = { "checkmake" },
}
