---@type table
return {
  filetypes = { "awk" },
  extensions = { ".awk" },
  treesitter = { "awk" },
  root_markers = { ".git" },
  lsp = { tool = "awk_ls" },
  formatters = { "gawk" },
  linters = { "gawk" },
}
