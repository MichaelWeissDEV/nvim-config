---@type table
return {
  filetypes = { "make" },
  extensions = { ".mk" },
  treesitter = { "make" },
  root_markers = { "Makefile", ".git" },
  notes = "No LSP available for Makefiles; relies on Tree-sitter highlighting only.",
}
