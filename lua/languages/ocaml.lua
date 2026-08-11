---@type table
return {
  filetypes = { "ocaml" },
  extensions = { ".ml", ".mli" },
  treesitter = { "ocaml", "ocaml_interface" },
  root_markers = { "dune-project", ".git" },
  lsp = { tool = "ocamllsp" },
  formatters = { "ocamlformat" },
}
