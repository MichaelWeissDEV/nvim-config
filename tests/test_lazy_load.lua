-- Positive counterpart to test_startup.lua's "nothing loads eagerly":
-- confirm each trigger actually loads its plugin, exactly once, on demand.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")
local fixtures = this_dir .. "/fixtures"

lib.run("lazy load: triggers actually load their plugin", function()
  -- Markdown is plain text by default: opening a file must NOT load the
  -- renderer or conceal anything. Only the explicit toggle loads it.
  -- A second markdown buffer, opened BEFORE the plugin loads: the toggle
  -- must render it too, not only the buffer it was pressed in.
  local other_md = vim.fn.tempname() .. ".md"
  local f = assert(io.open(other_md, "w"))
  f:write("# Other\n\n- [ ] task\n")
  f:close()
  vim.cmd.edit(other_md)
  vim.cmd.edit(fixtures .. "/notes.md")
  vim.wait(200)
  lib.assert_true(package.loaded["render-markdown"] == nil, "render-markdown loaded just by opening a markdown buffer")
  lib.assert_eq(vim.wo.conceallevel, 0, "markdown buffer is concealed by default")

  local markdown = require("plugins.markdown")
  local calls, restore = lib.notify_spy()

  -- "off" while never loaded: nothing to switch off, so nothing is loaded.
  lib.assert_eq(markdown.set(false), false, "MarkdownRender off did not report off")
  lib.assert_true(package.loaded["render-markdown"] == nil, "MarkdownRender off loaded the plugin")

  lib.assert_eq(markdown.set(true), true, "MarkdownRender on did not report on")
  vim.wait(200)
  lib.assert_true(package.loaded["render-markdown"] ~= nil, "render-markdown did not load on the toggle")
  lib.assert_true(markdown.enabled(), "render-markdown loaded but is not enabled")
  lib.assert_true(vim.wo.conceallevel > 0, "rendering on, but the window is not concealing")

  vim.cmd.edit(other_md)
  vim.wait(200)
  lib.assert_true(vim.wo.conceallevel > 0, "a markdown buffer opened before the toggle is not rendered")
  vim.cmd.edit(fixtures .. "/notes.md")
  vim.wait(100)

  lib.assert_eq(markdown.set(nil), false, "toggle from on did not switch off")
  vim.wait(200)
  restore()
  lib.assert_true(not markdown.enabled(), "render-markdown still enabled after toggling off")
  lib.assert_eq(vim.wo.conceallevel, 0, "toggling off did not restore plain text (conceallevel 0)")
  lib.assert_eq(#calls, 3, "expected exactly one notification per toggle: " .. vim.inspect(calls))
  os.remove(other_md)

  vim.cmd.edit(fixtures .. "/data.csv")
  vim.wait(200)
  lib.assert_true(vim.fn.exists(":RainbowDelim") == 2, "rainbow_csv did not load for a csv buffer")

  vim.cmd.edit(fixtures .. "/paper.tex")
  vim.wait(200)
  lib.assert_true(vim.g.loaded_vimtex == 1, "vimtex did not load for a tex buffer")

  vim.cmd.edit(fixtures .. "/main.py")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>e", true, false, true), "mx", false)
  vim.wait(300)
  lib.assert_true(package.loaded["nvim-tree"] ~= nil, "nvim-tree did not load on <leader>e")
  lib.assert_true(package.loaded["oil"] == nil, "oil should not have loaded from <leader>e (moved to <leader>o / '-')")

  vim.cmd.edit(fixtures .. "/main.py")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>o", true, false, true), "mx", false)
  vim.wait(300)
  lib.assert_true(package.loaded["oil"] ~= nil, "oil did not load on <leader>o")
  pcall(vim.cmd, "close")

  vim.cmd.edit(fixtures .. "/main.py")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>ff", true, false, true), "mx", false)
  vim.wait(500)
  lib.assert_true(package.loaded["telescope"] ~= nil, "telescope did not load on <leader>ff")
  pcall(vim.cmd, "close")
end)
