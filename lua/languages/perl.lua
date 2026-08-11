---@type table
return {
  filetypes = { "perl" },
  extensions = { ".pl", ".pm" },
  treesitter = { "perl" },
  root_markers = { ".git" },
  lsp = { tool = "perl_navigator" },
  formatters = { "perltidy" },
  linters = { "perlcritic" },
}
