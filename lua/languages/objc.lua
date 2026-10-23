local c = require("languages.c")

---@type table
return {
  filetypes = { "objc" },
  extensions = { ".m" },
  treesitter = { "objc" },
  root_markers = c.root_markers,
  lsp = c.lsp,
  formatters = { "clang_format" },
  linters = { "clang_tidy" },
  debugger = c.debugger,
  notes = "Shares clangd/clang-format/clang-tidy/codelldb config with C; see languages/c.lua.",
}
