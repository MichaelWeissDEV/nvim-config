-- Meta-commands for discovering the config itself: health, own commands,
-- own keymaps, and local documentation. Feature commands (Format*, Lsp*,
-- Tools*, Debugger*) are registered next to their feature in plugins/,
-- lsp/, tools/ and dap/ -- all through the same util.command_registry so
-- they all show up in :NvimCommands regardless of where they're defined.
local cmdreg = require("util.command_registry")
local km = require("util.keymap_registry")
local scratch = require("util.scratch")
local platform = require("util.platform")

cmdreg.command({
  name = "NvimConfigHealth",
  desc = "Run the structured health report for this config (alias for :checkhealth nvim-config)",
  category = "Diagnostics",
  example = ":NvimConfigHealth",
  fn = function()
    vim.cmd("checkhealth nvim-config")
  end,
})

cmdreg.command({
  name = "NvimCommands",
  desc = "List every command this config defines, grouped by category",
  category = "Documentation",
  example = ":NvimCommands",
  fn = function()
    local lines = { "# nvim-config: Commands", "" }
    local last_category = nil
    for _, c in ipairs(cmdreg.all()) do
      if c.category ~= last_category then
        table.insert(lines, "")
        table.insert(lines, "## " .. c.category)
        table.insert(lines, "")
        last_category = c.category
      end
      local head = ":" .. c.name .. (c.args and (" " .. c.args) or "")
      table.insert(lines, string.format("- `%s` -- %s", head, c.desc))
      if c.example then
        table.insert(lines, "  - example: `" .. c.example .. "`")
      end
    end
    scratch.open("nvim-config://commands", lines)
  end,
})

cmdreg.command({
  name = "NvimKeymaps",
  desc = "List every keymap this config defines, grouped by group",
  category = "Documentation",
  example = ":NvimKeymaps",
  fn = function()
    local lines = { "# nvim-config: Keymaps", "" }
    local last_group = nil
    for _, k in ipairs(km.all()) do
      if k.group ~= last_group then
        table.insert(lines, "")
        table.insert(lines, "## " .. k.group)
        table.insert(lines, "")
        last_group = k.group
      end
      local mode = type(k.mode) == "table" and table.concat(k.mode, ",") or k.mode
      table.insert(lines, string.format("- `%-4s` `%-18s` %s _(%s)_", mode, k.lhs, k.desc, k.context))
    end
    scratch.open("nvim-config://keymaps", lines)
  end,
})

cmdreg.command({
  name = "NvimDocs",
  desc = "Open local documentation: built Sphinx HTML if available, else :help nvim-config",
  category = "Documentation",
  example = ":NvimDocs",
  fn = function()
    local index = vim.fs.joinpath(platform.config_dir, "docs", "_build", "html", "index.html")
    if vim.uv.fs_stat(index) then
      local ok = pcall(vim.ui.open, index)
      if ok then
        return
      end
    end
    vim.cmd("help nvim-config")
  end,
})

cmdreg.command({
  name = "RelativeNumbersToggle",
  desc = "Toggle relative/absolute line numbers in the current window",
  category = "UI",
  example = ":RelativeNumbersToggle",
  fn = function()
    vim.wo.relativenumber = not vim.wo.relativenumber
  end,
})

km.map({
  mode = "n",
  lhs = "<leader>hd",
  rhs = "<cmd>NvimDocs<cr>",
  desc = "Open documentation",
  group = "Help",
})
km.map({
  mode = "n",
  lhs = "<leader>hc",
  rhs = "<cmd>NvimCommands<cr>",
  desc = "List commands",
  group = "Help",
})
km.map({
  mode = "n",
  lhs = "<leader>hk",
  rhs = "<cmd>NvimKeymaps<cr>",
  desc = "List keymaps",
  group = "Help",
})
km.map({
  mode = "n",
  lhs = "<leader>hh",
  rhs = "<cmd>NvimConfigHealth<cr>",
  desc = "Run health check",
  group = "Help",
})
