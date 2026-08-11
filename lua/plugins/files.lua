-- oil.nvim: file navigation as a buffer. Loaded on first <leader>e or :Oil.
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local cmdreg = require("util.command_registry")

local function setup()
  require("oil").setup({
    default_file_explorer = true,
    view_options = { show_hidden = true },
  })
end

local function open()
  vim.cmd.Oil()
end

lazyload.on_key("n", "<leader>e", "oil.nvim", function()
  setup()
  vim.keymap.set("n", "<leader>e", open, { desc = "Open file explorer (Oil)", silent = true })
  open()
end, "Open file explorer (Oil)")

km.document({ mode = "n", lhs = "<leader>e", desc = "Open file explorer (Oil)", group = "Find" })

lazyload.on_command("Oil", "oil.nvim", setup)
cmdreg.external({ name = "Oil", desc = "Open Oil file explorer", category = "Plugins", example = ":Oil" })
