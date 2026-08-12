-- Two complementary Git layers, deliberately not one:
--
--   gitsigns.nvim (start) -- the always-on, in-buffer layer: signs in the
--   gutter, hunk navigation, stage/reset/preview a hunk, inline blame.
--   Cheap enough to always load, and useless if it isn't.
--
--   vim-fugitive (opt) -- the full porcelain: :Git status/commit/push,
--   :Gdiffsplit three-way merges, :Git blame, :Git log. A whole Git UI,
--   only worth loading the moment you actually run a Git command.
--
-- gitsigns handles "what changed in this file", fugitive handles "operate
-- on the repository". Neither replaces the other.
local km = require("util.keymap_registry")
local cmdreg = require("util.command_registry")
local lazyload = require("config.lazyload")

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

-- vim-fugitive: loaded on the first Git command or <leader>g keymap.
-- Fugitive is a Vimscript plugin that defines its commands in plugin/, so
-- unlike the Lua plugins here there is no setup() to call -- packadd is
-- the whole activation.
local function load_fugitive()
  lazyload.packadd("vim-fugitive")
end

lazyload.on_command({
  "Git",
  "G",
  "Gdiffsplit",
  "Gvdiffsplit",
  "Gread",
  "Gwrite",
  "Gedit",
  "GBrowse",
  "Gclog",
  "Glgrep",
}, "vim-fugitive", load_fugitive)

-- These are ordinary keymaps, NOT lazyload.on_key: that helper shares one
-- once-guard per plugin name, so the first key pressed would load fugitive
-- and the *others* would then hit the already-fired guard and silently do
-- nothing. lazyload.packadd() is itself idempotent, so calling it on every
-- press is both correct and cheap -- the plugin still loads exactly once,
-- on first use, which is the property that actually matters.
for _, spec in ipairs({
  { lhs = "<leader>gg", cmd = "Git", desc = "Git status (fugitive)" },
  { lhs = "<leader>gc", cmd = "Git commit", desc = "Git commit" },
  { lhs = "<leader>gp", cmd = "Git push", desc = "Git push" },
  { lhs = "<leader>gP", cmd = "Git pull", desc = "Git pull" },
  { lhs = "<leader>gd", cmd = "Gvdiffsplit", desc = "Git diff against index (split)" },
  { lhs = "<leader>gl", cmd = "Git log --oneline --decorate --graph", desc = "Git log (graph)" },
}) do
  km.map({
    mode = "n",
    lhs = spec.lhs,
    rhs = function()
      load_fugitive()
      vim.cmd(spec.cmd)
    end,
    desc = spec.desc,
    group = "Git",
  })
end

cmdreg.external({
  name = "Git",
  desc = "Run any git command through vim-fugitive; bare :Git opens the interactive status buffer",
  category = "Git",
  args = "[git-subcommand]",
  example = ":Git blame",
})
cmdreg.external({
  name = "Gvdiffsplit",
  desc = "Open a vertical three-way diff of the current file against the index (fugitive)",
  category = "Git",
  example = ":Gvdiffsplit",
})
