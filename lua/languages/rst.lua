---@type table
return {
  filetypes = { "rst" },
  extensions = { ".rst" },
  treesitter = { "rst" },
  root_markers = { "conf.py", ".git" },
  lsp = { tool = "esbonio" },
  linters = { "doc8" },
}
