---@type table
return {
  filetypes = { "elixir", "eex", "heex" },
  extensions = { ".ex", ".exs", ".eex", ".heex" },
  treesitter = { "elixir", "eex", "heex" },
  root_markers = { "mix.exs", ".git" },
  lsp = { tool = "elixir_ls" },
  linters = { "credo" },
}
