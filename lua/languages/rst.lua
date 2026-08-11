---@type table
return {
  filetypes = { "rst" },
  extensions = { ".rst" },
  treesitter = { "rst" },
  root_markers = { "conf.py", ".git" },
  -- esbonio's CLI requires an explicit subcommand ("server" for LSP mode,
  -- vs. "sphinx" for its build-wrapper mode) -- bare `esbonio` just prints
  -- usage and exits. Confirmed by actually running it, not assumed.
  lsp = { tool = "esbonio", extra = { cmd = { "esbonio", "server" } } },
  linters = { "doc8" },
}
