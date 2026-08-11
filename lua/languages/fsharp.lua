---@type table
return {
  filetypes = { "fsharp" },
  extensions = { ".fs", ".fsx", ".fsi" },
  treesitter = { "fsharp" },
  root_markers = { ".fsproj", ".git" },
  lsp = { tool = "fsautocomplete" },
  formatters = { "dotnet_format" },
  notes = "root_markers here are literal names, not globs; vim.fs.find has no glob "
    .. "support, so F# project-root detection is approximate until a glob-aware "
    .. "root_markers mechanism exists.",
}
