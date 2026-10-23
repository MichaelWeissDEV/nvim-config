local c = require("languages.c")

---@type table
return {
  filetypes = { "zig" },
  extensions = { ".zig" },
  treesitter = { "zig" },
  root_markers = { "build.zig", ".git" },
  lsp = { tool = "zls" },
  formatters = { "zigfmt" },
  debugger = c.debugger,
  notes = "zig fmt ships with the zig compiler itself; shares codelldb debugger config with C.",
}
