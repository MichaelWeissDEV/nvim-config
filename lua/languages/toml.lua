---@type table
return {
  filetypes = { "toml" },
  extensions = { ".toml" },
  treesitter = { "toml" },
  root_markers = { ".git" },
  lsp = { tool = "taplo" },
  formatters = { "taplo" },
  notes = "taplo is registered in tools.registry with category = \"lsp\" only; it's "
    .. "reused here as a formatter too since the same binary formats via `taplo fmt`, "
    .. "and consumers key off lang.lsp/lang.formatters, not the tool's category.",
}
