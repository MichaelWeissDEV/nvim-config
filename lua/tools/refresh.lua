-- The single place that announces "the set of installed tools changed".
--
-- Every subsystem that decides something from tool availability
-- (LSP server enablement, conform's formatter table, nvim-lint's linter
-- list, DAP adapters) caches that decision to some degree. Without one
-- shared signal, each installer path would have to remember to poke each
-- subsystem -- which is exactly how util.executable's cache ended up
-- never being invalidated at all.
--
-- Contract:
--   1. util.executable's cache is cleared FIRST, so every listener that
--      re-checks availability sees the new reality rather than the
--      answer from before the install.
--   2. `User NvimConfigToolsChanged` is fired once, synchronously.
--
-- Anything that needs to react subscribes to that autocommand. Nothing
-- else may fire it.
local M = {}

M.EVENT = "NvimConfigToolsChanged"

--- Announce that installed tools changed.
--- @param data table|nil optional payload, e.g. { packages = {...} }
function M.notify_tools_changed(data)
  require("util.executable").reset()

  vim.api.nvim_exec_autocmds("User", {
    pattern = M.EVENT,
    modeline = false,
    data = data,
  })
end

--- Register a listener for the event. Thin wrapper so subsystems don't
--- each repeat the pattern string and group boilerplate.
--- @param name string used for the augroup, must be unique per subsystem
--- @param fn fun(args: table)
function M.on_tools_changed(name, fn)
  vim.api.nvim_create_autocmd("User", {
    pattern = M.EVENT,
    group = vim.api.nvim_create_augroup("nvim_config_tools_changed_" .. name, { clear = true }),
    callback = fn,
  })
end

return M
