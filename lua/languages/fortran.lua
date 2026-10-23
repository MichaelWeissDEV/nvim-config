local c = require("languages.c")

---@type table
return {
  filetypes = { "fortran" },
  extensions = { ".f90", ".f95", ".f03", ".f08", ".f", ".for" },
  treesitter = { "fortran" },
  root_markers = { "fpm.toml", "CMakeLists.txt", "Makefile", ".git" },
  lsp = { tool = "fortls" },
  formatters = { "fprettify" },
  debugger = c.debugger,
  notes = "Shares codelldb debugger config with C; see languages/c.lua.",
}
