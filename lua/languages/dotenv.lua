---@type table
return {
  filetypes = { "dotenv" },
  extensions = { ".env" },
  root_markers = { ".git" },
  linters = { "dotenv_linter" },
}
