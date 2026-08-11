-- Minimal loader around Neovim's native `packadd` + autocommands. This is
-- deliberately NOT a plugin manager: it does no dependency resolution, no
-- version pinning, no network I/O. It only answers "load this `opt` package
-- and run its setup the first time some trigger fires."
local M = {}

local loaded = {} ---@type table<string, boolean>

--- Idempotently `packadd` a vendored package from pack/vendor/opt.
--- @param name string directory name under pack/vendor/opt
--- @return boolean ok
function M.packadd(name)
  if loaded[name] then
    return true
  end
  local ok, err = pcall(vim.cmd.packadd, name)
  if not ok then
    require("util.notify").config_error("packadd(" .. name .. ")", tostring(err))
    return false
  end
  loaded[name] = true
  return true
end

--- Run `fn` exactly once, no matter how many times this trigger fires.
--- @param key string
--- @param fn function
local function once(key, fn)
  if loaded["fn:" .. key] then
    return
  end
  loaded["fn:" .. key] = true
  fn()
end

--- Load on first matching FileType.
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

--- Load on first use of a user command, by registering a stub command that
--- loads the real plugin (which defines the real command) and then
--- re-dispatches the original invocation to it.
--- @param commands string|string[]
--- @param name string unique key for the once-guard
--- @param fn function loader, called before re-dispatch
function M.on_command(commands, name, fn)
  commands = type(commands) == "string" and { commands } or commands
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd, function(opts)
      vim.api.nvim_del_user_command(cmd)
      once(name, fn)
      local cmd_str = (opts.bang and (cmd .. "!") or cmd)
      if opts.args and opts.args ~= "" then
        cmd_str = cmd_str .. " " .. opts.args
      end
      vim.cmd(cmd_str)
    end, { desc = "Lazy-load stub for " .. cmd, bang = true, nargs = "*", range = true })
  end
end

--- Load on first press of a key. `fn` is responsible for BOTH loading the
--- plugin and performing the key's actual action (see plugins/files.lua or
--- plugins/diagnostics.lua) -- the stub is removed first so a second press
--- goes straight to whatever real keymap `fn` sets up, if any.
--- @param mode string|string[]
--- @param lhs string
--- @param name string unique key for the once-guard
--- @param fn function loader + action, called with no args
--- @param desc string
function M.on_key(mode, lhs, name, fn, desc)
  vim.keymap.set(mode, lhs, function()
    pcall(vim.keymap.del, mode, lhs)
    once(name, fn)
  end, { desc = desc, silent = true })
end

--- Load right now (used for User autocmd triggers like LspAttach, or from
--- other loaders that need a plugin loaded unconditionally).
--- @param name string
--- @param fn function
function M.now(name, fn)
  once(name, fn)
end

return M
