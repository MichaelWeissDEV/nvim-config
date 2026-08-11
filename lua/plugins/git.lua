local km = require("util.keymap_registry")
local cmdreg = require("util.command_registry")

require("gitsigns").setup({
  signs = {
    add = { text = "│" },
    change = { text = "│" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    km.map_many({
      {
        mode = "n",
        lhs = "]h",
        rhs = function()
          gs.nav_hunk("next")
        end,
        desc = "Next git hunk",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "[h",
        rhs = function()
          gs.nav_hunk("prev")
        end,
        desc = "Previous git hunk",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>ghs",
        rhs = gs.stage_hunk,
        desc = "Stage hunk",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>ghr",
        rhs = gs.reset_hunk,
        desc = "Reset hunk",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>ghp",
        rhs = gs.preview_hunk,
        desc = "Preview hunk",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>gb",
        rhs = gs.blame_line,
        desc = "Blame line",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>gB",
        rhs = gs.toggle_current_line_blame,
        desc = "Toggle blame virtual text",
        group = "Git",
        context = "Git-tracked buffer",
        buffer = bufnr,
      },
    })
  end,
})

cmdreg.external({
  name = "Gitsigns",
  desc = "Gitsigns subcommands (staging, blame, hunks)",
  category = "Git",
  example = ":Gitsigns preview_hunk",
})
