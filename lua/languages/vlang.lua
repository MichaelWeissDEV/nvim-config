local c = require("languages.c")

---@type table
return {
  filetypes = { "v" },
  extensions = { ".v", ".vsh" },
  treesitter = { "v" },
  root_markers = { "v.mod", ".git" },
  lsp = { tool = "v_analyzer" },
  formatters = { "v" },
  debugger = c.debugger,
}
