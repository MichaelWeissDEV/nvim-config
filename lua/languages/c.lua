---@type table
return {
  filetypes = { "c" },
  extensions = { ".c", ".h" },
  treesitter = { "c" },
  root_markers = { "compile_commands.json", "compile_flags.txt", "CMakeLists.txt", "Makefile", ".git" },
  lsp = { tool = "clangd", extra = { cmd = { "clangd", "--background-index", "--clang-tidy" } } },
  formatters = { "clang_format" },
  linters = { "clang_tidy" },
  debugger = {
    tool = "codelldb",
    adapter = require("debugger.adapters.codelldb").adapter,
    configurations = function()
      return { require("debugger.adapters.codelldb").configuration() }
    end,
  },
  notes = "Falls back to gdb if codelldb is unavailable; see :DebuggerStatus.",
}
