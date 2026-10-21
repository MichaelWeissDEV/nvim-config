-- render-markdown.nvim: in-editor rendering of headings, tables, code
-- blocks, checkboxes. OFF by default -- markdown opens as the plain text it
-- is, with ordinary Tree-sitter highlighting and no concealment. Rendering
-- is one keypress away (<leader>um / :MarkdownRender) and only then is the
-- plugin loaded at all.
--
-- To get the previous "always render" behaviour back, set
--   vim.g.nvim_config_markdown_render = true
-- in lua/config/local.lua; markdown buffers then render as they open.
local km = require("util.keymap_registry")
local cmdreg = require("util.command_registry")
local lazyload = require("config.lazyload")

local M = {}

local function load()
  return lazyload.now("render-markdown.nvim", function()
    -- The plugin's own plugin/ script calls setup(vim.g.render_markdown_config)
    -- during packadd, and attaches to the current buffer right then. Handing
    -- the config over through that variable (rather than a setup() call
    -- afterwards) means the very first buffer is attached with our config,
    -- not the defaults.
    vim.g.render_markdown_config = {
      enabled = true,
      file_types = { "markdown" },
      -- Show the raw text of the line under the cursor, so editing a
      -- rendered line never means editing something you cannot see.
      anti_conceal = { enabled = true },
    }
    lazyload.packadd("render-markdown.nvim")
    -- During packadd the plugin attaches only to the current buffer (its
    -- FileType autocmd only sees buffers opened later). Replay its own
    -- FileType handler for every markdown buffer that is already loaded,
    -- so the toggle renders all of them, not just the one it was pressed in.
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
        vim.api.nvim_exec_autocmds("FileType", { group = "RenderMarkdown", buffer = buf, modeline = false })
      end
    end
  end)
end

--- Is rendering currently on? False whenever the plugin has not been loaded.
--- @return boolean
function M.enabled()
  if not package.loaded["render-markdown"] then
    return false
  end
  return require("render-markdown").get()
end

--- Switch rendering on or off for every markdown buffer.
--- @param enable boolean|nil nil toggles
--- @return boolean enabled the state it is in now
function M.set(enable)
  if enable == nil then
    enable = not M.enabled()
  end
  if not enable and not package.loaded["render-markdown"] then
    -- Never loaded means nothing is rendered: "off" is already true, and
    -- loading the plugin just to switch it off would flash a render.
    vim.notify("Markdown rendering: off (plain text)")
    return false
  end
  if not load() then
    return false
  end
  require("render-markdown").set(enable)
  vim.notify("Markdown rendering: " .. (enable and "on" or "off (plain text)"))
  return enable
end

km.map({
  mode = "n",
  lhs = "<leader>um",
  rhs = function()
    M.set(nil)
  end,
  desc = "Toggle markdown rendering (off by default)",
  group = "UI",
})

cmdreg.command({
  name = "MarkdownRender",
  desc = "Toggle in-editor markdown rendering (render-markdown.nvim); 'on'/'off' to set explicitly",
  category = "UI",
  args = "[on|off]",
  example = ":MarkdownRender on",
  opts = {
    nargs = "?",
    complete = function()
      return { "on", "off" }
    end,
  },
  fn = function(opts)
    local arg = opts.args
    if arg == "on" then
      M.set(true)
    elseif arg == "off" then
      M.set(false)
    elseif arg == "" then
      M.set(nil)
    else
      vim.notify("MarkdownRender: expected 'on', 'off' or nothing, got '" .. arg .. "'", vim.log.levels.ERROR)
    end
  end,
})

-- Opt-in auto-render. Read at FileType time rather than at module load so
-- lua/config/local.lua (loaded before plugins) and a later `:let` both work.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = vim.api.nvim_create_augroup("nvim_config_markdown_autorender", { clear = true }),
  callback = function()
    if vim.g.nvim_config_markdown_render == true and not package.loaded["render-markdown"] then
      load()
    end
  end,
})

return M
