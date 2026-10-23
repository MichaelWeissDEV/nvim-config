local c = require("languages.c")

---@type table
return {
  filetypes = { "swift" },
  extensions = { ".swift" },
  treesitter = { "swift" },
  root_markers = { "Package.swift", "Podfile", ".git" },
  lsp = { tool = "sourcekit_lsp" },
  formatters = { "swiftformat" },
  linters = { "swiftlint" },
  debugger = c.debugger,
  notes = "sourcekit-lsp ships with the Swift toolchain / Xcode; shares codelldb debugger config with C.",
}
