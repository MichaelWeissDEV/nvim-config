---@type table
return {
  filetypes = { "rego" },
  extensions = { ".rego" },
  treesitter = { "rego" },
  root_markers = { ".regal", ".git" },
  lsp = { tool = "regal", extra = { cmd = { "regal", "language-server" } } },
  formatters = { "opa_fmt" },
  linters = { "regal" },
}
