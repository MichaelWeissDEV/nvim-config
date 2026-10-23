---@type table
return {
  filetypes = { "tcl" },
  extensions = { ".tcl", ".tk" },
  treesitter = { "tcl" },
  root_markers = { ".git" },
  formatters = { "tclfmt" },
  linters = { "nagelfar" },
}
