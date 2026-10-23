---@type table
return {
  filetypes = { "cue" },
  extensions = { ".cue" },
  treesitter = { "cue" },
  root_markers = { "cue.mod", ".git" },
  lsp = { tool = "cue", extra = { cmd = { "cue", "lsp" } } },
  formatters = { "cue_fmt" },
  linters = { "cue" },
}
