-- Answers "is this tool actually installed" for a ToolSpec from
-- tools/registry.lua. Separate from the registry itself so the registry
-- stays pure data and this stays the only place that touches PATH.
local exe = require("util.executable")

local M = {}

--- @param spec table ToolSpec
--- @return boolean|nil nil means "not checkable" (e.g. java_debug via jdtls)
function M.installed(spec)
  if spec.exe == nil then
    return nil
  end
  if type(spec.exe) == "table" then
    return exe.all(spec.exe)
  end
  return exe.exists(spec.exe)
end

--- @param id string tool id from tools/registry.lua
--- @return boolean
function M.is_installed(id)
  local registry = require("tools.registry")
  local spec = registry.get(id)
  if not spec then
    return false
  end
  local status = M.installed(spec)
  return status == true
end

return M
