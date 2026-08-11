---@type table
return {
  filetypes = { "xml" },
  extensions = { ".xml" },
  treesitter = { "xml" },
  root_markers = { ".git" },
  lsp = { tool = "lemminx" },
}
