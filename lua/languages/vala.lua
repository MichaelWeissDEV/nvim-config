local c = require("languages.c")

---@type table
return {
  filetypes = { "vala" },
  extensions = { ".vala", ".vapi" },
  treesitter = { "vala" },
  root_markers = { "meson.build", "CMakeLists.txt", ".git" },
  lsp = { tool = "vala_ls" },
  debugger = c.debugger,
}
