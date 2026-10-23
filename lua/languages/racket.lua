---@type table
return {
  filetypes = { "racket", "scheme" },
  extensions = { ".rkt", ".scm", ".ss" },
  treesitter = { "racket", "scheme" },
  root_markers = { "info.rkt", ".git" },
  lsp = { tool = "racket_langserver", extra = { cmd = { "racket", "-l", "racket-langserver" } } },
  formatters = { "racketfmt" },
}
