-- The only runtime responsibility left here (LSP/formatters/linters/DAP
-- already read languages.registry directly from lsp/, plugins/formatting.lua,
-- plugins/linting.lua and dap/registry.lua): apply each language's optional
-- buffer-local `keymaps` function the first time its filetype is opened.
local registry = require("languages.registry")

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("languages_keymaps", { clear = true }),
  callback = function(args)
    local lang = registry.by_filetype(vim.bo[args.buf].filetype)
    if lang and lang.keymaps then
      lang.keymaps(args.buf)
    end
  end,
})
