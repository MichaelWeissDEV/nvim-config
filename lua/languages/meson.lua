---@type table
return {
  filetypes = { "meson" },
  extensions = { "meson.build", "meson_options.txt" },
  treesitter = { "meson" },
  root_markers = { "meson.build", ".git" },
  lsp = { tool = "mesonlsp", extra = { cmd = { "mesonlsp", "--lsp" } } },
  formatters = { "meson" },
}
