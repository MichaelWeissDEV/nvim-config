---@type table
return {
  filetypes = { "typst" },
  extensions = { ".typ" },
  treesitter = { "typst" },
  root_markers = { "typst.toml", ".git" },
  lsp = { tool = "tinymist" },
  formatters = { "typstyle" },
}
