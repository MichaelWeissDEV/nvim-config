---@type table
return {
  filetypes = { "fish" },
  extensions = { ".fish" },
  treesitter = { "fish" },
  root_markers = { ".git" },
  lsp = { tool = "fish_lsp", extra = { cmd = { "fish-lsp", "start" } } },
  formatters = { "fish_indent" },
  linters = { "fish" },
}
