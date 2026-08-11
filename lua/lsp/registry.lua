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

--- @return table<string, {filetypes: table<string,boolean>, root_markers: table<string,boolean>, settings: table, extra: table, tool: table}>
local function collect()
  local by_tool = {}

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
    local entry = by_tool[lsp_spec.tool]
    if not entry then
      entry = { filetypes = {}, root_markers = {}, settings = {}, extra = {}, tool = tool }
      by_tool[lsp_spec.tool] = entry
    end
    for _, ft in ipairs(lang.filetypes) do
      entry.filetypes[ft] = true
    end
    for _, marker in ipairs(lang.root_markers or { ".git" }) do
      entry.root_markers[marker] = true
    end
    if lsp_spec.settings then
      entry.settings = vim.tbl_deep_extend("force", entry.settings, lsp_spec.settings)
    end
    if lsp_spec.extra then
      entry.extra = vim.tbl_deep_extend("force", entry.extra, lsp_spec.extra)
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
  return by_tool
end

local function keys(set)
  local out = {}
  for k in pairs(set) do
    table.insert(out, k)
  end
  table.sort(out)
  return out
end

--- Build vim.lsp.config() tables and vim.lsp.enable() every server whose
--- binary is present. Called once at startup.
function M.setup()
  for tool_id, entry in pairs(collect()) do
    local extra = vim.deepcopy(entry.extra)
    local cmd = extra.cmd
    extra.cmd = nil
    if not cmd then
      cmd = type(entry.tool.exe) == "table" and entry.tool.exe or { entry.tool.exe }
    end

    local config = vim.tbl_deep_extend("force", {
      cmd = cmd,
      filetypes = keys(entry.filetypes),
      root_markers = keys(entry.root_markers),
      capabilities = capabilities.default(),
    }, extra)

    if next(entry.settings) ~= nil then
      config.settings = entry.settings
    end

    local ok, err = pcall(vim.lsp.config, tool_id, config)
    if not ok then
      require("util.notify").config_error("lsp.registry(" .. tool_id .. ")", tostring(err))
    else
      vim.lsp.enable(tool_id)
    end
  end
end

--- @return table[] one row per configured (installed) server, for :LspStatus
function M.configured()
  local out = {}
  for tool_id, entry in pairs(collect()) do
    table.insert(out, { id = tool_id, name = entry.tool.name, filetypes = keys(entry.filetypes) })
  end
  table.sort(out, function(a, b)
    return a.id < b.id
  end)
  return out
end

return M
