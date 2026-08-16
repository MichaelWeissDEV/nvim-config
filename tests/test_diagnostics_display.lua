-- Diagnostic display defaults and their toggles.
--
-- Two things this pins down:
--   1. `virtual_lines` is OFF by default. It is the only diagnostic display
--      setting that adds screen lines, so with it on the buffer reflows as
--      the cursor moves -- the code you are reading shifts down and back up
--      again. Everything that marks a problem *without* moving text
--      (underline, sign, end-of-line virtual_text) stays on.
--   2. The toggle actually toggles. It used to be written as
--      `current and false or { current_line = true }`, and in Lua
--      `x and false or y` is always `y` -- so it could only ever switch the
--      feature on, while notifying that it had switched it off. A toggle
--      that moves in one direction is worse than no toggle, and nothing
--      caught it.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("diagnostics: quiet display by default, working toggles", function()
  local diagnostics = require("config.diagnostics")
  local config = vim.diagnostic.config()

  ------------------------------------------------------------------
  -- 1. the setting that reflows the buffer is off...
  ------------------------------------------------------------------
  lib.assert_eq(config.virtual_lines, false, "virtual_lines must be off by default -- it reflows the buffer")

  ------------------------------------------------------------------
  -- 2. ...and everything that marks a problem in place is on
  ------------------------------------------------------------------
  lib.assert_eq(config.underline, true, "underline must stay on: it marks the problem without moving text")
  lib.assert_true(type(config.virtual_text) == "table", "end-of-line virtual_text must stay on")
  lib.assert_true(
    type(config.signs) == "table" and type(config.signs.text) == "table",
    "sign column glyphs must stay configured"
  )
  lib.assert_eq(config.update_in_insert, false, "diagnostics must not re-render on every keystroke")

  ------------------------------------------------------------------
  -- 3. the toggle moves in BOTH directions, repeatedly
  ------------------------------------------------------------------
  local calls, restore_notify = lib.notify_spy()
  local ok, err = pcall(function()
    lib.assert_eq(diagnostics.toggle_virtual_lines(), true, "first press must turn inline detail on")
    lib.assert_true(vim.diagnostic.config().virtual_lines ~= false, "config must reflect it being on")

    lib.assert_eq(diagnostics.toggle_virtual_lines(), false, "second press must turn it back off")
    lib.assert_eq(vim.diagnostic.config().virtual_lines, false, "config must reflect it being off again")

    lib.assert_eq(diagnostics.toggle_virtual_lines(), true, "third press must turn it on again")
    diagnostics.toggle_virtual_lines()

    -- The message must match reality, not the pre-toggle state.
    lib.assert_eq(#calls, 4, "each toggle reports exactly once")
    lib.assert_true(calls[1].msg:find("on", 1, true) ~= nil, "turning it on must say so: " .. calls[1].msg)
    lib.assert_true(calls[2].msg:find("off", 1, true) ~= nil, "turning it off must say so: " .. calls[2].msg)
  end)
  restore_notify()

  -- Leave the session in the documented default whatever happened above.
  vim.diagnostic.config({ virtual_lines = false })
  if not ok then
    error(err, 0)
  end

  ------------------------------------------------------------------
  -- 4. the per-buffer toggle behaves the same way
  ------------------------------------------------------------------
  local calls2, restore2 = lib.notify_spy()
  local ok2, err2 = pcall(function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)

    lib.assert_eq(diagnostics.toggle_buffer(), false, "first press must disable diagnostics here")
    lib.assert_eq(vim.diagnostic.is_enabled({ bufnr = 0 }), false, "and the buffer must actually be disabled")
    lib.assert_eq(diagnostics.toggle_buffer(), true, "second press must enable them again")
    lib.assert_eq(vim.diagnostic.is_enabled({ bufnr = 0 }), true, "and the buffer must actually be enabled")
    lib.assert_eq(#calls2, 2, "each toggle reports exactly once")
  end)
  restore2()
  if not ok2 then
    error(err2, 0)
  end
end)
