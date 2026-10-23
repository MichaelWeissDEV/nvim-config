local c = require("languages.c")

---@type table
return {
  filetypes = { "nim" },
  extensions = { ".nim", ".nims", ".nimble" },
  treesitter = { "nim" },
  root_markers = { "nim.cfg", ".git" },
  lsp = { tool = "nim_langserver" },
  formatters = { "nimpretty" },
  debugger = c.debugger,
  notes = "Shares codelldb debugger config with C; see languages/c.lua.",
}
