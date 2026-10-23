---@type table
return {
  filetypes = { "wgsl" },
  extensions = { ".wgsl" },
  treesitter = { "wgsl" },
  root_markers = { ".git" },
  lsp = { tool = "wgsl_analyzer" },
}
