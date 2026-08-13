-- Registry integrity checks.
--
-- The registries are the single source of truth for LSP, formatting,
-- linting, debugging and every generated document. A typo in one of them
-- does not crash Neovim -- it produces a language that silently never gets
-- a formatter, or documentation that describes a tool that does not exist.
-- This module makes those failures loud and findable.
--
-- Two deliberate properties:
--   * It collects ALL problems instead of stopping at the first, because
--     fixing registry mistakes one `assert()` at a time is miserable.
--   * Its output is sorted, so the same broken registry always produces
--     byte-identical output -- diffable, and usable as a CI gate.
--
-- Runs independently of interactive startup: `nvim -l` can call it, the
-- docs generator gates on it, and tests drive it with synthetic registries.
local M = {}

--- @class IntegrityProblem
--- @field scope string e.g. "languages.python", "tools", "debugger.go"
--- @field message string

--- @param problems IntegrityProblem[]
--- @param scope string
--- @param message string
local function add(problems, scope, message)
  table.insert(problems, { scope = scope, message = message })
end

local VALID_TOOL_CATEGORIES = { lsp = true, formatter = true, linter = true, debugger = true }

--- Which registry field may reference which tool category. A language's
--- `formatters` list pointing at something registered as an LSP is a
--- mistake worth catching, not a coincidence.
local FIELD_CATEGORY = {
  lsp = "lsp",
  extra_lsp = "lsp",
  formatters = "formatter",
  linters = "linter",
  debugger = "debugger",
}

