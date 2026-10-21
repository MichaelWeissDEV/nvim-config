-- Per-language tooling, driven entirely by lua/languages/*.lua:
--
--   :LangInstall [lang]   install everything one language needs -- language
--                         server(s), formatter, linter, debugger (via Mason)
--                         and its Tree-sitter parsers. No argument: the
--                         current buffer's language, or a picker.
--   :LangInfo [lang]      what that language uses, what is installed, what
--                         is attached to this buffer, and how to fix gaps.
--
-- The network is only touched by :LangInstall, and only when run. Opening a
-- file never prompts, never installs and never notifies about missing tools
-- -- that is the "quiet by default" contract (see README).
local languages = require("languages.registry")
local tools = require("tools.registry")
local detection = require("tools.detection")
local cmdreg = require("util.command_registry")
local km = require("util.keymap_registry")
local scratch = require("util.scratch")
local exe = require("util.executable")

local M = {}

--- Every tool reference of a language, labelled by role, in display order.
--- @param lang table LanguageSpec
--- @param opts table|nil { all: boolean? } all = include LSP alternatives
---   that are currently switched off by their `enabled` predicate
--- @return { role: string, tool: table, active: boolean }[]
function M.tool_refs(lang, opts)
  opts = opts or {}
  local refs = {}
  local function add(role, tool_id, enabled_fn)
    local tool = tools.get(tool_id)
    if not tool then
      return
    end
    local active = enabled_fn == nil or enabled_fn() == true
    if active or opts.all then
      table.insert(refs, { role = role, tool = tool, active = active })
    end
  end
  if lang.lsp then
    add("lsp", lang.lsp.tool, lang.lsp.enabled)
  end
  for _, spec in ipairs(lang.extra_lsp or {}) do
    add("lsp", spec.tool, spec.enabled)
  end
  for _, id in ipairs(lang.formatters or {}) do
    add("formatter", id)
  end
  for _, id in ipairs(lang.linters or {}) do
    add("linter", id)
  end
  if lang.debugger then
    add("debugger", lang.debugger.tool)
  end
  return refs
end

--- Is a Tree-sitter parser available (bundled with Neovim or installed)?
--- @param name string
--- @return boolean
function M.parser_installed(name)
  local ok, loaded = pcall(vim.treesitter.language.add, name)
  return ok and loaded == true
end

--- What :LangInstall would do for `lang`, without doing it. Pure, so tests
--- can check it without any network.
--- @param lang table LanguageSpec
--- @param opts table|nil { all: boolean? }
--- @return { mason: string[], manual: table[], parsers: string[], needs_ts_cli: boolean }
function M.plan(lang, opts)
  local mason, manual, seen = {}, {}, {}
  for _, ref in ipairs(M.tool_refs(lang, opts)) do
    local tool = ref.tool
    if detection.installed(tool) ~= true then
      if tool.mason then
        if not seen[tool.mason] then
          seen[tool.mason] = true
          table.insert(mason, tool.mason)
        end
      elseif tool.exe and not seen["manual:" .. tool.id] then
        seen["manual:" .. tool.id] = true
        table.insert(manual, tool)
      end
    end
  end
  local parsers = {}
  for _, p in ipairs(lang.treesitter or {}) do
    if not M.parser_installed(p) then
      table.insert(parsers, p)
    end
  end
  -- nvim-treesitter (main) compiles parsers with the `tree-sitter` CLI.
  -- Mason ships it, so a fresh machine needs nothing else but a C compiler.
  local needs_ts_cli = #parsers > 0 and not exe.exists("tree-sitter")
  return { mason = mason, manual = manual, parsers = parsers, needs_ts_cli = needs_ts_cli }
end

--- Start Tree-sitter in every loaded buffer of `lang` (after a parser install).
local function restart_treesitter(lang)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(lang.filetypes, vim.bo[buf].filetype) then
      pcall(vim.treesitter.start, buf)
    end
  end
end

local function install_parsers(lang, parsers)
  if #parsers == 0 then
    return
  end
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    vim.notify("nvim-treesitter is not available; cannot install parsers.", vim.log.levels.ERROR)
    return
  end
  vim.notify("Installing Tree-sitter parser(s): " .. table.concat(parsers, ", "), vim.log.levels.INFO, {
    title = "nvim-config: LangInstall",
  })
  ts.install(parsers):await(function(err)
    vim.schedule(function()
      if err then
        vim.notify(
          "Tree-sitter parser install failed: " .. tostring(err) .. "\nNeeds a C compiler; see docs/treesitter.md.",
          vim.log.levels.WARN,
          { title = "nvim-config: LangInstall" }
        )
        return
      end
      restart_treesitter(lang)
    end)
  end)
end

--- Install everything `lang` needs that is not installed yet.
--- @param lang table LanguageSpec
--- @param opts table|nil { all: boolean? }
function M.install(lang, opts)
  local plan = M.plan(lang, opts)
  local mason = vim.deepcopy(plan.mason)
  if plan.needs_ts_cli then
    table.insert(mason, "tree-sitter-cli")
  end
  local installer = require("tools.install")

  if #mason == 0 and #plan.parsers == 0 then
    vim.notify(
      ("%s: everything is already installed."):format(lang.id)
        .. (#plan.manual > 0 and " (Some tools need a manual install -- see :LangInfo.)" or ""),
      vim.log.levels.INFO,
      { title = "nvim-config: LangInstall" }
    )
    return
  end

  -- Parsers go after Mason has finished, because Mason may be what puts
  -- the `tree-sitter` CLI on PATH in the first place.
  installer.install_packages(mason, {
    title = "LangInstall " .. lang.id,
    on_done = function()
      install_parsers(lang, plan.parsers)
    end,
  })
  installer.report_manual(plan.manual)
end

--- The language of the current buffer, or nil.
--- @return table|nil
function M.current()
  return languages.by_filetype(vim.bo.filetype)
end

--- Resolve a :Lang* argument: an id, or the current buffer, or a picker.
--- @param arg string
--- @param fn fun(lang: table)
local function with_language(arg, fn)
  if arg ~= "" then
    local lang = languages.get(arg) or languages.by_filetype(arg)
    if not lang then
      vim.notify("Unknown language '" .. arg .. "'. See :LangInstall <Tab>.", vim.log.levels.ERROR)
      return
    end
    fn(lang)
    return
  end
  local lang = M.current()
  if lang then
    fn(lang)
    return
  end
  vim.ui.select(languages.ids, { prompt = "Language" }, function(choice)
    if choice then
      fn(languages.get(choice))
    end
  end)
end

local function complete_languages(arglead)
  return vim.tbl_filter(function(id)
    return vim.startswith(id, arglead)
  end, languages.ids)
end

--- Report lines for :LangInfo.
--- @param lang table LanguageSpec
--- @param bufnr integer|nil buffer to report attached clients for
--- @return string[]
function M.info_lines(lang, bufnr)
  local lines = { "# " .. lang.id, "" }
  table.insert(lines, "Filetypes: " .. table.concat(lang.filetypes, ", "))
  table.insert(lines, "")
  table.insert(lines, "## Tools")
  table.insert(lines, "")
  local missing = false
  for _, ref in ipairs(M.tool_refs(lang, { all = true })) do
    local status = detection.installed(ref.tool)
    local glyph = status == nil and "~" or (status and "OK" or "MISSING")
    if status == false and ref.active then
      missing = true
    end
    local how = ""
    if status == false then
      how = ref.tool.mason and (" -- Mason: " .. ref.tool.mason) or (" -- manual: " .. (ref.tool.note or "see docs"))
    end
    table.insert(
      lines,
      string.format(
        "- [%s] %-10s %s%s%s",
        glyph,
        ref.role,
        ref.tool.name,
        ref.active and "" or " (inactive alternative)",
        how
      )
    )
  end
  table.insert(lines, "")
  table.insert(lines, "## Tree-sitter parsers")
  table.insert(lines, "")
  if not lang.treesitter or #lang.treesitter == 0 then
    table.insert(lines, "- (none)")
  end
  for _, p in ipairs(lang.treesitter or {}) do
    local ok = M.parser_installed(p)
    missing = missing or not ok
    table.insert(lines, string.format("- [%s] %s", ok and "OK" or "MISSING", p))
  end
  if bufnr and vim.tbl_contains(lang.filetypes, vim.bo[bufnr].filetype) then
    table.insert(lines, "")
    table.insert(lines, "## Attached to this buffer")
    table.insert(lines, "")
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    if #clients == 0 then
      table.insert(lines, "- (no language server)")
    end
    for _, c in ipairs(clients) do
      table.insert(lines, string.format("- %s (root: %s)", c.name, c.root_dir or "single file"))
    end
  end
  if lang.notes then
    table.insert(lines, "")
    table.insert(lines, "Notes: " .. lang.notes)
  end
  table.insert(lines, "")
  if missing then
    table.insert(
      lines,
      "Install what is missing: :LangInstall " .. lang.id .. "   (or <leader>tl in a " .. lang.id .. " buffer)"
    )
  else
    table.insert(lines, "Everything this language uses is installed.")
  end
  return lines
end

cmdreg.command({
  name = "LangInstall",
  desc = "Install a language's language server, formatter, linter, debugger and Tree-sitter parsers via Mason "
    .. "(no arg: current buffer's language; ! also installs inactive alternatives; network)",
  category = "Tools",
  args = "[language]",
  example = ":LangInstall python",
  opts = { nargs = "?", bang = true, complete = complete_languages },
  fn = function(opts)
    with_language(opts.args, function(lang)
      M.install(lang, { all = opts.bang })
    end)
  end,
})

cmdreg.command({
  name = "LangInfo",
  desc = "Show a language's tools (installed or missing), parsers and attached servers (no arg: current buffer)",
  category = "Tools",
  args = "[language]",
  example = ":LangInfo rust",
  opts = { nargs = "?", complete = complete_languages },
  fn = function(opts)
    local bufnr = vim.api.nvim_get_current_buf()
    with_language(opts.args, function(lang)
      scratch.open("nvim-config://lang-info/" .. lang.id, M.info_lines(lang, bufnr))
    end)
  end,
})

km.map_many({
  {
    mode = "n",
    lhs = "<leader>tl",
    rhs = "<cmd>LangInstall<cr>",
    desc = "Install tools for this language",
    group = "Tools",
  },
  {
    mode = "n",
    lhs = "<leader>ti",
    rhs = "<cmd>LangInfo<cr>",
    desc = "Language info / missing tools",
    group = "Tools",
  },
  { mode = "n", lhs = "<leader>ts", rhs = "<cmd>ToolsStatus<cr>", desc = "Status of every tool", group = "Tools" },
  { mode = "n", lhs = "<leader>tm", rhs = "<cmd>Mason<cr>", desc = "Mason installer UI", group = "Tools" },
  { mode = "n", lhs = "<leader>tL", rhs = "<cmd>LspStatus<cr>", desc = "LSP status", group = "Tools" },
})

return M
