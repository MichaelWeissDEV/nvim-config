-- The whole "quiet by default" requirement lives here: missing optional
-- tools may only ever produce ONE notification per session, and only when
-- the user actually tried to use the feature. Real config bugs (Lua errors,
-- bad plugin API calls) must stay loud and are never routed through this
-- module's `once()` -- they should surface as normal Neovim errors/tracebacks.
local M = {}

local seen = {}

--- Show a notification exactly once per session for a given key.
--- @param key string stable identifier, e.g. "formatter-missing-cpp"
--- @param msg string
--- @param level? integer vim.log.levels.*
function M.once(key, msg, level)
  if seen[key] then
    return
  end
  seen[key] = true
  vim.notify(msg, level or vim.log.levels.WARN, { title = "nvim-config" })
end

--- Standard one-shot "feature needs a tool you don't have" message.
--- @param feature string human name, e.g. "C/C++ debugger"
--- @param tool string the missing binary/package, e.g. "codelldb"
--- @param install_hint? string e.g. ":ToolsInstall systems"
function M.missing_dependency(feature, tool, install_hint)
  local msg = string.format("%s not available: '%s' is not installed.", feature, tool)
  if install_hint then
    msg = msg .. string.format(" Install via %s.", install_hint)
  end
  M.once("missing:" .. feature .. ":" .. tool, msg, vim.log.levels.WARN)
end

--- Real configuration errors: always shown, never deduplicated, never hidden
--- behind pcall. Use this from xpcall handlers around plugin setup, not as a
--- substitute for letting genuine Lua errors propagate.
--- @param source string module/plugin name
--- @param err string
function M.config_error(source, err)
  vim.notify(string.format("[nvim-config] %s failed to load:\n%s", source, err), vim.log.levels.ERROR, {
    title = "nvim-config: configuration error",
  })
end

--- Reset the dedup cache (tests only).
function M._reset()
  seen = {}
end

return M
