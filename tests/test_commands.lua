-- Every zero-argument, read-only custom command must run without error.
-- (Commands that require an argument -- :ToolsInstall, :MasonInstall -- or
-- that perform a real install are intentionally not exercised here; that's
-- what a manual `./scripts/bootstrap.sh core` run is for.)
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

local SAFE_COMMANDS = {
  "NvimConfigHealth",
  "ToolsStatus",
  "NvimCommands",
  "NvimKeymaps",
  "LspStatus",
  "FormatterStatus",
  "LinterStatus",
  "DebuggerStatus",
  "NvimDocs",
  "RelativeNumbersToggle",
  "FormatEnable",
  "FormatDisable",
}

lib.run("commands: every safe custom command runs without error", function()
  local cmdreg = require("util.command_registry")
  local registered = {}
  for _, c in ipairs(cmdreg.all()) do
    registered[c.name] = true
  end

  for _, name in ipairs(SAFE_COMMANDS) do
    lib.assert_true(registered[name], name .. " is not registered in util.command_registry")
    local ok, err = pcall(vim.cmd, name)
    lib.assert_true(ok, name .. " raised an error: " .. tostring(err))
    pcall(vim.cmd, "close") -- these open a scratch/health buffer; close it again
  end
end)
