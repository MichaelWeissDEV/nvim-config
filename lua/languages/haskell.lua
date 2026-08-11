---@type table
return {
  filetypes = { "haskell" },
  extensions = { ".hs" },
  treesitter = { "haskell" },
  root_markers = { "stack.yaml", "cabal.project", ".git" },
  lsp = { tool = "haskell_language_server" },
  formatters = { "fourmolu" },
  linters = { "hlint" },
  notes = "`*.cabal` files also mark a root but vim.fs.find has no glob support; "
    .. "stack.yaml/cabal.project/.git cover the common cases.",
}
