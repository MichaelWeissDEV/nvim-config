-- A plain `nvim` with no file argument: zero notifications, and zero `opt`
-- plugins loaded (they're all lazy-load-on-first-use).
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("startup: quiet + no opt plugins loaded", function()
  local calls, restore = lib.notify_spy()
  vim.wait(300) -- let any deferred startup work (e.g. LSP autocmd registration) settle
  restore()

  lib.assert_eq(#calls, 0, "startup produced notifications: " .. vim.inspect(calls))

  lib.assert_true(package.loaded["telescope"] == nil, "telescope loaded at plain startup")
  lib.assert_true(package.loaded["oil"] == nil, "oil loaded at plain startup")
  lib.assert_true(package.loaded["trouble"] == nil, "trouble loaded at plain startup")
  lib.assert_true(package.loaded["dap"] == nil, "nvim-dap loaded at plain startup")
  lib.assert_true(package.loaded["dapui"] == nil, "nvim-dap-ui loaded at plain startup")
  lib.assert_true(package.loaded["render-markdown"] == nil, "render-markdown loaded at plain startup")
  lib.assert_true(vim.g.loaded_vimtex == nil, "vimtex loaded at plain startup")
end)
