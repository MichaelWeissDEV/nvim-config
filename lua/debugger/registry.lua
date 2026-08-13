-- Registers nvim-dap adapters/configurations from lua/languages/*.lua, one
-- filetype at a time, the first time debugging is actually used for that
-- filetype. nvim-dap itself has no concept of "lazy register" so we just
-- make sure we only ever call dap.adapters[x]/dap.configurations[x] once
-- per tool/filetype instead of eagerly registering all ~15 debuggers this
-- config knows about at startup.
local languages = require("languages.registry")
local tools = require("tools.registry")
local detection = require("tools.detection")
local notify = require("util.notify")

local M = {}

local registered_adapters = {}
local registered_filetypes = {}

--- @param filetype string
--- @return boolean true if a debugger is now ready to use for this filetype
function M.ensure_for_filetype(filetype)
  local lang = languages.by_filetype(filetype)
  if not lang or not lang.debugger then
    notify.once(
      "debug:no-debugger:" .. filetype,
      "No debugger configured for filetype '" .. filetype .. "'.",
      vim.log.levels.WARN
    )
    return false
  end

  -- Checked per invocation, not cached: a debug adapter installed
  -- mid-session works on the next <leader>d press without a restart. See
  -- the same note in plugins/linting.lua and tests/test_tools_refresh.lua.
  local tool = tools.get(lang.debugger.tool)
  if not tool or not detection.installed(tool) then
    notify.missing_dependency(
      (lang.id .. " debugger"),
      tool and tool.name or lang.debugger.tool,
      ":ToolsInstall " .. (tool and tool.profiles[1] or "core")
    )
    return false
  end

  local configurations = lang.debugger.configurations()
  if #configurations == 0 then
    notify.once(
      "debug:not-implemented:" .. filetype,
      string.format("Debugging for '%s' is not implemented yet (see notes in languages/%s.lua).", filetype, lang.id),
      vim.log.levels.WARN
    )
    return false
  end

  local dap = require("dap")

  if not registered_adapters[lang.debugger.tool] then
    dap.adapters[lang.debugger.tool] = lang.debugger.adapter()
    registered_adapters[lang.debugger.tool] = true
  end

  if not registered_filetypes[filetype] then
    dap.configurations[filetype] = configurations
    registered_filetypes[filetype] = true
  end

  return true
end

--- @return table[] every language with a debugger entry, annotated with tool install status -- for :DebuggerStatus
function M.all()
  local out = {}
  for _, lang in ipairs(languages.all()) do
    if lang.debugger then
      local tool = tools.get(lang.debugger.tool)
      table.insert(out, {
        language = lang.id,
        tool = tool and tool.name or lang.debugger.tool,
        installed = tool ~= nil and detection.installed(tool),
      })
    end
  end
  return out
end

return M
