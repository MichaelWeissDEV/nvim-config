-- Every zero-argument, read-only custom command must run without error.
-- (Commands that install anything -- :ToolsInstall, :ToolsUpdate,
-- :LangInstall, :MasonInstall -- are intentionally not exercised here: they
-- touch the network. That's what a manual `./scripts/bootstrap.sh core` run
-- is for; tests/test_lang_tools.lua covers :LangInstall's planning offline.)
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
  -- With arguments: the first word is the registered command name.
  "LangInfo python",
  "LangInfo lua",
  "PythonInfo",
  "PythonLsp",
  "Pytest last",
  "MarkdownRender off",
}

lib.run("commands: every safe custom command runs without error", function()
  local cmdreg = require("util.command_registry")
  local registered = {}
  for _, c in ipairs(cmdreg.all()) do
    registered[c.name] = true
  end

  for _, invocation in ipairs(SAFE_COMMANDS) do
    local name = invocation:match("^%S+")
    lib.assert_true(registered[name], name .. " is not registered in util.command_registry")
    local ok, err = pcall(vim.cmd, invocation)
    lib.assert_true(ok, invocation .. " raised an error: " .. tostring(err))
    pcall(vim.cmd, "close") -- these open a scratch/health buffer; close it again
  end
end)
