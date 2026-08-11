-- Telescope loads lazily: the first press of any <leader>f* key or
-- :Telescope packadds it, calls setup() once, and then dispatches straight
-- to the requested picker (no feedkeys indirection needed since we already
-- know exactly which action was requested).
local km = require("util.keymap_registry")
local lazyload = require("config.lazyload")
local notify = require("util.notify")
local exe = require("util.executable")
local cmdreg = require("util.command_registry")

local ready = false

local function ensure()
  lazyload.packadd("telescope.nvim")
  if not ready then
    require("telescope").setup({
      defaults = {
        prompt_prefix = "  ",
        selection_caret = " ",
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        -- No `fd`/`rg` on PATH just means Telescope's own fallback finder
        -- (vim.fn.glob-based) is used instead -- not an error.
      },
    })
    ready = true
  end
end

local function builtin(name)
  return function()
    ensure()
    require("telescope.builtin")[name]()
  end
end

local function live_grep()
  ensure()
  if not exe.exists("rg") then
    notify.once(
      "telescope-rg-missing",
      "Telescope live_grep needs ripgrep ('rg'); falling back to grep_string.",
      vim.log.levels.WARN
    )
    require("telescope.builtin").grep_string({ search = vim.fn.input("Grep for: ") })
    return
  end
  require("telescope.builtin").live_grep()
end

local function git_files()
  ensure()
  local ok = pcall(require("telescope.builtin").git_files)
  if not ok then
    notify.once("telescope-not-git", "Not inside a git repository; showing all files instead.", vim.log.levels.INFO)
    require("telescope.builtin").find_files()
  end
end

km.map_many({
  { mode = "n", lhs = "<leader>ff", rhs = builtin("find_files"), desc = "Find files", group = "Find" },
  { mode = "n", lhs = "<leader>fg", rhs = live_grep, desc = "Live grep", group = "Find" },
  { mode = "n", lhs = "<leader>fb", rhs = builtin("buffers"), desc = "Find buffers", group = "Find" },
  { mode = "n", lhs = "<leader>fr", rhs = builtin("oldfiles"), desc = "Recent files", group = "Find" },
  { mode = "n", lhs = "<leader>fh", rhs = builtin("help_tags"), desc = "Help tags", group = "Find" },
  { mode = "n", lhs = "<leader>fk", rhs = builtin("keymaps"), desc = "Keymaps (all of Neovim's)", group = "Find" },
  { mode = "n", lhs = "<leader>fc", rhs = builtin("commands"), desc = "Commands (all of Neovim's)", group = "Find" },
  { mode = "n", lhs = "<leader>fd", rhs = builtin("diagnostics"), desc = "Diagnostics", group = "Find" },
  { mode = "n", lhs = "<leader>fs", rhs = builtin("lsp_document_symbols"), desc = "Document symbols", group = "Find" },
  { mode = "n", lhs = "<leader>fG", rhs = git_files, desc = "Git files", group = "Find" },
})

lazyload.on_command("Telescope", "telescope", ensure)
cmdreg.external({
  name = "Telescope",
  desc = "Open a Telescope picker by name",
  category = "Plugins",
  args = "<picker>",
  example = ":Telescope find_files",
})
