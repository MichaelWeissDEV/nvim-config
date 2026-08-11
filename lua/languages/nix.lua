---@type table
return {
  filetypes = { "nix" },
  extensions = { ".nix" },
  treesitter = { "nix" },
  root_markers = { "flake.nix", ".git" },
  lsp = { tool = "nixd" },
  formatters = { "nixfmt" },
  linters = { "statix" },
}
