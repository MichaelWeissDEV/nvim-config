---@type table
return {
  filetypes = { "julia" },
  extensions = { ".jl" },
  treesitter = { "julia" },
  root_markers = { "Project.toml", "JuliaProject.toml", ".git" },
  lsp = { tool = "julials" },
}
