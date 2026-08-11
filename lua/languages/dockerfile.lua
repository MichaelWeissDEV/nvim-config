---@type table
return {
  filetypes = { "dockerfile" },
  extensions = { ".dockerfile" },
  treesitter = { "dockerfile" },
  root_markers = { ".git" },
  lsp = { tool = "dockerls" },
  linters = { "hadolint" },
}
