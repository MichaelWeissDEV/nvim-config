---@type table
return {
  filetypes = { "erlang" },
  extensions = { ".erl", ".hrl" },
  treesitter = { "erlang" },
  root_markers = { "rebar.config", ".git" },
  lsp = { tool = "erlang_ls" },
}
