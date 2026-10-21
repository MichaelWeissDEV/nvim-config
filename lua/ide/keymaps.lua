-- Everyday editor keymaps on top of config/keymaps.lua: saving, quitting,
-- moving lines. Kept separate because these are the "feels like an IDE"
-- additions, not Neovim basics.
local km = require("util.keymap_registry")

km.map_many({
  -- <C-s> in insert mode is Neovim's default for signature help; LSP
  -- buffers keep that on <C-k> (lsp/attach.lua), so saving wins here.
  {
    mode = { "n", "i", "x" },
    lhs = "<C-s>",
    rhs = "<cmd>write<cr><esc>",
    desc = "Save file",
    group = "File",
  },
  { mode = "n", lhs = "<leader>fn", rhs = "<cmd>enew<cr>", desc = "New empty buffer", group = "Find" },
  -- 'confirm' is on (config/options.lua): quitting with unsaved changes
  -- asks instead of failing or discarding.
  {
    mode = "n",
    lhs = "<leader>qq",
    rhs = "<cmd>qall<cr>",
    desc = "Quit all (asks about unsaved changes)",
    group = "Quit",
  },
  { mode = "n", lhs = "<leader>qw", rhs = "<cmd>wqall<cr>", desc = "Save all and quit", group = "Quit" },
  { mode = "n", lhs = "<leader>bb", rhs = "<cmd>buffer #<cr>", desc = "Switch to alternate buffer", group = "Buffer" },
  { mode = "n", lhs = "<leader>ba", rhs = "<cmd>wall<cr>", desc = "Save all buffers", group = "Buffer" },

  -- Move lines. <A-...> needs the terminal to send Option/Alt as Meta (iTerm2:
  -- "Esc+", Kitty/WezTerm/Ghostty: default; Terminal.app: "Use Option as Meta").
  { mode = "n", lhs = "<A-j>", rhs = "<cmd>move .+1<cr>==", desc = "Move line down", group = "Edit" },
  { mode = "n", lhs = "<A-k>", rhs = "<cmd>move .-2<cr>==", desc = "Move line up", group = "Edit" },
  { mode = "i", lhs = "<A-j>", rhs = "<esc><cmd>move .+1<cr>==gi", desc = "Move line down", group = "Edit" },
  { mode = "i", lhs = "<A-k>", rhs = "<esc><cmd>move .-2<cr>==gi", desc = "Move line up", group = "Edit" },
  { mode = "x", lhs = "<A-j>", rhs = ":move '>+1<cr>gv=gv", desc = "Move selection down", group = "Edit" },
  { mode = "x", lhs = "<A-k>", rhs = ":move '<-2<cr>gv=gv", desc = "Move selection up", group = "Edit" },

  -- Keep search results centered. Not silent: a silent mapping would hide
  -- the "[3/12]" search count and the "search hit BOTTOM" message.
  {
    mode = "n",
    lhs = "n",
    rhs = "nzzzv",
    desc = "Next search result, centered",
    group = "General",
    silent = false,
  },
  {
    mode = "n",
    lhs = "N",
    rhs = "Nzzzv",
    desc = "Previous search result, centered",
    group = "General",
    silent = false,
  },
})
