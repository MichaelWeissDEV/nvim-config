local c = require("languages.c")

---@type table
return {
  filetypes = { "asm", "nasm", "masm" },
  extensions = { ".asm", ".s", ".S" },
  treesitter = { "asm", "nasm" },
  root_markers = { ".git" },
  lsp = { tool = "asm_lsp" },
  formatters = { "asmfmt" },
  debugger = c.debugger,
  notes = "Shares codelldb/gdb debugger config with C; see languages/c.lua.",
}
