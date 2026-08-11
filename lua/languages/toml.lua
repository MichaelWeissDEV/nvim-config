---@type table
return {
  filetypes = { "toml" },
  extensions = { ".toml" },
  treesitter = { "toml" },
  root_markers = { ".git" },
  -- taplo's LSP mode is a subcommand ("taplo lsp stdio"); the bare binary
  -- is a formatter/linter CLI (`taplo fmt`, `taplo check`), not a server.
  lsp = { tool = "taplo", extra = { cmd = { "taplo", "lsp", "stdio" } } },
  formatters = { "taplo" },
  notes = 'taplo is registered in tools.registry with category = "lsp" only; it\'s '
    .. "reused here as a formatter too since the same binary formats via `taplo fmt`, "
    .. "and consumers key off lang.lsp/lang.formatters, not the tool's category.",
}
