-- Minimal loader around Neovim's native `packadd` + autocommands. This is
-- deliberately NOT a plugin manager: it does no dependency resolution, no
-- version pinning, no network I/O. It only answers "load this `opt` package
-- and run its setup the first time some trigger fires."
--
-- The one thing it takes seriously is failure. A loader that throws must
-- not leave the system believing the plugin loaded: the state goes back to
-- unloaded, the trigger is restored, and the next trigger retries. The
-- error itself is never swallowed -- it surfaces with a full traceback
-- through util.notify.config_error, which is the loud path.
local M = {}

--- Load states. Explicit rather than a boolean so a *failed* load is
--- distinguishable from a *finished* one, and so re-entering a loader
--- while it is still running can be detected instead of silently
--- recursing.
--- @alias LoadState "loading"|"loaded"
--- @type table<string, LoadState>
local states = {}

--- @param key string
--- @return LoadState|nil
function M.state(key)
  return states[key]
end

--- Test seam: forget everything. Only tests call this.
function M._reset()
  states = {}
end

--- Run `fn` at most once, transactionally.
---
--- Returns true when the config is now loaded (either because this call
--- succeeded or because it already was), false when it is not -- which
--- includes both a failed loader and a detected re-entry.
--- @param key string
--- @param fn function
--- @return boolean loaded
local function once(key, fn)
  local state = states[key]
  if state == "loaded" then
    return true
  end
  if state == "loading" then
    -- Re-entry: the loader triggered itself, directly or via a stub it
    -- did not manage to replace. Returning instead of recursing turns a
    -- stack overflow into a diagnosable message.
    require("util.notify").config_error(
      "lazyload(" .. key .. ")",
      "recursive load detected: the loader for '" .. key .. "' triggered itself before finishing"
    )
    return false
  end

  states[key] = "loading"
  local ok, err = xpcall(fn, debug.traceback)
  if not ok then
    -- Roll back so a later trigger can retry rather than being stuck.
    states[key] = nil
    require("util.notify").config_error("lazyload(" .. key .. ")", tostring(err))
    return false
  end

  states[key] = "loaded"
  return true
end

M.once = once

--- Idempotently `packadd` a vendored package from pack/vendor/opt.
--- @param name string directory name under pack/vendor/opt
--- @return boolean ok
function M.packadd(name)
  local key = "packadd:" .. name
  if states[key] == "loaded" then
    return true
  end
  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    require("util.notify").config_error("packadd(" .. name .. ")", tostring(err))
    return false
  end
  states[key] = "loaded"
  return true
end

--- Load on first matching FileType. A failed load leaves the autocommand
--- in place, so the next matching buffer retries.
--- @param filetypes string|string[]
--- @param name string unique key for the once-guard
--- @param fn function called with no args the first time one of the filetypes opens
function M.on_filetype(filetypes, name, fn)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetypes,
    group = vim.api.nvim_create_augroup("lazyload_ft_" .. name, { clear = true }),
    callback = function()
      once(name, fn)
    end,
  })
end

