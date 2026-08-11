-- Positive counterpart to test_startup.lua's "nothing loads eagerly":
-- confirm each trigger actually loads its plugin, exactly once, on demand.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")
local fixtures = this_dir .. "/fixtures"

lib.run("lazy load: triggers actually load their plugin", function()
  vim.cmd.edit(fixtures .. "/notes.md")
  vim.wait(200)
  lib.assert_true(package.loaded["render-markdown"] ~= nil, "render-markdown did not load for a markdown buffer")

  vim.cmd.edit(fixtures .. "/data.csv")
  vim.wait(200)
  lib.assert_true(vim.fn.exists(":RainbowDelim") == 2, "rainbow_csv did not load for a csv buffer")

  vim.cmd.edit(fixtures .. "/paper.tex")
  vim.wait(200)
  lib.assert_true(vim.g.loaded_vimtex == 1, "vimtex did not load for a tex buffer")

  vim.cmd.edit(fixtures .. "/main.py")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>e", true, false, true), "mx", false)
  vim.wait(300)
  lib.assert_true(package.loaded["oil"] ~= nil, "oil did not load on <leader>e")
  pcall(vim.cmd, "close")

  vim.cmd.edit(fixtures .. "/main.py")
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>ff", true, false, true), "mx", false)
  vim.wait(500)
  lib.assert_true(package.loaded["telescope"] ~= nil, "telescope did not load on <leader>ff")
  pcall(vim.cmd, "close")
end)
