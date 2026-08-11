-- vimtex: only loaded for LaTeX buffers. vimtex configures itself mostly
-- via g:vimtex_* variables read at plugin-load time, so those are set
-- immediately before packadd rather than after.
local lazyload = require("config.lazyload")

lazyload.on_filetype({ "tex", "plaintex", "bib" }, "vimtex", function()
  vim.g.vimtex_view_method = "skim" -- macOS default; ignored on Linux/Windows without skim
  vim.g.vimtex_quickfix_mode = 0
  lazyload.packadd("vimtex")
end)
