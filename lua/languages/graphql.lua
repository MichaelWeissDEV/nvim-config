---@type table
return {
  filetypes = { "graphql" },
  extensions = { ".graphql", ".gql" },
  treesitter = { "graphql" },
  root_markers = { ".graphqlrc", ".git" },
  lsp = { tool = "graphql_lsp" },
  formatters = { "prettier" },
}
