-- `nvim <a-directory>` should open the nvim-tree sidebar at that directory
-- (see the VimEnter autocmd in plugins/tree.lua) instead of an empty
-- buffer. This specifically needs VimEnter to actually fire, which in
-- Neovim's documented startup order happens AFTER any "-c cmd" arguments
-- are executed -- so unlike every other test here, this one can't be
-- invoked as `nvim -l test_directory_arg.lua -c qa` (the qa would run
-- before VimEnter ever fires). Instead it's sourced via --cmd (the
-- earliest possible hook point) and quits itself from inside the
-- VimEnter callback. See tests/run.sh for the exact invocation.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

local target = vim.fn.argv(0)

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      lib.run("directory-arg opens the file tree", function()
        vim.wait(500)
        lib.assert_true(
          package.loaded["nvim-tree"] ~= nil,
          "nvim-tree did not load for `nvim " .. tostring(target) .. "`"
        )
        local resolved_cwd = vim.uv.fs_realpath(vim.fn.getcwd())
        local resolved_target = vim.uv.fs_realpath(target)
        lib.assert_eq(resolved_cwd, resolved_target, "cwd was not changed to the directory argument")
      end)
    end)
  end,
})

-- Safety net: if VimEnter never fires for some reason, don't hang forever.
vim.defer_fn(function()
  print("FAIL: directory-arg opens the file tree: VimEnter never fired")
  os.exit(1)
end, 10000)
