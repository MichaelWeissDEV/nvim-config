-- Turns lua/languages/*.lua entries into native vim.lsp.config()/enable()
-- calls. This is the ONLY place that talks to vim.lsp.config -- language
-- files never call it themselves, so "which servers exist" always matches
-- the language registry.
--
-- Design note: this config deliberately does NOT vendor nvim-lspconfig.
-- Every server's cmd/filetypes/root_markers is already known from
-- languages.registry (we wrote them once, per language, for docs anyway),
-- so pulling in ~150 files of default configs we'd mostly override bought
-- nothing. Native vim.lsp.config()/vim.lsp.enable() (stable since Neovim
-- 0.11) already does the per-filetype lazy client start we want -- a
-- server is only spawned when a matching buffer is opened AND a root
-- marker is found, so "on-demand" comes for free. mason-lspconfig is
-- skipped too: its automatic_enable defaults to on in 2.x and would start
-- servers based on what Mason has installed, bypassing our own
-- executable-gated registry.
local languages = require("languages.registry")
local tools = require("tools.registry")
local detection = require("tools.detection")
local capabilities = require("lsp.capabilities")

local M = {}

--- Is `marker` a valid root-marker entry? Either a non-empty string, or a
--- non-empty array of non-empty strings (Neovim treats a nested list as one
--- priority tier: any of those markers, all outranking the next entry).
--- @param marker any
--- @return boolean ok, string|nil why
function M.validate_root_marker(marker)
  if type(marker) == "string" then
    if marker == "" then
      return false, "root marker must be a non-empty string"
    end
    return true
  end
  if type(marker) == "table" then
    if #marker == 0 then
      return false, "root marker group must be a non-empty array"
    end
    for i, inner in ipairs(marker) do
      if type(inner) ~= "string" or inner == "" then
        return false, "root marker group entry " .. i .. " must be a non-empty string"
      end
    end
    return true
  end
  return false, "root marker must be a string or an array of strings, got " .. type(marker)
end

--- @return table<string, table>, string[] entries keyed by tool id, plus conflict messages
local function collect()
  local by_tool = {}
  local conflicts = {}

  local function add(lang, lsp_spec)
    local tool = tools.get(lsp_spec.tool)
    if not tool then
      require("util.notify").config_error(
        "languages." .. lang.id,
        "lsp.tool '" .. lsp_spec.tool .. "' has no entry in tools.registry"
      )
      return
    end
    if not detection.installed(tool) then
      -- tool not installed: silently skip. This is the "no error when an
      -- optional dependency is missing" requirement -- visible only via
      -- :ToolsStatus / :checkhealth nvim-config.
      return
    end

    local root_markers = lang.root_markers or { ".git" }
    for i, marker in ipairs(root_markers) do
      local ok, why = M.validate_root_marker(marker)
      if not ok then
        table.insert(conflicts, ("languages.%s: root_markers[%d]: %s"):format(lang.id, i, why))
      end
    end

    local entry = by_tool[lsp_spec.tool]
    if not entry then
      by_tool[lsp_spec.tool] = {
        -- Ordered list, not a set: root-marker order is declared priority
        -- (a project's pyproject.toml must outrank its .git), and sorting
        -- or set-ifying it silently destroys that.
        root_markers = vim.deepcopy(root_markers),
        filetypes = {},
        filetype_seen = {},
        settings = lsp_spec.settings and vim.deepcopy(lsp_spec.settings) or nil,
        extra = lsp_spec.extra and vim.deepcopy(lsp_spec.extra) or nil,
        tool = tool,
        owner = lang.id, -- which language first configured this server
      }
      entry = by_tool[lsp_spec.tool]
    else
      -- A server shared by several languages (clangd for c+cpp, vtsls for
      -- javascript+typescript). Filetypes legitimately merge; everything
      -- that configures the *server* must agree, because vim.lsp.config()
      -- holds exactly one config per name. Silently deep-extending them
      -- made the result depend on language load order.
      local function require_equal(field, a, b)
        if not vim.deep_equal(a, b) then
          table.insert(
            conflicts,
            ("LSP '%s' is shared by languages '%s' and '%s' but their %s differ; "):format(
              lsp_spec.tool,
              entry.owner,
              lang.id,
              field
            ) .. "server-wide configuration for a shared LSP must be identical"
          )
        end
      end
      require_equal("root_markers", entry.root_markers, root_markers)
      require_equal("lsp.settings", entry.settings, lsp_spec.settings)
      require_equal("lsp.extra", entry.extra, lsp_spec.extra)
    end

    -- Filetypes: union, first-seen order, deduplicated -- deterministic
    -- without imposing an alphabetical order nobody asked for.
    for _, ft in ipairs(lang.filetypes) do
      if not entry.filetype_seen[ft] then
        entry.filetype_seen[ft] = true
        table.insert(entry.filetypes, ft)
      end
    end
  end

  for _, lang in ipairs(languages.all()) do
    if lang.lsp then
      add(lang, lang.lsp)
    end
    -- extra_lsp: additional LSP clients attached alongside the primary one
    -- for the same filetypes (e.g. Python's "ty" running next to
    -- basedpyright) -- Neovim natively supports multiple attached clients
    -- per buffer, so this needs no special dispatch beyond also enabling
    -- the second server.
    if lang.extra_lsp then
      for _, lsp_spec in ipairs(lang.extra_lsp) do
        add(lang, lsp_spec)
      end
    end
  end
  return by_tool, conflicts
end

M._collect = collect

--- Build the vim.lsp.config() table for one collected entry. Split out so
--- tests can inspect exactly what would be handed to Neovim without
--- actually enabling a server.
--- @param entry table
--- @return table
local function build_config(entry)
  local extra = entry.extra and vim.deepcopy(entry.extra) or {}
  local cmd = extra.cmd
  extra.cmd = nil
  if not cmd then
    cmd = type(entry.tool.exe) == "table" and entry.tool.exe or { entry.tool.exe }
  end

  local config = vim.tbl_deep_extend("force", {
    cmd = cmd,
    filetypes = vim.deepcopy(entry.filetypes),
    root_markers = vim.deepcopy(entry.root_markers),
    capabilities = capabilities.default(),
  }, extra)

  if entry.settings and next(entry.settings) ~= nil then
    config.settings = vim.deepcopy(entry.settings)
  end
  return config
end

M._build_config = build_config

--- Sorted tool ids, so setup() is deterministic regardless of table order.
local function sorted_ids(by_tool)
  local ids = {}
  for id in pairs(by_tool) do
    table.insert(ids, id)
  end
  table.sort(ids)
  return ids
end

--- Build vim.lsp.config() tables and vim.lsp.enable() every server whose
--- binary is present.
---
--- Idempotent: safe to call again after tools are installed at runtime
--- (see lua/tools/refresh.lua). vim.lsp.config() replaces a name's config
--- rather than accumulating, and vim.lsp.enable() on an already-enabled
--- name is a no-op, so re-running does not duplicate anything or restart
--- clients that are already attached.
function M.setup()
  local by_tool, conflicts = collect()

  for _, message in ipairs(conflicts) do
    require("util.notify").config_error("lsp.registry", message)
  end

  for _, tool_id in ipairs(sorted_ids(by_tool)) do
    local ok, err = pcall(vim.lsp.config, tool_id, build_config(by_tool[tool_id]))
    if not ok then
      require("util.notify").config_error("lsp.registry(" .. tool_id .. ")", tostring(err))
    else
      vim.lsp.enable(tool_id)
    end
  end
end

--- Re-run setup() after the set of installed tools changed. Separate name
--- so the intent is readable at call sites even though the work is the same.
function M.refresh()
  M.setup()
end

--- @return table[] one row per configured (installed) server, for :LspStatus
function M.configured()
  local by_tool = collect()
  local out = {}
  for _, tool_id in ipairs(sorted_ids(by_tool)) do
    local entry = by_tool[tool_id]
    table.insert(out, { id = tool_id, name = entry.tool.name, filetypes = vim.deepcopy(entry.filetypes) })
  end
  return out
end

return M
