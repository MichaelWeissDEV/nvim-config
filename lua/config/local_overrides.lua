-- Loads lua/config/local.lua when it exists: machine-specific settings that
-- must never be committed (the path is in .gitignore). Runs right after
-- config.options and before any plugin or language module, so every
-- `vim.g.nvim_config_*` switch set there is in place before anything reads it.
--
-- lua/config/local.example.lua lists every supported switch; copy it to
-- lua/config/local.lua and edit.
--
-- Loaded with loadfile() rather than require() so a missing file is a
-- plain "nothing to do", while a file that exists but is broken stays loud:
-- a typo in your overrides should not silently fall back to defaults.
--
-- The path is derived from this file's own location, not stdpath("config"):
-- under `nvim -u <repo>/init.lua` (CI, the test suite) stdpath("config") is
-- ~/.config/nvim, which may be a different checkout entirely.
local here = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local path = vim.fs.joinpath(here, "local.lua")

-- NVIM_CONFIG_NO_LOCAL=1 skips it: tests/run.sh sets this so a developer's
-- personal overrides (say, auto-rendered markdown) cannot change what the
-- test suite observes.
if vim.env.NVIM_CONFIG_NO_LOCAL ~= "1" and vim.uv.fs_stat(path) then
  local chunk, load_err = loadfile(path)
  if not chunk then
    require("util.notify").config_error("config/local.lua", tostring(load_err))
  else
    local ok, run_err = xpcall(chunk, debug.traceback)
    if not ok then
      require("util.notify").config_error("config/local.lua", tostring(run_err))
    end
  end
end
