---@type table
return {
  filetypes = { "tex", "plaintex", "bib" },
  extensions = { ".tex", ".bib" },
  treesitter = { "latex", "bibtex" },
  root_markers = { ".git" },
  lsp = { tool = "texlab" },
  formatters = { "latexindent" },
  linters = { "chktex" },
  notes = "Editor integration (folding, TOC, forward/inverse search) is provided by the "
    .. "lazy-loaded vimtex plugin, triggered on filetype tex/plaintex -- see plugins/latex.lua.",
}
