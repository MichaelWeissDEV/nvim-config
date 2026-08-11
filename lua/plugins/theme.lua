require("catppuccin").setup({
  flavour = "mocha",
  integrations = {
    cmp = true,
    gitsigns = true,
    telescope = true,
    treesitter = true,
    which_key = true,
    mason = true,
    dap = true,
    dap_ui = true,
    native_lsp = { enabled = true },
  },
})

vim.cmd.colorscheme("catppuccin")
