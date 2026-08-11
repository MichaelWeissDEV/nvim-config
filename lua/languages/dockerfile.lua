---@type table
return {
  filetypes = { "dockerfile" },
  extensions = { ".dockerfile" },
  treesitter = { "dockerfile" },
  root_markers = { ".git" },
  lsp = { tool = "dockerls", extra = { cmd = { "docker-langserver", "--stdio" } } },
  linters = { "hadolint" },
}
