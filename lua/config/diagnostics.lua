-- Global diagnostic presentation + navigation. Independent of which LSP (if
-- any) produced the diagnostics, so these keymaps work even for buffers with
-- no language server attached (e.g. linter-only diagnostics via nvim-lint).
local km = require("util.keymap_registry")

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    spacing = 2,
    source = "if_many",
    prefix = "●",
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
  float = {
    border = "rounded",
    source = true,
  },
})

km.map_many({
  {
    mode = "n",
    lhs = "[d",
    rhs = function()
      vim.diagnostic.jump({ count = -1, float = true })
    end,
    desc = "Previous diagnostic",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "]d",
    rhs = function()
      vim.diagnostic.jump({ count = 1, float = true })
    end,
    desc = "Next diagnostic",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xl",
    rhs = vim.diagnostic.open_float,
    desc = "Line diagnostics (float)",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xq",
    rhs = function()
      vim.diagnostic.setqflist({ open = true })
    end,
    desc = "Diagnostics to quickfix",
    group = "Diagnostics",
  },
})
