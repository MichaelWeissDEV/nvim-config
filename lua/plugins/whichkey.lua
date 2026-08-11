-- which-key.nvim: purely presentational. It shows whatever is already
-- registered via vim.keymap.set()/util.keymap_registry -- it never defines
-- a mapping itself, it only groups the leader-key popup.
local wk = require("which-key")

wk.setup({
  preset = "modern",
  win = { border = "rounded" },
})

wk.add({
  { "<leader>f", group = "Find" },
  { "<leader>b", group = "Buffer" },
  { "<leader>w", group = "Window" },
  { "<leader>g", group = "Git" },
  { "<leader>gh", group = "Git Hunk" },
  { "<leader>l", group = "LSP / Format" },
  { "<leader>d", group = "Debug" },
  { "<leader>t", group = "Tools" },
  { "<leader>u", group = "UI" },
  { "<leader>c", group = "Code" },
  { "<leader>x", group = "Diagnostics" },
  { "<leader>h", group = "Help / Docs" },
})
