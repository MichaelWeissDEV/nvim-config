---@type table
return {
  filetypes = { "csv", "tsv" },
  extensions = { ".csv", ".tsv" },
  treesitter = { "csv", "tsv" },
  root_markers = { ".git" },
  notes = "Handled by a lazy-loaded rainbow_csv plugin, not LSP tooling.",
}
