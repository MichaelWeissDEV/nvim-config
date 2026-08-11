---@type table
return {
  filetypes = { "proto" },
  extensions = { ".proto" },
  treesitter = { "proto" },
  root_markers = { "buf.yaml", "buf.gen.yaml", ".git" },
  lsp = { tool = "buf" },
}
