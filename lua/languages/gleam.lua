---@type table
return {
  filetypes = { "gleam" },
  extensions = { ".gleam" },
  treesitter = { "gleam" },
  root_markers = { "gleam.toml", ".git" },
  lsp = { tool = "gleam", extra = { cmd = { "gleam", "lsp" } } },
  formatters = { "gleam" },
  notes = "`gleam lsp` and `gleam format` ship with the Gleam compiler binary.",
}
