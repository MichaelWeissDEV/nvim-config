---@type table
return {
  filetypes = { "elm" },
  extensions = { ".elm" },
  treesitter = { "elm" },
  root_markers = { "elm.json", ".git" },
  lsp = { tool = "elmls" },
  formatters = { "elm_format" },
}
