---@type table
return {
  filetypes = { "jsonnet" },
  extensions = { ".jsonnet", ".libsonnet" },
  treesitter = { "jsonnet" },
  root_markers = { "jsonnetfile.json", ".git" },
  lsp = { tool = "jsonnet_ls" },
  formatters = { "jsonnetfmt" },
}