--- @param languages table languages.registry-like: .all(), .ids
--- @param tools table tools.registry-like: .get(), .all(), .profiles
--- @param opts table|nil { module_exists = fun(id): boolean }
--- @return IntegrityProblem[] sorted, deterministic
function M.check(languages, tools, opts)
  opts = opts or {}
  local problems = {}

  ------------------------------------------------------------------
  -- Tools registry
  ------------------------------------------------------------------
  local tool_ids = {}
  local valid_profiles = {}
  for _, profile in ipairs(tools.profiles or {}) do
    valid_profiles[profile] = true
  end

  for _, tool in ipairs(tools.all()) do
    local scope = "tools." .. tostring(tool.id)
    if type(tool.id) ~= "string" or tool.id == "" then
      add(problems, "tools", "a tool has a missing or empty id")
    elseif tool_ids[tool.id] then
      -- tools.registry's own add() already asserts on duplicates, so this
      -- is a backstop for synthetic registries and future refactors.
      add(problems, scope, "duplicate tool id")
    else
      tool_ids[tool.id] = tool
    end

    if not VALID_TOOL_CATEGORIES[tool.category] then
      add(problems, scope, "unknown category '" .. tostring(tool.category) .. "'")
    end
    if tool.mason ~= nil and (type(tool.mason) ~= "string" or tool.mason == "") then
      add(problems, scope, "mason package name must be a non-empty string when set")
    end
    if tool.exe ~= nil then
      if type(tool.exe) == "table" then
        if #tool.exe == 0 then
          add(problems, scope, "exe list must not be empty")
        end
        for _, e in ipairs(tool.exe) do
          if type(e) ~= "string" or e == "" then
            add(problems, scope, "exe list entries must be non-empty strings")
          end
        end
      elseif type(tool.exe) ~= "string" or tool.exe == "" then
        add(problems, scope, "exe must be a non-empty string or a list of them")
      end
    end
    if type(tool.profiles) ~= "table" or #tool.profiles == 0 then
      add(problems, scope, "must belong to at least one profile")
    else
      for _, profile in ipairs(tool.profiles) do
        if not valid_profiles[profile] then
          add(problems, scope, "unknown profile '" .. tostring(profile) .. "'")
        end
      end
    end
  end

  ------------------------------------------------------------------
  -- Language registry
  ------------------------------------------------------------------
  local seen_ids = {}
  local filetype_owner = {}

  --- Validate one tool reference from a language spec.
  local function check_tool_ref(scope, field, tool_id)
    if type(tool_id) ~= "string" or tool_id == "" then
      add(problems, scope, field .. " must reference a tool id string")
      return
    end
    local tool = tool_ids[tool_id]
    if not tool then
      add(problems, scope, field .. " references unknown tool '" .. tool_id .. "'")
      return
    end
    local expected = FIELD_CATEGORY[field:gsub("%[%d+%]$", "")]
    -- A tool satisfies the reference if the role is its primary category
    -- or one of its declared secondary ones (`also`), so genuinely
    -- multi-role binaries like ktlint and taplo validate cleanly while a
    -- real mistake -- pointing `formatters` at a debug adapter -- does not.
    if expected and not (tool.categories and tool.categories[expected]) then
      add(
        problems,
        scope,
        ("%s references '%s', which is registered as a %s, not a %s"):format(field, tool_id, tool.category, expected)
      )
    end
  end

  for _, lang in ipairs(languages.all()) do
    local id = lang.id
    local scope = "languages." .. tostring(id)

    if type(id) ~= "string" or id == "" then
      add(problems, "languages", "a language has a missing or empty id")
    elseif seen_ids[id] then
      add(problems, scope, "duplicate language id")
    else
      seen_ids[id] = true
    end

    if opts.module_exists and type(id) == "string" and id ~= "" and not opts.module_exists(id) then
      add(problems, scope, "registered in LANGUAGE_IDS but lua/languages/" .. id .. ".lua does not exist")
    end

    -- filetypes
    if type(lang.filetypes) ~= "table" or #lang.filetypes == 0 then
      add(problems, scope, "filetypes must be a non-empty list")
    else
      local seen_ft = {}
      for _, ft in ipairs(lang.filetypes) do
        if type(ft) ~= "string" or ft == "" then
          add(problems, scope, "filetype entries must be non-empty strings")
        elseif seen_ft[ft] then
          add(problems, scope, "duplicate filetype '" .. ft .. "' within this spec")
        else
          seen_ft[ft] = true
          local owner = filetype_owner[ft]
          if owner and owner ~= id then
            -- Last-writer-wins here silently decides which language's LSP
            -- and formatters a buffer gets. Not something to leave implicit.
            add(problems, scope, ("filetype '%s' is already claimed by language '%s'"):format(ft, owner))
          else
            filetype_owner[ft] = id
          end
        end
      end
    end

    -- root markers
    if lang.root_markers ~= nil then
      if type(lang.root_markers) ~= "table" or #lang.root_markers == 0 then
        add(problems, scope, "root_markers must be a non-empty list when set")
      else
        local validate = require("lsp.registry").validate_root_marker
        for i, marker in ipairs(lang.root_markers) do
          local ok, why = validate(marker)
          if not ok then
            add(problems, scope, ("root_markers[%d]: %s"):format(i, why))
          end
        end
      end
    end

    -- tool references
    if lang.lsp ~= nil then
      if type(lang.lsp) ~= "table" then
        add(problems, scope, "lsp must be a table")
      else
        check_tool_ref(scope, "lsp", lang.lsp.tool)
      end
    end
    if lang.extra_lsp ~= nil then
      if type(lang.extra_lsp) ~= "table" then
        add(problems, scope, "extra_lsp must be a list")
      else
        for i, spec in ipairs(lang.extra_lsp) do
          check_tool_ref(scope, ("extra_lsp[%d]"):format(i), type(spec) == "table" and spec.tool or spec)
        end
      end
    end
    for _, field in ipairs({ "formatters", "linters" }) do
      if lang[field] ~= nil then
        if type(lang[field]) ~= "table" then
          add(problems, scope, field .. " must be a list")
        else
          for i, tool_id in ipairs(lang[field]) do
            check_tool_ref(scope, ("%s[%d]"):format(field, i), tool_id)
          end
        end
      end
    end

    -- debugger
    if lang.debugger ~= nil then
      if type(lang.debugger) ~= "table" then
        add(problems, scope, "debugger must be a table")
      else
        check_tool_ref(scope, "debugger", lang.debugger.tool)
        if type(lang.debugger.adapter) ~= "function" then
          add(problems, scope, "debugger.adapter must be a function")
        end
        if type(lang.debugger.configurations) ~= "function" then
          add(problems, scope, "debugger.configurations must be a function")
        else
          local ok, configs = pcall(lang.debugger.configurations)
          if not ok then
            add(problems, scope, "debugger.configurations() raised an error")
          elseif type(configs) ~= "table" then
            add(problems, scope, "debugger.configurations() must return a list")
          else
            for i, config in ipairs(configs) do
              if type(config) ~= "table" then
                add(problems, scope, ("debugger.configurations()[%d] must be a table"):format(i))
              elseif config.type ~= lang.debugger.tool then
                -- nvim-dap resolves dap.adapters[config.type], and this
                -- config registers adapters under the tool id.
                add(
                  problems,
                  scope,
                  ("debugger.configurations()[%d].type is '%s' but adapters are registered under '%s'"):format(
                    i,
                    tostring(config.type),
                    tostring(lang.debugger.tool)
                  )
                )
              end
            end
          end
        end
      end
    end

    if lang.keymaps ~= nil and type(lang.keymaps) ~= "function" then
      add(problems, scope, "keymaps must be a function")
    end
  end

  -- Deterministic ordering: same registry, same output, every run.
  table.sort(problems, function(a, b)
    if a.scope ~= b.scope then
      return a.scope < b.scope
    end
    return a.message < b.message
  end)
  return problems
end

--- Check the real registries of this config.
--- @return IntegrityProblem[]
function M.check_current()
  local languages = require("languages.registry")
  return M.check(languages, require("tools.registry"), {
    -- Resolve through 'runtimepath' rather than stdpath("config"): the
    -- repo is not necessarily installed at stdpath("config") (CI and the
    -- test suite run it with `nvim -u <repo>/init.lua`), and checking the
    -- wrong root reported every single language as missing.
    module_exists = function(id)
      return #vim.api.nvim_get_runtime_file("lua/languages/" .. id .. ".lua", false) > 0
    end,
  })
end

--- @param problems IntegrityProblem[]
--- @return string[] human-readable lines
function M.format(problems)
  if #problems == 0 then
    return { "Registry integrity: OK" }
  end
  local lines = { ("Registry integrity: %d problem(s)"):format(#problems), "" }
  for _, p in ipairs(problems) do
    table.insert(lines, ("  %s: %s"):format(p.scope, p.message))
  end
  return lines
end

return M
