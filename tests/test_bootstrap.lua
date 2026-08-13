-- Regression test for the CI startup failure.
--
-- Starting `nvim -u /path/to/init.lua` from anywhere other than
-- stdpath("config") used to fail twice over:
--   1. `module 'config.options' not found` -- the repo root was not on
--      'runtimepath', so none of lua/ resolved.
--   2. after that was fixed, `module 'nvim-web-devicons' not found` --
--      vendored packages under pack/vendor/start/ key off 'packpath',
--      which the first fix did not touch.
--
-- Both are exactly the state of a fresh CI runner, where there is no
-- ~/.config/nvim at all. This test asserts the invariant that makes the
-- suite runnable there: with this init.lua loaded, both the config's own
-- modules and the vendored start plugins are importable.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

local function canonical(path)
  local p = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  p = p:gsub("[/\\]+$", "")
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    p = p:lower()
  end
  return p
end

local function pathlist_contains(pathlist, path)
  local want = canonical(path)
  for _, entry in ipairs(vim.split(pathlist, ",", { plain = true, trimempty = true })) do
    if canonical(entry) == want then
      return true
    end
  end
  return false
end

lib.run("bootstrap: config modules and vendored plugins resolve", function()
  local repo_root = vim.fs.dirname(this_dir)

  -- The repo root must be on both paths. runtimepath alone is not enough:
  -- that was the exact incomplete fix that left CI red.
  lib.assert_true(
    pathlist_contains(vim.o.runtimepath, repo_root),
    "repo root missing from runtimepath -- lua/ would not resolve"
  )
  lib.assert_true(
    pathlist_contains(vim.o.packpath, repo_root),
    "repo root missing from packpath -- vendored start plugins would not resolve"
  )

  -- Failure mode 1: the config's own modules.
  for _, mod in ipairs({ "config.options", "util.version", "languages.registry", "tools.registry" }) do
    lib.assert_true(pcall(require, mod), "require('" .. mod .. "') failed")
  end

  -- Failure mode 2: vendored `start` plugins, which init.lua requires
  -- during startup and which therefore must resolve from packpath.
  for _, mod in ipairs({ "nvim-web-devicons", "cmp", "gitsigns", "conform", "lint" }) do
    lib.assert_true(pcall(require, mod), "require('" .. mod .. "') failed -- vendored start plugin not on packpath")
  end
end)
