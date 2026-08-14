-- Runtime tool refresh.
--
-- The original defect: util.executable cached "not found" per binary name
-- for the whole session and nothing ever cleared it, so a tool installed
-- via :ToolsInstall kept reporting as missing until Neovim restarted.
--
-- No Mason, no downloads, no network: availability is simulated by putting
-- a real executable file into a temporary directory on PATH, which is what
-- util.executable actually probes.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("tools refresh: newly installed tools become visible without a restart", function()
  local exe = require("util.executable")
  local refresh = require("tools.refresh")
  local platform = require("util.platform")

  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local original_path = vim.env.PATH

  -- The name a tool registry entry carries in its `exe` field: never
  -- suffixed, on any platform. The file on disk does need a suffix on
  -- Windows, where an extensionless file is not executable at all -- so
  -- probe name and filename are kept apart deliberately. That difference is
  -- itself part of what this test asserts: `exe.exists("nvimcfg_fake_tool")`
  -- has to find `nvimcfg_fake_tool.cmd` through PATHEXT, exactly as it finds
  -- a real `ruff` through `ruff.exe`.
  local tool_name = "nvimcfg_fake_tool"
  local tool_path = tmp .. "/" .. tool_name .. (platform.is_windows and ".cmd" or "")

  --- Write the fake tool to disk and make it executable where that is a
  --- separate step (it is not on Windows, where the suffix decides).
  local function install_fake_tool()
    local f = assert(io.open(tool_path, "w"))
    f:write(platform.is_windows and "@echo off\r\nexit /b 0\r\n" or "#!/bin/sh\nexit 0\n")
    f:close()
    if not platform.is_windows then
      vim.fn.system({ "chmod", "+x", tool_path })
    end
  end

  local ok, err = pcall(function()
    -- ";" on Windows, ":" elsewhere -- the wrong one does not error, it
    -- silently collapses $PATH into one unusable entry.
    vim.env.PATH = tmp .. platform.path_list_sep .. original_path
    exe.reset()

    ------------------------------------------------------------------
    -- 1. not installed yet -> reported unavailable, and the answer is
    --    cached (that caching is the whole reason a reset is needed)
    ------------------------------------------------------------------
    lib.assert_eq(exe.exists(tool_name), false, "tool must start out unavailable")

    ------------------------------------------------------------------
    -- 2. it appears on disk -- but the cached answer is still stale.
    --    This asserts the failure mode exists, so the fix below is
    --    demonstrably doing something.
    ------------------------------------------------------------------
    install_fake_tool()

    lib.assert_eq(exe.exists(tool_name), false, "stale cache is expected until the change is announced")

    ------------------------------------------------------------------
    -- 3. announcing the change clears the cache AND fires the event
    ------------------------------------------------------------------
    local fired = 0
    local payload = nil
    refresh.on_tools_changed("test_listener", function(args)
      fired = fired + 1
      payload = args.data
    end)

    refresh.notify_tools_changed({ packages = { "fake" } })

    lib.assert_eq(fired, 1, "NvimConfigToolsChanged must fire exactly once")
    lib.assert_true(payload ~= nil and payload.packages ~= nil, "listeners must receive the payload")
    lib.assert_eq(exe.exists(tool_name), true, "tool must be visible after the refresh, with no restart")

    ------------------------------------------------------------------
    -- 4. the cache is cleared BEFORE listeners run -- otherwise a
    --    listener that re-derives availability would still see the old
    --    answer, which is precisely the bug this event exists to fix
    ------------------------------------------------------------------
    local seen_by_listener = nil
    refresh.on_tools_changed("test_ordering", function()
      seen_by_listener = exe.exists(tool_name)
    end)
    os.remove(tool_path)
    refresh.notify_tools_changed()
    lib.assert_eq(seen_by_listener, false, "listeners must observe the post-change state, not the cached one")

    ------------------------------------------------------------------
    -- 5. linting resolves availability per trigger, so it needs no
    --    subscription at all -- assert that documented property
    ------------------------------------------------------------------
    local tools_registry = require("tools.registry")
    local detection = require("tools.detection")
    local shellcheck = tools_registry.get("shellcheck")
    lib.assert_true(shellcheck ~= nil, "shellcheck must exist in the tool registry")

    local fake = { id = "fake", name = "fake", category = "linter", exe = tool_name, profiles = { "core" } }
    exe.reset()
    lib.assert_eq(detection.installed(fake), false, "detection reflects a missing binary")
    install_fake_tool()
    exe.reset()
    lib.assert_eq(detection.installed(fake), true, "detection reflects an installed binary after a reset")
  end)

  -- Clean up regardless of outcome: PATH, temp dir, cache, listeners.
  vim.env.PATH = original_path
  pcall(os.remove, tool_path)
  pcall(vim.fn.delete, tmp, "rf")
  exe.reset()
  pcall(vim.api.nvim_del_augroup_by_name, "nvim_config_tools_changed_test_listener")
  pcall(vim.api.nvim_del_augroup_by_name, "nvim_config_tools_changed_test_ordering")

  if not ok then
    error(err, 0)
  end
end)
