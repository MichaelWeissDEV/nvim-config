---@type table
return {
  filetypes = { "vim" },
  extensions = { ".vim" },
  treesitter = { "vim", "vimdoc" },
  root_markers = { ".git" },
  lsp = { tool = "vimls", extra = { cmd = { "vim-language-server", "--stdio" } } },
  linters = { "vint" },
}
