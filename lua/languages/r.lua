---@type table
return {
  filetypes = { "r", "rmd" },
  extensions = { ".R", ".r", ".Rmd", ".rmd" },
  treesitter = { "r" },
  root_markers = { "DESCRIPTION", ".Rproj", ".git" },
  lsp = { tool = "r_language_server" },
  formatters = { "air" },
}
