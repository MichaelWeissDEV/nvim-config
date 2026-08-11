-- nvim-lint, driven by lua/languages/*.lua the same way conform is. Unlike
-- conform, nvim-lint has no built-in "skip if missing" behavior, so we
-- filter to installed linters ourselves on every trigger (not just once at
-- startup) so a linter installed mid-session via :ToolsInstall works
-- without restarting Neovim.
local lint = require("lint")
local languages = require("languages.registry")
local tools = require("tools.registry")
local detection = require("tools.detection")
local cmdreg = require("util.command_registry")
local scratch = require("util.scratch")

-- nvim-lint's built-in linter module names (verified against
-- mfussenegger/nvim-lint's lua/lint/linters/*.lua) that differ from our
-- tool ids. doc8 has no nvim-lint module at all, so RST linting is left to
-- esbonio's own LSP diagnostics.
local ENGINE_ALIAS = { golangci_lint = "golangcilint", clang_tidy = "clangtidy" }
local UNSUPPORTED = { doc8 = true }

local linters_by_ft = {}

for _, lang in ipairs(languages.all()) do
  if lang.linters and #lang.linters > 0 then
    local entries = {}
    for _, tool_id in ipairs(lang.linters) do
      if not UNSUPPORTED[tool_id] then
        local tool = tools.get(tool_id)
        if tool then
          table.insert(entries, { id = tool_id, engine = ENGINE_ALIAS[tool_id] or tool_id, tool = tool })
        end
      end
    end
    if #entries > 0 then
      for _, ft in ipairs(lang.filetypes) do
        linters_by_ft[ft] = entries
      end
    end
  end
end

local function installed_engine_names(ft)
  local entries = linters_by_ft[ft]
  if not entries then
    return {}
  end
  local names = {}
  for _, e in ipairs(entries) do
    if detection.installed(e.tool) then
      table.insert(names, e.engine)
    end
  end
  return names
end

vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
  callback = function()
    local names = installed_engine_names(vim.bo.filetype)
    if #names > 0 then
      lint.try_lint(names)
    end
  end,
})

cmdreg.command({
  name = "LinterStatus",
  desc = "Show which linter(s) are configured/available for the current buffer, and all linters by filetype",
  category = "Diagnostics",
  example = ":LinterStatus",
  fn = function()
    local lines = { "# Linter Status", "" }
    local fts = {}
    for ft in pairs(linters_by_ft) do
      table.insert(fts, ft)
    end
    table.sort(fts)
    for _, ft in ipairs(fts) do
      local names = {}
      for _, e in ipairs(linters_by_ft[ft]) do
        table.insert(names, string.format("%s%s", e.tool.name, detection.installed(e.tool) and "" or " (missing)"))
      end
      table.insert(lines, string.format("- %-16s %s", ft, table.concat(names, ", ")))
    end
    scratch.open("nvim-config://linter-status", lines)
  end,
})
