---@type table
return {
  filetypes = { "vhdl" },
  extensions = { ".vhd", ".vhdl" },
  treesitter = { "vhdl" },
  root_markers = { "vhdl_ls.toml", ".git" },
  lsp = { tool = "vhdl_ls" },
}
