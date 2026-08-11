---@type table
return {
  filetypes = { "sql" },
  extensions = { ".sql" },
  treesitter = { "sql" },
  root_markers = { ".git" },
  lsp = { tool = "sqls" },
  formatters = { "sqlfluff" },
  linters = { "sqlfluff_lint" },
  notes = "No automatic database connection is ever established.",
}
