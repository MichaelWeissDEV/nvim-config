local js = require("languages.javascript")

---@type table
return {
  filetypes = { "typescript", "typescriptreact" },
  extensions = { ".ts", ".tsx" },
  treesitter = { "typescript", "tsx" },
  root_markers = js.root_markers,
  lsp = js.lsp,
  formatters = js.formatters,
  linters = js.linters,
  debugger = js.debugger,
  notes = "Shares vtsls/prettier/eslint/js-debug-adapter config with JavaScript; see languages/javascript.lua.",
}
