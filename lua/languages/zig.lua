---@type table
return {
  filetypes = { "zig" },
  extensions = { ".zig" },
  treesitter = { "zig" },
  root_markers = { "build.zig", ".git" },
  lsp = { tool = "zls" },
  notes = "zig fmt ships with the zig compiler itself, not a standalone tools.registry entry.",
}
