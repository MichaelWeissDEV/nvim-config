---@type table
return {
  filetypes = { "crystal" },
  extensions = { ".cr" },
  root_markers = { "shard.yml", ".git" },
  lsp = { tool = "crystalline" },
  formatters = { "crystal" },
}
