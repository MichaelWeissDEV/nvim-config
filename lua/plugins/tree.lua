-- nvim-tree.lua: sidebar file tree, the <leader>e experience. Loaded lazily
-- on first <leader>e / :NvimTreeToggle / :NvimTreeFindFile, same pattern as
-- every other opt plugin. Oil (buffer-as-directory editing) lives at
-- <leader>o and "-" instead -- see plugins/files.lua.
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local cmdreg = require("util.command_registry")

local function setup()
  lazyload.packadd("nvim-tree.lua")
  require("nvim-tree").setup({
    view = { width = 32, side = "left" },
    renderer = { group_empty = true },
    filters = { dotfiles = false, git_ignored = false },
    git = { enable = true },
    -- Keep the tree in sync with the actual editing buffer instead of a
    -- separate, driftable file list.
    update_focused_file = { enable = true },
  })
end

local function toggle()
  require("nvim-tree.api").tree.toggle({ find_file = true, focus = true })
end

lazyload.on_key("n", "<leader>e", "nvim-tree.lua", function()
  setup()
  vim.keymap.set("n", "<leader>e", toggle, { desc = "Toggle file explorer (nvim-tree)", silent = true })
  toggle()
end, "Toggle file explorer (nvim-tree)")
km.document({ mode = "n", lhs = "<leader>e", desc = "Toggle file explorer (nvim-tree)", group = "Find" })

lazyload.on_command({ "NvimTreeToggle", "NvimTreeFindFile", "NvimTreeOpen" }, "nvim-tree.lua", setup)
cmdreg.external({
  name = "NvimTreeToggle",
  desc = "Toggle the nvim-tree sidebar",
  category = "Plugins",
  example = ":NvimTreeToggle",
})
cmdreg.external({
  name = "NvimTreeFindFile",
  desc = "Open nvim-tree and reveal the current buffer's file",
  category = "Plugins",
  example = ":NvimTreeFindFile",
})

-- `nvim <a-directory>` (or `nvim .`): cd into it, same as Neovim's own
-- default behavior for a directory argument. Deliberately does NOT open
-- the tree -- the sidebar stays closed until you explicitly ask for it
-- (<leader>e / :NvimTreeToggle), matching this config's "quiet by
-- default, nothing visible until you ask" rule for every other opt
-- plugin. An earlier version auto-opened the tree here; removed by
-- request so a plain `nvim .` never shows a sidebar you didn't ask for.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("cd_to_dir_arg", { clear = true }),
  once = true,
  callback = function()
    if vim.fn.argc() ~= 1 then
      return
    end
    local arg = vim.fn.argv(0) --[[@as string]]
    if vim.fn.isdirectory(arg) == 1 then
      vim.cmd.cd(arg)
    end
  end,
})
