-- oil.nvim: file navigation as a buffer (edit a directory listing like any
-- other buffer -- rename/delete/create by editing text, then :w). Secondary
-- to the nvim-tree sidebar (plugins/tree.lua, <leader>e): Oil lives at
-- <leader>o and the classic oil convention "-" (open the parent directory
-- of the current file), and still owns :Oil / default_file_explorer, so
-- `:edit some/dir` after Oil has loaded once still opens an Oil buffer.
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local cmdreg = require("util.command_registry")

local function setup()
  lazyload.packadd("oil.nvim")
  require("oil").setup({
    default_file_explorer = true,
    view_options = { show_hidden = true },
  })
end

local function open()
  vim.cmd.Oil()
end

-- Both trigger keys share one once-guard ("oil.nvim"): whichever is
-- pressed first runs setup() and rebinds BOTH keys to the real `open`
-- action, so the second key works correctly too, not just the one that
-- happened to trigger loading.
local function first_use()
  setup()
  vim.keymap.set("n", "<leader>o", open, { desc = "Open file explorer (Oil)", silent = true })
  vim.keymap.set("n", "-", open, { desc = "Open parent directory (Oil)", silent = true })
  open()
end

lazyload.on_key("n", "<leader>o", "oil.nvim", first_use, "Open file explorer (Oil)")
km.document({ mode = "n", lhs = "<leader>o", desc = "Open file explorer (Oil)", group = "Find" })

lazyload.on_key("n", "-", "oil.nvim", first_use, "Open parent directory (Oil)")
km.document({ mode = "n", lhs = "-", desc = "Open parent directory (Oil)", group = "Find" })

lazyload.on_command("Oil", "oil.nvim", setup)
cmdreg.external({ name = "Oil", desc = "Open Oil file explorer", category = "Plugins", example = ":Oil" })
