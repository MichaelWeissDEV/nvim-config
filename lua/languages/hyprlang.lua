---@type table
return {
  filetypes = { "hyprlang" },
  extensions = { ".conf" },
  treesitter = { "hyprlang" },
  root_markers = { "hyprland.conf", ".git" },
  lsp = { tool = "hyprls" },
}
