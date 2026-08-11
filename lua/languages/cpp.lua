local c = require("languages.c")

---@type table
return {
  filetypes = { "cpp", "objcpp" },
  extensions = { ".cpp", ".cc", ".cxx", ".hpp", ".hh", ".hxx" },
  treesitter = { "cpp" },
  root_markers = c.root_markers,
  lsp = { tool = "clangd", extra = { cmd = { "clangd", "--background-index", "--clang-tidy" } } },
  formatters = { "clang_format" },
  linters = { "clang_tidy" },
  debugger = c.debugger,
  notes = "Shares clangd/clang-format/clang-tidy/codelldb config with C; see languages/c.lua.",
}
