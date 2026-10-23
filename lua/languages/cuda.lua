local c = require("languages.c")

---@type table
return {
  filetypes = { "cuda" },
  extensions = { ".cu", ".cuh" },
  treesitter = { "cuda" },
  root_markers = c.root_markers,
  lsp = c.lsp,
  formatters = { "clang_format" },
  debugger = c.debugger,
  notes = "Shares clangd/clang-format/codelldb config with C; see languages/c.lua.",
}
