-- Single source of truth for "is this binary on PATH". Cached because the
-- language/tool registries call it repeatedly (per buffer, per statusline
-- redraw); vim.fn.executable() itself is cheap but we still don't want it
-- run hundreds of times per session.
local M = {}

local cache = {}

--- @param name string binary name, e.g. "clangd"
--- @return boolean
function M.exists(name)
  if name == nil or name == "" then
    return false
  end
  local cached = cache[name]
  if cached ~= nil then
    return cached
  end
  local found = vim.fn.executable(name) == 1
  cache[name] = found
  return found
end

--- Clear the cache (used by :ToolsInstall / :ToolsUpdate after installing
--- new binaries, and by tests).
function M.reset()
  cache = {}
end

--- @param names string[]
--- @return boolean true if all are present
function M.all(names)
  for _, name in ipairs(names) do
    if not M.exists(name) then
      return false
    end
  end
  return true
end

--- @param names string[]
--- @return string[] the subset that is missing
function M.missing(names)
  local out = {}
  for _, name in ipairs(names) do
    if not M.exists(name) then
      table.insert(out, name)
    end
  end
  return out
end

return M
