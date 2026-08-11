-- :ToolsStatus command + the "Formatters/Linters/Debuggers/LSP" sections of
-- :checkhealth nvim-config. Both read the same tools.registry + detection
-- data so the two views can never drift apart.
local registry = require("tools.registry")
local detection = require("tools.detection")
local cmdreg = require("util.command_registry")
local scratch = require("util.scratch")

local M = {}

local CATEGORY_LABEL = {
  lsp = "Language Servers",
  formatter = "Formatters",
  linter = "Linters",
  debugger = "Debuggers",
}

--- @return table<string, table[]> tools grouped by category, each entry annotated with .status
function M.grouped()
  local groups = { lsp = {}, formatter = {}, linter = {}, debugger = {} }
  for _, spec in ipairs(registry.all()) do
    local status = detection.installed(spec)
    table.insert(groups[spec.category], vim.tbl_extend("force", {}, spec, { status = status }))
  end
  return groups
end

local function status_glyph(status)
  if status == nil then
    return "~"
  end
  return status and "OK" or "MISSING"
end

--- Used by config/health.lua so :checkhealth nvim-config shows the same data.
function M.health_report()
  local groups = M.grouped()
  for _, category in ipairs({ "lsp", "formatter", "linter", "debugger" }) do
    vim.health.start(CATEGORY_LABEL[category])
    for _, t in ipairs(groups[category]) do
      if t.status == true then
        vim.health.ok(t.name)
      elseif t.status == false then
        vim.health.warn(t.name .. " not installed", "Run :ToolsInstall " .. (t.profiles[1] or "core") .. " (or install manually" .. (t.note and (": " .. t.note) or "") .. ")")
      end -- status == nil: not independently checkable, skip
    end
  end
end

cmdreg.command({
  name = "ToolsStatus",
  desc = "Show installed/missing status for every LSP/formatter/linter/debugger this config knows about",
  category = "Tools",
  example = ":ToolsStatus",
  fn = function()
    local groups = M.grouped()
    local lines = { "# Tools Status", "" }
    for _, category in ipairs({ "lsp", "formatter", "linter", "debugger" }) do
      table.insert(lines, "## " .. CATEGORY_LABEL[category])
      table.insert(lines, "")
      for _, t in ipairs(groups[category]) do
        table.insert(lines, string.format("- [%s] %-28s (%s)", status_glyph(t.status), t.name, table.concat(t.profiles, ",")))
      end
      table.insert(lines, "")
    end
    scratch.open("nvim-config://tools-status", lines)
  end,
})

return M
