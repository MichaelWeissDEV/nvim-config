---@type table
return {
  filetypes = { "cmake" },
  extensions = { ".cmake" },
  treesitter = { "cmake" },
  root_markers = { "CMakeLists.txt", ".git" },
  lsp = { tool = "cmake_lsp" },
}
