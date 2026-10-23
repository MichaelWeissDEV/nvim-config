---@type table
return {
  filetypes = { "helm" },
  extensions = { ".tpl" },
  treesitter = { "helm" },
  root_markers = { "Chart.yaml", ".git" },
  lsp = { tool = "helm_ls", extra = { cmd = { "helm_ls", "serve" } } },
}
