-- The lazyloader's failure semantics. A loader that throws must NOT leave
-- the system believing the plugin loaded -- that was the original defect:
-- a boolean set before running the loader meant one transient failure
-- disabled the feature for the rest of the session.
--
-- Uses synthetic local loaders throughout: no plugins, no packadd, no
-- network.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("lazyload: failed loads roll back and can retry", function()
  local lazyload = require("config.lazyload")

  -- config_error is deliberately loud; silence it for the duration so the
  -- expected failures do not spam the test output, but count the calls so
  -- we can assert the error was actually reported rather than swallowed.
  local reported = 0
  local notify = require("util.notify")
  local real_config_error = notify.config_error
  notify.config_error = function()
    reported = reported + 1
  end
  local restore = function()
    notify.config_error = real_config_error
  end

  local ok, err = pcall(function()
    lazyload._reset()

    ----------------------------------------------------------------------
    -- 1. failing loader -> not loaded, error reported, state rolled back
    ----------------------------------------------------------------------
    local calls = 0
    local should_fail = true
    local function loader()
      calls = calls + 1
      if should_fail then
        error("synthetic loader failure")
      end
    end

    local loaded = lazyload.now("synthetic", loader)
    lib.assert_eq(loaded, false, "first (failing) load must report not-loaded")
    lib.assert_eq(calls, 1, "loader must have run once")
    lib.assert_eq(lazyload.state("synthetic"), nil, "state must roll back to unloaded after failure")
    lib.assert_eq(reported, 1, "the failure must be reported, not swallowed")

    ----------------------------------------------------------------------
    -- 2. retry in the same session succeeds
    ----------------------------------------------------------------------
    should_fail = false
    loaded = lazyload.now("synthetic", loader)
    lib.assert_eq(loaded, true, "retry after a failure must be allowed and succeed")
    lib.assert_eq(calls, 2, "loader must have run a second time")
    lib.assert_eq(lazyload.state("synthetic"), "loaded", "state must be loaded after success")

    ----------------------------------------------------------------------
    -- 3. a third trigger must NOT run the loader again
    ----------------------------------------------------------------------
    loaded = lazyload.now("synthetic", loader)
    lib.assert_eq(loaded, true, "already-loaded must report loaded")
    lib.assert_eq(calls, 2, "loader must not run again once loaded")

    ----------------------------------------------------------------------
    -- 4. recursion is detected instead of overflowing the stack
    ----------------------------------------------------------------------
    reported = 0
    local depth = 0
    local function recursive()
      depth = depth + 1
      lazyload.now("recursive", recursive) -- re-enter while still loading
    end
    local rec_loaded = lazyload.now("recursive", recursive)
    lib.assert_eq(depth, 1, "recursive loader body must run exactly once")
    lib.assert_eq(rec_loaded, true, "outer call still completes")
    lib.assert_true(reported >= 1, "re-entry must be reported")

    ----------------------------------------------------------------------
    -- 5. a failing key stub must not permanently delete the mapping
    ----------------------------------------------------------------------
    lazyload._reset()
    local key_calls = 0
    local key_should_fail = true
    lazyload.on_key("n", "<Plug>LazyloadTest", "synthetic-key", function()
      key_calls = key_calls + 1
      if key_should_fail then
        error("synthetic key loader failure")
      end
      vim.keymap.set("n", "<Plug>LazyloadTest", function() end, { desc = "real" })
    end, "synthetic key")

    lib.assert_true(vim.fn.maparg("<Plug>LazyloadTest", "n") ~= "", "stub mapping must exist up front")

    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>LazyloadTest", true, false, true), "mx", false)
    vim.wait(100)
    lib.assert_eq(key_calls, 1, "key loader must have run")
    lib.assert_true(vim.fn.maparg("<Plug>LazyloadTest", "n") ~= "", "stub must be restored after a failed load")

    key_should_fail = false
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>LazyloadTest", true, false, true), "mx", false)
    vim.wait(100)
    lib.assert_eq(key_calls, 2, "second press must retry the loader")
    lib.assert_true(vim.fn.maparg("<Plug>LazyloadTest", "n") ~= "", "real mapping must exist after success")

    ----------------------------------------------------------------------
    -- 6. a failing FileType loader must retry on the next matching buffer
    ----------------------------------------------------------------------
    lazyload._reset()
    local ft_calls = 0
    local ft_should_fail = true
    lazyload.on_filetype({ "lazyloadtestft" }, "synthetic-ft", function()
      ft_calls = ft_calls + 1
      if ft_should_fail then
        error("synthetic filetype loader failure")
      end
    end)

    local buf1 = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "lazyloadtestft", { buf = buf1 })
    lib.assert_eq(ft_calls, 1, "filetype loader must have run")
    lib.assert_eq(lazyload.state("synthetic-ft"), nil, "failed filetype load must not be marked loaded")

    ft_should_fail = false
    local buf2 = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("filetype", "lazyloadtestft", { buf = buf2 })
    lib.assert_eq(ft_calls, 2, "a later matching buffer must retry")
    lib.assert_eq(lazyload.state("synthetic-ft"), "loaded", "successful retry must mark loaded")
  end)

  restore()
  lazyload._reset()
  if not ok then
    error(err, 0)
  end
end)
