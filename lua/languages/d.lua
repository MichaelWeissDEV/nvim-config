local c = require("languages.c")

---@type table
return {
  filetypes = { "d" },
  extensions = { ".d", ".di" },
  treesitter = { "d" },
  root_markers = { "dub.json", "dub.sdl", ".git" },
  lsp = { tool = "serve_d" },
  formatters = { "dfmt" },
  debugger = c.debugger,
  notes = "Shares codelldb debugger config with C; see languages/c.lua.",
}
