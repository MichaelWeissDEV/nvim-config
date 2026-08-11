-- nvim-treesitter (main branch, requires Neovim 0.12+). This plugin
-- explicitly does not support lazy-loading (see its README), so it lives
-- in pack/vendor/start and is always sourced.
--
-- No parsers are bundled or auto-installed: Neovim itself ships c, lua,
-- markdown, markdown_inline, query, vim, vimdoc. Anything else needs an
-- explicit `:TSInstall <lang>` -- the one deliberate exception to "no
-- network at runtime" in this whole config, and it's opt-in by name. See
-- docs/offline.rst.
require("nvim-treesitter").setup({})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
  callback = function(args)
    -- pcall: silently no-op for filetypes with no parser installed --
    -- that's the whole point, no error for a missing optional component.
    pcall(vim.treesitter.start, args.buf)
  end,
})

require("util.command_registry").external({
  name = "TSInstall",
  desc = "Install a Tree-sitter parser (network; explicit action only)",
  category = "Plugins",
  args = "<language>",
  example = ":TSInstall rust",
})
require("util.command_registry").external({
  name = "TSUpdate",
  desc = "Update installed Tree-sitter parsers (network; explicit action only)",
  category = "Plugins",
  example = ":TSUpdate",
})
