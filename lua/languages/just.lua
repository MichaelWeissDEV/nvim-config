---@type table
return {
  filetypes = { "just" },
  extensions = { ".just", "justfile" },
  treesitter = { "just" },
  root_markers = { "justfile", "Justfile", ".git" },
  lsp = { tool = "just_lsp" },
  formatters = { "just" },
}
