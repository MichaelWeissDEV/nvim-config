-- render-markdown.nvim: only loaded for markdown buffers, never at startup.
local lazyload = require("config.lazyload")

lazyload.on_filetype({ "markdown" }, "render-markdown.nvim", function()
  lazyload.packadd("render-markdown.nvim")
  require("render-markdown").setup({})
end)
