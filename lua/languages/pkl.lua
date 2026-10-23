---@type table
return {
  filetypes = { "pkl" },
  extensions = { ".pkl" },
  treesitter = { "pkl" },
  root_markers = { "PklProject", ".git" },
  lsp = { tool = "pkl_lsp" },
  formatters = { "pkl" },
}