--- The stub's own definition, so it can be re-created after a failed load.
--- @param cmd string
--- @param name string
--- @param fn function
local function create_command_stub(cmd, name, fn)
  vim.api.nvim_create_user_command(cmd, function(opts)
    -- Remove the stub first: the real plugin needs the name free to
    -- define its own command during the load.
    pcall(vim.api.nvim_del_user_command, cmd)

    if not once(name, fn) then
      -- Load failed (or re-entered). Put the stub back so the command
      -- still exists and the user can try again; config_error has
      -- already reported why.
      if vim.fn.exists(":" .. cmd) ~= 2 then
        create_command_stub(cmd, name, fn)
      end
      return
    end

    if vim.fn.exists(":" .. cmd) ~= 2 then
      -- The loader succeeded but did not define the command it was
      -- supposed to. Silently doing nothing here is how a typo in a
      -- manifest turns into an unexplainable no-op, so say it plainly.
      require("util.notify").config_error(
        "lazyload(" .. name .. ")",
        "loaded successfully but did not define the expected command :" .. cmd
      )
      return
    end

    -- Re-dispatch with the full original invocation. Built as a structured
    -- nvim_cmd call rather than by concatenating an Ex string: string
    -- building loses range/register/modifiers and would re-quote arguments
    -- that the parser already split correctly.
    --
    -- `count` is deliberately NOT forwarded. The stub is declared -range,
    -- and Vim treats -range and -count as mutually exclusive, so a -range
    -- stub never carries a meaningful count -- while passing one to a
    -- command that does not declare -count is a hard error ("Command
    -- cannot accept count"). This was caught by
    -- tests/test_lazyload_command_context.lua rather than in the wild.
    local dispatch = {
      cmd = cmd,
      args = opts.fargs,
      bang = opts.bang,
      -- `range` says how many of line1/line2 the user actually typed;
      -- forwarding the values only when a range was given keeps `:Cmd`
      -- distinct from `:.Cmd` and `:1,5Cmd`.
      range = (opts.range == 1 and { opts.line1 }) or (opts.range == 2 and { opts.line1, opts.line2 }) or nil,
      reg = (opts.reg ~= "" and opts.reg) or nil,
      mods = opts.smods,
    }
    local dispatched, dispatch_err = pcall(vim.api.nvim_cmd, dispatch, {})
    if not dispatched then
      -- A generic stub cannot mirror every attribute set an unknown
      -- command might declare (e.g. forwarding a range to a command that
      -- takes none). Report which invocation could not be replayed
      -- instead of surfacing a bare traceback from inside the stub.
      require("util.notify").config_error(
        "lazyload(" .. name .. ")",
        "loaded :" .. cmd .. " but could not replay the original invocation:\n" .. tostring(dispatch_err)
      )
    end
  end, {
    desc = "Lazy-load stub for :" .. cmd,
    bang = true,
    nargs = "*",
    range = true,
    complete = "file",
  })
end

--- Load on first use of a user command. The stub re-dispatches the original
--- invocation, with its arguments, bang, range, count, register and command
--- modifiers preserved.
--- @param commands string|string[]
--- @param name string unique key for the once-guard
--- @param fn function loader, called before re-dispatch
function M.on_command(commands, name, fn)
  commands = type(commands) == "string" and { commands } or commands
  for _, cmd in ipairs(commands) do
    create_command_stub(cmd, name, fn)
  end
end

--- Load on first press of a key. `fn` is responsible for BOTH loading the
--- plugin and performing the key's actual action (see plugins/files.lua or
--- plugins/diagnostics.lua).
---
--- The stub is removed before loading so the real keymap can take the same
--- lhs, and restored if the load fails -- otherwise a single failure would
--- silently delete the binding for the rest of the session.
--- @param mode string|string[]
--- @param lhs string
--- @param name string unique key for the once-guard
--- @param fn function loader + action, called with no args
--- @param desc string
function M.on_key(mode, lhs, name, fn, desc)
  local function create_key_stub()
    vim.keymap.set(mode, lhs, function()
      pcall(vim.keymap.del, mode, lhs)
      if not once(name, fn) then
        -- Restore the stub unless the loader already bound this key to
        -- something real (checking avoids clobbering a working mapping
        -- and avoids the stub re-triggering itself).
        local existing = vim.fn.maparg(lhs, type(mode) == "table" and mode[1] or mode)
        if existing == "" then
          create_key_stub()
        end
      end
    end, { desc = desc, silent = true })
  end
  create_key_stub()
end

--- Load right now (used for User autocmd triggers like LspAttach, or from
--- other loaders that need a plugin loaded unconditionally).
--- @param name string
--- @param fn function
--- @return boolean loaded
function M.now(name, fn)
  return once(name, fn)
end

return M
