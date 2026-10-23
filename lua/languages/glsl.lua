---@type table
return {
  filetypes = { "glsl" },
  extensions = { ".glsl", ".vert", ".frag", ".geom", ".comp", ".tesc", ".tese" },
  treesitter = { "glsl" },
  root_markers = { ".git" },
  lsp = { tool = "glsl_analyzer" },
  formatters = { "clang_format" },
  linters = { "glslc" },
}
