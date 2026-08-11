-- General, always-available keymaps. Feature-specific keymaps (LSP, DAP,
-- Telescope, ...) live next to the code that owns them and register through
-- the same util.keymap_registry so they all end up in one place.
local km = require("util.keymap_registry")

-- Window navigation
km.map_many({
  { mode = "n", lhs = "<C-h>", rhs = "<C-w>h", desc = "Go to left window", group = "Window" },
  { mode = "n", lhs = "<C-j>", rhs = "<C-w>j", desc = "Go to lower window", group = "Window" },
  { mode = "n", lhs = "<C-k>", rhs = "<C-w>k", desc = "Go to upper window", group = "Window" },
  { mode = "n", lhs = "<C-l>", rhs = "<C-w>l", desc = "Go to right window", group = "Window" },
  { mode = "n", lhs = "<leader>wv", rhs = "<cmd>vsplit<cr>", desc = "Split window vertically", group = "Window" },
  { mode = "n", lhs = "<leader>ws", rhs = "<cmd>split<cr>", desc = "Split window horizontally", group = "Window" },
  { mode = "n", lhs = "<leader>wc", rhs = "<cmd>close<cr>", desc = "Close window", group = "Window" },
  { mode = "n", lhs = "<leader>we", rhs = "<C-w>=", desc = "Equalize window sizes", group = "Window" },
})

-- Buffers
km.map_many({
  { mode = "n", lhs = "<S-h>", rhs = "<cmd>bprevious<cr>", desc = "Previous buffer", group = "Buffer" },
  { mode = "n", lhs = "<S-l>", rhs = "<cmd>bnext<cr>", desc = "Next buffer", group = "Buffer" },
  -- opt.confirm = true means :bdelete on a modified buffer prompts instead
  -- of silently discarding changes.
  { mode = "n", lhs = "<leader>bd", rhs = "<cmd>bdelete<cr>", desc = "Delete buffer", group = "Buffer" },
  {
    mode = "n",
    lhs = "<leader>bo",
    rhs = function()
      local current = vim.api.nvim_get_current_buf()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current and vim.bo[buf].buflisted then
          vim.cmd.bdelete(buf)
        end
      end
    end,
    desc = "Close other buffers",
    group = "Buffer",
  },
})

-- UI toggles
km.map_many({
  {
    mode = "n",
    lhs = "<leader>un",
    rhs = function()
      vim.wo.relativenumber = not vim.wo.relativenumber
    end,
    desc = "Toggle relative/absolute line numbers",
    group = "UI",
  },
  {
    mode = "n",
    lhs = "<leader>uN",
    rhs = function()
      vim.wo.number = not vim.wo.number
      vim.wo.relativenumber = false
    end,
    desc = "Toggle line numbers on/off",
    group = "UI",
  },
  {
    mode = "n",
    lhs = "<leader>uw",
    rhs = function()
      vim.wo.wrap = not vim.wo.wrap
    end,
    desc = "Toggle line wrap",
    group = "UI",
  },
  {
    mode = "n",
    lhs = "<leader>ul",
    rhs = function()
      vim.wo.list = not vim.wo.list
    end,
    desc = "Toggle whitespace display",
    group = "UI",
  },
})

-- Misc editing
km.map_many({
  { mode = "n", lhs = "<Esc>", rhs = "<cmd>nohlsearch<cr>", desc = "Clear search highlight", group = "General" },
  { mode = { "n", "v" }, lhs = "<leader>y", rhs = '"+y', desc = "Yank to system clipboard", group = "General" },
  { mode = "n", lhs = "<leader>Y", rhs = '"+Y', desc = "Yank line to system clipboard", group = "General" },
  { mode = "v", lhs = "<", rhs = "<gv", desc = "Indent left, keep selection", group = "General" },
  { mode = "v", lhs = ">", rhs = ">gv", desc = "Indent right, keep selection", group = "General" },
  { mode = "n", lhs = "<C-d>", rhs = "<C-d>zz", desc = "Half-page down, centered", group = "General" },
  { mode = "n", lhs = "<C-u>", rhs = "<C-u>zz", desc = "Half-page up, centered", group = "General" },
})
