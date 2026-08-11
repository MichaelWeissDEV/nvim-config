-- "Plugins" section of :checkhealth nvim-config: just confirms every
-- vendored plugin directory this config expects is actually present under
-- pack/vendor/{start,opt} -- catches an incomplete clone/checkout, not a
-- missing external tool (that's tools/status.lua's job).
local platform = require("util.platform")

local M = {}

local START = {
  "plenary.nvim",
  "nvim-web-devicons",
  "catppuccin",
  "nvim-treesitter",
  "nvim-cmp",
  "cmp-nvim-lsp",
  "cmp-buffer",
  "cmp-path",
  "LuaSnip",
  "cmp_luasnip",
  "friendly-snippets",
  "gitsigns.nvim",
  "lualine.nvim",
  "which-key.nvim",
  "mason.nvim",
  "conform.nvim",
  "nvim-lint",
  "nvim-autopairs",
  "nvim-surround",
}

local OPT = {
  "telescope.nvim",
  "nvim-tree.lua",
  "oil.nvim",
  "trouble.nvim",
  "render-markdown.nvim",
  "vimtex",
  "rainbow_csv",
  "nvim-dap",
  "nvim-dap-ui",
  "nvim-nio",
}

local function check_dir(base, name)
  local path = vim.fs.joinpath(platform.config_dir, "pack", "vendor", base, name)
  if vim.uv.fs_stat(path) then
    vim.health.ok(name)
  else
    vim.health.error(
      name .. " missing from pack/vendor/" .. base,
      "Repository checkout is incomplete; see scripts/plugin-status.sh"
    )
  end
end

function M.check()
  vim.health.start("Plugins (start)")
  for _, name in ipairs(START) do
    check_dir("start", name)
  end
  vim.health.start("Plugins (opt, lazy-loaded)")
  for _, name in ipairs(OPT) do
    check_dir("opt", name)
  end
end

M.START = START
M.OPT = OPT

return M
