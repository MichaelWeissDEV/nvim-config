-- Lazy command stubs must hand the real command the *whole* original
-- invocation. The previous implementation rebuilt an Ex string as
-- `cmd .. "!" .. " " .. opts.args`, which silently dropped range, count,
-- register and command modifiers, and re-joined arguments the parser had
-- already split -- so `:Cmd "two words"` arrived as two arguments.
--
-- Synthetic commands only: no plugins, no packadd, no network.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("lazyload: command stubs preserve the full invocation", function()
  local lazyload = require("config.lazyload")
  lazyload._reset()

  -- A line range can only be typed against a buffer that actually has
  -- those lines; without this the `2,7` case below fails with E16 on the
  -- empty scratch buffer nvim -l starts in.
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" })

  local received = nil
  local load_count = 0

  -- The "plugin": defines the real command when loaded.
  local function loader()
    load_count = load_count + 1
    vim.api.nvim_create_user_command("LazyCtxTest", function(opts)
      received = {
        fargs = opts.fargs,
        bang = opts.bang,
        range = opts.range,
        line1 = opts.line1,
        line2 = opts.line2,
        reg = opts.reg,
        vertical = opts.smods and opts.smods.vertical or false,
      }
    end, { nargs = "*", bang = true, range = true, register = true })
  end

  local function reset_stub()
    pcall(vim.api.nvim_del_user_command, "LazyCtxTest")
    lazyload._reset()
    received = nil
    lazyload.on_command("LazyCtxTest", "lazy-ctx", loader)
  end

  --------------------------------------------------------------------
  -- 1. plain invocation
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd("LazyCtxTest")
  lib.assert_true(received ~= nil, "real command was never reached")
  lib.assert_eq(#received.fargs, 0, "no args expected")
  lib.assert_eq(received.bang, false, "no bang expected")
  lib.assert_eq(load_count, 1, "loader must run exactly once")

  --------------------------------------------------------------------
  -- 2. bang + several arguments, one of them quoted with a space
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd('LazyCtxTest! alpha "two words" beta')
  lib.assert_true(received ~= nil, "real command was never reached (bang/args)")
  lib.assert_eq(received.bang, true, "bang must be preserved")
  lib.assert_eq(#received.fargs, 4, "argument count: nvim splits the quoted word too")
  lib.assert_eq(received.fargs[1], "alpha", "first arg")
  lib.assert_eq(received.fargs[4], "beta", "last arg")
  -- The point of passing fargs through rather than re-joining a string:
  -- whatever Neovim's parser produced arrives unchanged, no re-quoting.
  lib.assert_eq(
    table.concat(received.fargs, "|"),
    'alpha|"two|words"|beta',
    "fargs must arrive exactly as the parser produced them"
  )

  --------------------------------------------------------------------
  -- 3. explicit line range
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd("2,7LazyCtxTest")
  lib.assert_true(received ~= nil, "real command was never reached (range)")
  lib.assert_eq(received.range, 2, "a two-part range must be reported as range=2")
  lib.assert_eq(received.line1, 2, "range start must be preserved")
  lib.assert_eq(received.line2, 7, "range end must be preserved")

  --------------------------------------------------------------------
  -- 4. no range at all must stay range=0, not become an implicit "."
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd("LazyCtxTest")
  lib.assert_eq(received.range, 0, "an unranged call must not acquire a range")

  --------------------------------------------------------------------
  -- 5. register
  --
  -- No `count` case: the stub is declared -range, and Vim treats -range
  -- and -count as mutually exclusive, so a -range stub never carries a
  -- meaningful count. Forwarding one anyway is a hard error, which is
  -- exactly what an earlier version of this test caught.
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd("LazyCtxTest x")
  -- With register=true and nargs="*", `x` is taken as the register.
  lib.assert_true(received ~= nil, "real command was never reached (register)")

  --------------------------------------------------------------------
  -- 6. command modifiers survive
  --------------------------------------------------------------------
  reset_stub()
  vim.cmd("vertical LazyCtxTest")
  lib.assert_true(received ~= nil, "real command was never reached (mods)")
  lib.assert_eq(received.vertical, true, "the :vertical modifier must be preserved")

  --------------------------------------------------------------------
  -- 7. a loader that does not define the command reports it clearly
  --------------------------------------------------------------------
  local notify = require("util.notify")
  local real_config_error = notify.config_error
  local reported = 0
  notify.config_error = function()
    reported = reported + 1
  end
  pcall(vim.api.nvim_del_user_command, "LazyCtxMissing")
  lazyload._reset()
  lazyload.on_command("LazyCtxMissing", "lazy-ctx-missing", function() end)
  pcall(vim.cmd, "LazyCtxMissing")
  notify.config_error = real_config_error
  lib.assert_true(reported >= 1, "a loader that never defines its command must be reported")

  pcall(vim.api.nvim_del_user_command, "LazyCtxTest")
  pcall(vim.api.nvim_del_user_command, "LazyCtxMissing")
  lazyload._reset()
end)
