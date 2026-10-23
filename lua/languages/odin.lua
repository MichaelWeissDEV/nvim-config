local c = require("languages.c")

---@type table
return {
  filetypes = { "odin" },
  extensions = { ".odin" },
  treesitter = { "odin" },
  root_markers = { "ols.json", ".git" },
  lsp = { tool = "ols" },
  formatters = { "odinfmt" },
  debugger = c.debugger,
  notes = "Shares codelldb debugger config with C; see languages/c.lua.",
}
