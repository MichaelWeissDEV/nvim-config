-- Interpreter resolution for "run the current file".
--
-- Replaces a keymap that contained the literal Ex string
-- `terminal python3 %`, which assumed python3 exists (it does not on a
-- default Windows install), ignored an activated virtualenv, and let the
-- shell split a path containing a space into two arguments.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("process: interpreter resolution, venv priority, spaces in paths", function()
  local process = require("util.process")
  local exe = require("util.executable")

  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp .. "/bin", "p")
  local original_path = vim.env.PATH
  local original_venv = vim.env.VIRTUAL_ENV

  local ok, err = pcall(function()
    ------------------------------------------------------------------
    -- 1. resolves to something real on this machine
    ------------------------------------------------------------------
    local argv = process.resolve("python")
    lib.assert_true(argv ~= nil, "python must resolve on a machine that has one")
    lib.assert_true(type(argv) == "table" and #argv >= 1, "resolve must return an argv list")

    ------------------------------------------------------------------
    -- 2. an unknown language resolves to nil rather than erroring
    ------------------------------------------------------------------
    lib.assert_eq(process.resolve("no_such_language"), nil, "unknown language must resolve to nil")

    ------------------------------------------------------------------
    -- 3. VIRTUAL_ENV takes priority over anything on PATH
    ------------------------------------------------------------------
    local venv = tmp .. "/venv"
    local bindir = venv .. (require("util.platform").is_windows and "/Scripts" or "/bin")
    local pyname = require("util.platform").is_windows and "python.exe" or "python"
    vim.fn.mkdir(bindir, "p")
    local f = assert(io.open(bindir .. "/" .. pyname, "w"))
    f:write("#!/bin/sh\nexit 0\n")
    f:close()
    vim.fn.system({ "chmod", "+x", bindir .. "/" .. pyname })

    vim.env.VIRTUAL_ENV = venv
    exe.reset()
    argv = process.resolve("python")
    lib.assert_eq(argv[1], bindir .. "/" .. pyname, "an activated virtualenv must win over PATH")

    ------------------------------------------------------------------
    -- 4. a VIRTUAL_ENV without an interpreter falls back to PATH
    ------------------------------------------------------------------
    vim.env.VIRTUAL_ENV = tmp .. "/empty-venv"
    exe.reset()
    argv = process.resolve("python")
    lib.assert_true(argv ~= nil, "a broken VIRTUAL_ENV must fall back, not fail")
    lib.assert_true(
      argv[1] ~= tmp .. "/empty-venv/bin/python",
      "must not return an interpreter path that does not exist"
    )
    vim.env.VIRTUAL_ENV = original_venv

    ------------------------------------------------------------------
    -- 5. no interpreter at all -> nil, and the caller reports it once
    ------------------------------------------------------------------
    -- Name the buffer BEFORE restricting PATH: naming fires BufFilePost,
    -- and gitsigns shells out to `git` there, which would fail for an
    -- unrelated reason on an emptied PATH.
    local buf = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf, tmp .. "/thing.rb")
    vim.api.nvim_set_current_buf(buf)

    vim.env.PATH = tmp .. "/bin" -- empty directory: nothing resolvable
    exe.reset()
    lib.assert_eq(process.resolve("ruby"), nil, "no interpreter on PATH must resolve to nil")

    local notify = require("util.notify")
    local real = notify.once
    local messages = {}
    notify.once = function(_, msg)
      table.insert(messages, msg)
    end
    local started = process.run_current_file("ruby")
    notify.once = real

    lib.assert_eq(started, false, "run_current_file must report failure when nothing resolves")
    lib.assert_eq(#messages, 1, "exactly one message, not a stream")
    lib.assert_true(messages[1]:find("ruby", 1, true) ~= nil, "the message must name the language")

    vim.env.PATH = original_path
    exe.reset()

    ------------------------------------------------------------------
    -- 6. a path containing a space stays ONE argument
    --
    -- Asserted on the argv the runner builds, which is what makes the
    -- old `terminal python3 %` form unfixable: that goes through a shell.
    ------------------------------------------------------------------
    local spaced_dir = tmp .. "/dir with spaces"
    vim.fn.mkdir(spaced_dir, "p")
    local spaced = spaced_dir .. "/my script.py"
    local sf = assert(io.open(spaced, "w"))
    sf:write("print('hi')\n")
    sf:close()

    local captured = nil
    local real_jobstart = vim.fn.jobstart
    vim.fn.jobstart = function(cmd, _)
      captured = cmd
      return 0
    end
    local buf2 = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_buf_set_name(buf2, spaced)
    vim.api.nvim_set_current_buf(buf2)
    process.run_current_file("python")
    vim.fn.jobstart = real_jobstart

    lib.assert_true(captured ~= nil, "jobstart must have been called")
    lib.assert_true(type(captured) == "table", "the command must be an argv list, not a shell string")
    -- Compare resolved paths: macOS reports /var as /private/var, and
    -- Neovim stores the buffer name resolved.
    lib.assert_eq(
      vim.uv.fs_realpath(captured[#captured]),
      vim.uv.fs_realpath(spaced),
      "the file path must arrive as one intact argument"
    )
    lib.assert_true(
      captured[#captured]:find(" ", 1, true) ~= nil,
      "the argument must still contain the space, i.e. it was never split"
    )

    ------------------------------------------------------------------
    -- 7. an unnamed buffer is refused, not run
    ------------------------------------------------------------------
    notify.once = function() end
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(scratch)
    lib.assert_eq(process.run_current_file("python"), false, "an unnamed buffer must not be run")
    notify.once = real
  end)

  vim.env.PATH = original_path
  vim.env.VIRTUAL_ENV = original_venv
  exe.reset()
  pcall(vim.fn.delete, tmp, "rf")

  if not ok then
    error(err, 0)
  end
end)
