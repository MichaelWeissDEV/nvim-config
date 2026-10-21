-- trouble.nvim: a nicer diagnostics/quickfix/symbols list. Loaded on the
-- first <leader>x* Trouble key or :Trouble; vim.diagnostic.*
-- (config/diagnostics.lua) works fully without it.
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local cmdreg = require("util.command_registry")

local function setup()
  lazyload.packadd("trouble.nvim")
  require("trouble").setup({})
end

-- Ordinary keymaps calling a shared once-guard, not lazyload.on_key: that
-- helper's guard is per plugin, so with several trigger keys only the
-- first pressed would have worked (see the same note in plugins/git.lua).
for _, spec in ipairs({
  { lhs = "<leader>xx", cmd = "diagnostics toggle", desc = "Diagnostics list, all buffers (Trouble)" },
  { lhs = "<leader>xX", cmd = "diagnostics toggle filter.buf=0", desc = "Diagnostics list, this buffer (Trouble)" },
  { lhs = "<leader>xs", cmd = "symbols toggle focus=false", desc = "Symbols outline (Trouble)" },
  {
    lhs = "<leader>xr",
    cmd = "lsp toggle focus=false win.position=right",
    desc = "LSP definitions/references (Trouble)",
  },
  { lhs = "<leader>xQ", cmd = "qflist toggle", desc = "Quickfix list (Trouble)" },
}) do
  km.map({
    mode = "n",
    lhs = spec.lhs,
    rhs = function()
      if lazyload.now("trouble.nvim", setup) then
        vim.cmd("Trouble " .. spec.cmd)
      end
    end,
    desc = spec.desc,
    group = "Diagnostics",
  })
end

lazyload.on_command("Trouble", "trouble.nvim", setup)
cmdreg.external({
  name = "Trouble",
  desc = "Open Trouble (diagnostics/quickfix/loclist list)",
  category = "Plugins",
  example = ":Trouble diagnostics toggle",
})
