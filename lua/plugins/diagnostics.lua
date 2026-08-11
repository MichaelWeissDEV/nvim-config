-- trouble.nvim: a nicer diagnostics/quickfix list. Loaded on first
-- <leader>xx or :Trouble; vim.diagnostic.* (config/diagnostics.lua) works
-- fully without it.
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local cmdreg = require("util.command_registry")

local function setup()
  lazyload.packadd("trouble.nvim")
  require("trouble").setup({})
end

local function toggle()
  vim.cmd("Trouble diagnostics toggle")
end

lazyload.on_key("n", "<leader>xx", "trouble.nvim", function()
  setup()
  vim.keymap.set("n", "<leader>xx", toggle, { desc = "Toggle diagnostics list (Trouble)", silent = true })
  toggle()
end, "Toggle diagnostics list (Trouble)")
km.document({ mode = "n", lhs = "<leader>xx", desc = "Toggle diagnostics list (Trouble)", group = "Diagnostics" })

lazyload.on_command("Trouble", "trouble.nvim", setup)
cmdreg.external({
  name = "Trouble",
  desc = "Open Trouble (diagnostics/quickfix/loclist list)",
  category = "Plugins",
  example = ":Trouble diagnostics toggle",
})
