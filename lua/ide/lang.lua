-- Per-language and per-pack tooling, driven entirely by lua/languages/*.lua:
--
--   :LangInstall [target ...]     install everything for one or more languages,
--                                 packs (web, systems, jvm, ...), or 'all' --
--                                 language server(s), formatter, linter, debugger
--                                 (via Mason) and Tree-sitter parsers. No argument:
--                                 the current buffer's language, or a picker.
--   :LangInstallLsp [target ...]  install only the LSP server(s) and Tree-sitter
--                                 parsers for the given language(s), pack(s), or 'all'.
--   :LangInfo [target ...]        what a language or pack uses, what is installed,
--                                 what is attached to this buffer, and how to fix gaps.
--   :LangPacks                    list all language packs, member languages, and aliases.
--
-- The network is only touched by :LangInstall / :LangInstallLsp, and only when
-- run explicitly. Opening a file never prompts, never installs and never notifies
-- about missing tools -- that is the "quiet by default" contract (see README).
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
--- @param opts table|nil { all: boolean?, lsp_only: boolean? }
---   all = include LSP alternatives that are currently switched off by their `enabled` predicate
---   lsp_only = include only language servers (`lsp` and `extra_lsp`)
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
  if not opts.lsp_only then
    for _, id in ipairs(lang.formatters or {}) do
      add("formatter", id)
    end
    for _, id in ipairs(lang.linters or {}) do
      add("linter", id)
    end
    if lang.debugger then
      add("debugger", lang.debugger.tool)
    end
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

--- Normalize a target into a deduplicated list of LanguageSpecs and a display label.
--- Accepts:
---   - a single LanguageSpec table
---   - a list of LanguageSpec tables
---   - a string or list of strings: language id(s), alias(es) ("ts", "js", "py", ...),
---     filetype(s), pack name(s) ("web", "systems", "jvm", ...), or "all"
--- @param target table|string|string[]
--- @return table[]|nil langs, string|nil label_or_err
function M.resolve_targets(target)
  if type(target) == "table" and target.id and target.filetypes then
    return { target }, target.id
  end
  if type(target) == "table" and #target > 0 and type(target[1]) == "table" and target[1].id then
    local ids = {}
    for _, l in ipairs(target) do
      table.insert(ids, l.id)
    end
    return target, table.concat(ids, ", ")
  end

  local tokens = {}
  if type(target) == "string" then
    tokens = vim.split(target, "%s+", { trimempty = true })
  elseif type(target) == "table" then
    for _, item in ipairs(target) do
      if type(item) == "string" then
        for _, sub in ipairs(vim.split(item, "%s+", { trimempty = true })) do
          table.insert(tokens, sub)
        end
      end
    end
  end

  if #tokens == 0 then
    return nil, "No language or pack specified."
  end

  local out, seen = {}, {}
  local labels = {}
  local function push(lang)
    if lang and not seen[lang.id] then
      seen[lang.id] = true
      table.insert(out, lang)
    end
  end

  for _, raw in ipairs(tokens) do
    local tok = raw:lower()
    if tok == "all" then
      for _, l in ipairs(languages.all()) do
        push(l)
      end
      table.insert(labels, "all")
    else
      local pack = languages.by_pack(tok)
      local direct = languages.get(tok)
      -- When a pack name matches a single-language id (e.g. "python"), both
      -- resolve to the same language; when a pack has multiple languages
      -- (e.g. "web", "systems", "jvm"), pack resolution takes effect.
      if pack and (not direct or #pack > 1) then
        for _, l in ipairs(pack) do
          push(l)
        end
        table.insert(labels, tok)
      else
        local lang = languages.resolve(raw)
        if not lang then
          return nil,
            ("Unknown language or pack '%s'. See :LangInstall <Tab> or :LangPacks."):format(raw)
        end
        push(lang)
        table.insert(labels, lang.id)
      end
    end
  end

  return out, table.concat(labels, ", ")
end

--- What :LangInstall would do for `target` (a LanguageSpec, list of specs,
--- language/alias/pack name, or "all"), without doing it. Pure, so tests
--- can check it without any network.
--- @param target table|string|string[] LanguageSpec, LanguageSpec[], or target name(s)
--- @param opts table|nil { all: boolean?, lsp_only: boolean? }
--- @return { mason: string[], manual: table[], parsers: string[], needs_ts_cli: boolean, languages: table[] }
function M.plan(target, opts)
  local langs, err = M.resolve_targets(target)
  if not langs then
    error(err, 0)
  end
  local mason, manual, parsers = {}, {}, {}
  local seen_mason, seen_manual, seen_parser = {}, {}, {}
  for _, lang in ipairs(langs) do
    for _, ref in ipairs(M.tool_refs(lang, opts)) do
      local tool = ref.tool
      if detection.installed(tool) ~= true then
        if tool.mason then
          if not seen_mason[tool.mason] then
            seen_mason[tool.mason] = true
            table.insert(mason, tool.mason)
          end
        elseif tool.exe and not seen_manual[tool.id] then
          seen_manual[tool.id] = true
          table.insert(manual, tool)
        end
      end
    end
    for _, p in ipairs(lang.treesitter or {}) do
      if not seen_parser[p] and not M.parser_installed(p) then
        seen_parser[p] = true
        table.insert(parsers, p)
      end
    end
  end
  -- nvim-treesitter (main) compiles parsers with the `tree-sitter` CLI.
  -- Mason ships it, so a fresh machine needs nothing else but a C compiler.
  local needs_ts_cli = #parsers > 0 and not exe.exists("tree-sitter")
  return {
    mason = mason,
    manual = manual,
    parsers = parsers,
    needs_ts_cli = needs_ts_cli,
    languages = langs,
  }
end

--- Start Tree-sitter in every loaded buffer matching any of `langs`.
--- @param langs table[]
local function restart_treesitter(langs)
  local ft_set = {}
  for _, lang in ipairs(langs) do
    for _, ft in ipairs(lang.filetypes or {}) do
      ft_set[ft] = true
    end
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and ft_set[vim.bo[buf].filetype] then
      pcall(vim.treesitter.start, buf)
    end
  end
end

--- @param langs table[]
--- @param parsers string[]
local function install_parsers(langs, parsers)
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
      restart_treesitter(langs)
    end)
  end)
end

--- Install everything `target` needs that is not installed yet.
--- @param target table|string|string[] LanguageSpec, LanguageSpec[], or target name(s)
--- @param opts table|nil { all: boolean?, lsp_only: boolean? }
function M.install(target, opts)
  local langs, label = M.resolve_targets(target)
  if not langs then
    vim.notify(label, vim.log.levels.ERROR, { title = "nvim-config: LangInstall" })
    return
  end
  local plan = M.plan(langs, opts)
  local mason = vim.deepcopy(plan.mason)
  if plan.needs_ts_cli then
    table.insert(mason, "tree-sitter-cli")
  end
  local installer = require("tools.install")

  if #mason == 0 and #plan.parsers == 0 then
    vim.notify(
      ("%s: everything is already installed."):format(label)
        .. (#plan.manual > 0 and " (Some tools need a manual install -- see :LangInfo.)" or ""),
      vim.log.levels.INFO,
      { title = "nvim-config: LangInstall" }
    )
    return
  end

  -- Parsers go after Mason has finished, because Mason may be what puts
  -- the `tree-sitter` CLI on PATH in the first place.
  installer.install_packages(mason, {
    title = "LangInstall " .. label,
    on_done = function()
      install_parsers(langs, plan.parsers)
    end,
  })
  installer.report_manual(plan.manual)
end

--- The language of the current buffer, or nil.
--- @return table|nil
function M.current()
  return languages.by_filetype(vim.bo.filetype)
end

--- All completion candidates for :LangInstall / :LangInfo: "all", pack names,
--- canonical language IDs, and short aliases ("ts", "js", "py", ...).
--- @return string[]
function M.completion_items()
  local out, seen = {}, {}
  local function add_item(s)
    if not seen[s] then
      seen[s] = true
      table.insert(out, s)
    end
  end
  add_item("all")
  for _, pack in ipairs(languages.pack_names or {}) do
    add_item(pack)
  end
  for _, id in ipairs(languages.ids) do
    add_item(id)
  end
  local alias_keys = {}
  for alias in pairs(languages.aliases or {}) do
    table.insert(alias_keys, alias)
  end
  table.sort(alias_keys)
  for _, alias in ipairs(alias_keys) do
    add_item(alias)
  end
  return out
end

local function complete_languages(arglead)
  local candidates = M.completion_items()
  if vim.startswith(arglead, "-") then
    table.insert(candidates, 1, "--lsp")
  end
  return vim.tbl_filter(function(item)
    return vim.startswith(item, arglead)
  end, candidates)
end

--- Parse optional flags (such as `--lsp`) out of a command argument string.
--- @param raw_args string
--- @return string remaining_args, { lsp_only: boolean }
local function parse_install_args(raw_args)
  local parts = vim.split(raw_args or "", "%s+", { trimempty = true })
  local kept = {}
  local lsp_only = false
  for _, p in ipairs(parts) do
    if p == "--lsp" or p == "-l" then
      lsp_only = true
    else
      table.insert(kept, p)
    end
  end
  return table.concat(kept, " "), { lsp_only = lsp_only }
end

--- Resolve a :Lang* argument: one or more targets (language id, alias, pack,
--- or 'all'), or the current buffer's language, or an interactive picker.
--- @param arg string
--- @param fn fun(langs: table[], label: string)
local function with_targets(arg, fn)
  if arg ~= "" then
    local langs, label_or_err = M.resolve_targets(arg)
    if not langs then
      vim.notify(label_or_err, vim.log.levels.ERROR, { title = "nvim-config: LangInstall" })
      return
    end
    fn(langs, label_or_err)
    return
  end
  local lang = M.current()
  if lang then
    fn({ lang }, lang.id)
    return
  end
  local choices = { "all (every supported language)" }
  for _, pack in ipairs(languages.pack_names or {}) do
    local members = languages.packs[pack] or {}
    table.insert(choices, ("pack:%s (%s)"):format(pack, table.concat(members, ", ")))
  end
  for _, id in ipairs(languages.ids) do
    table.insert(choices, id)
  end
  vim.ui.select(choices, { prompt = "Language or Pack" }, function(choice)
    if not choice then
      return
    end
    local token = choice:match("^pack:(%S+)") or choice:match("^(%S+)")
    if token then
      local langs, label = M.resolve_targets(token)
      if langs then
        fn(langs, label)
      end
    end
  end)
end

--- Report lines for :LangInfo on a single language.
--- @param lang table LanguageSpec
--- @param bufnr integer|nil buffer to report attached clients for
--- @return string[]
function M.info_lines(lang, bufnr)
  local lines = { "# " .. lang.id, "" }
  table.insert(lines, "Filetypes: " .. table.concat(lang.filetypes, ", "))
  local aliases = languages.aliases_for(lang.id)
  if #aliases > 0 then
    table.insert(lines, "Aliases:   " .. table.concat(aliases, ", "))
  end
  local packs = languages.packs_for(lang.id)
  if #packs > 0 then
    table.insert(lines, "Packs:     " .. table.concat(packs, ", "))
  end
  table.insert(lines, "")
  table.insert(lines, "## Tools")
  table.insert(lines, "")
  local missing = false
  local refs = M.tool_refs(lang, { all = true })
  if #refs == 0 then
    table.insert(lines, "- (none)")
  end
  for _, ref in ipairs(refs) do
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

--- Report lines for :LangInfo on a pack, 'all', or multiple languages.
--- @param langs table[]
--- @param label string
--- @return string[]
function M.multi_info_lines(langs, label)
  local plan = M.plan(langs)
  local lines = {
    "# LangInfo: " .. label .. string.format(" (%d languages)", #langs),
    "",
    string.format(
      "Missing Mason packages (%d): %s",
      #plan.mason,
      #plan.mason > 0 and table.concat(plan.mason, ", ") or "none"
    ),
    string.format(
      "Missing Tree-sitter parsers (%d): %s",
      #plan.parsers,
      #plan.parsers > 0 and table.concat(plan.parsers, ", ") or "none"
    ),
    "",
    "Install everything missing in this selection: `:LangInstall " .. label .. "`",
    "Install only LSP servers + parsers:           `:LangInstallLsp " .. label .. "`",
    "",
    "## Languages",
    "",
  }
  for _, lang in ipairs(langs) do
    local lsp_name = lang.lsp and (tools.get(lang.lsp.tool) and tools.get(lang.lsp.tool).name or lang.lsp.tool) or "-"
    local lsp_ok = true
    if lang.lsp then
      local t = tools.get(lang.lsp.tool)
      lsp_ok = t ~= nil and detection.installed(t) == true
    end
    local status = lsp_ok and "OK" or "MISSING"
    if not lang.lsp then
      status = "~"
    end
    local aliases = languages.aliases_for(lang.id)
    local alias_str = #aliases > 0 and (" (aliases: " .. table.concat(aliases, ", ") .. ")") or ""
    table.insert(lines, string.format("- [%s] %-14s LSP: %-32s%s", status, lang.id, lsp_name, alias_str))
  end
  return lines
end

--- Report lines for :LangPacks (all packs, their member languages, and aliases).
--- @return string[]
function M.packs_lines()
  local lines = {
    "# Language Packs & Aliases",
    "",
    "Install any pack, language, alias, or everything at once:",
    "  `:LangInstall all`                -- every language (LSP, formatter, linter, debugger, parsers)",
    "  `:LangInstallLsp all`             -- every language's LSP server(s) and parsers only",
    "  `:LangInstall web`                -- an entire language pack",
    "  `:LangInstall cpp c asm go rust`  -- any combination of languages, aliases, or packs",
    "",
    "## Packs (`:LangInstall <pack>`)",
    "",
  }
  for _, pack in ipairs(languages.pack_names or {}) do
    local members = languages.packs[pack] or {}
    table.insert(lines, string.format("- **%-12s** (%d): %s", pack, #members, table.concat(members, ", ")))
  end
  table.insert(lines, "")
  table.insert(lines, "## Short Aliases (`:LangInstall <alias>`)")
  table.insert(lines, "")
  for _, lang in ipairs(languages.all()) do
    local aliases = languages.aliases_for(lang.id)
    if #aliases > 0 then
      table.insert(lines, string.format("- **%-14s** <- %s", lang.id, table.concat(aliases, ", ")))
    end
  end
  table.insert(lines, "")
  table.insert(lines, "## All Languages (" .. #languages.ids .. ")")
  table.insert(lines, "")
  table.insert(lines, table.concat(languages.ids, ", "))
  return lines
end

cmdreg.command({
  name = "LangInstall",
  desc = "Install language server(s), formatter, linter, debugger and Tree-sitter parsers via Mason "
    .. "for one or more languages, aliases (ts, js, py, rs, ...), packs (web, systems, jvm, ...), or 'all' "
    .. "(no arg: current buffer's language; --lsp: LSP + parsers only; !: include inactive alternatives; network)",
  category = "Tools",
  args = "[language|pack|all ...]",
  example = ":LangInstall web",
  opts = { nargs = "*", bang = true, complete = complete_languages },
  fn = function(opts)
    local target_str, flags = parse_install_args(opts.args)
    with_targets(target_str, function(langs, label)
      M.install(#langs == 1 and langs[1] or langs, {
        all = opts.bang,
        lsp_only = flags.lsp_only,
        label = label,
      })
    end)
  end,
})

cmdreg.command({
  name = "LangInstallLsp",
  desc = "Install only the LSP server(s) and Tree-sitter parsers for one or more languages, aliases, packs (web, systems, ...), or 'all' (network)",
  category = "Tools",
  args = "[language|pack|all ...]",
  example = ":LangInstallLsp all",
  opts = { nargs = "*", bang = true, complete = complete_languages },
  fn = function(opts)
    local target_str = parse_install_args(opts.args)
    with_targets(target_str, function(langs, label)
      M.install(#langs == 1 and langs[1] or langs, {
        all = opts.bang,
        lsp_only = true,
        label = label,
      })
    end)
  end,
})

cmdreg.command({
  name = "LangInfo",
  desc = "Show tools (installed or missing), parsers and attached servers for a language, alias, pack, or 'all' (no arg: current buffer)",
  category = "Tools",
  args = "[language|pack|all ...]",
  example = ":LangInfo rust",
  opts = { nargs = "*", complete = complete_languages },
  fn = function(opts)
    if opts.args == "packs" then
      scratch.open("nvim-config://lang-packs", M.packs_lines())
      return
    end
    local bufnr = vim.api.nvim_get_current_buf()
    with_targets(opts.args, function(langs, label)
      if #langs == 1 then
        scratch.open("nvim-config://lang-info/" .. langs[1].id, M.info_lines(langs[1], bufnr))
      else
        local slug = label:gsub("[^%w_-]+", "-")
        scratch.open("nvim-config://lang-info/" .. slug, M.multi_info_lines(langs, label))
      end
    end)
  end,
})

cmdreg.command({
  name = "LangPacks",
  desc = "List all language packs (web, systems, jvm, ...), their member languages, and short aliases (ts, js, py, ...)",
  category = "Tools",
  example = ":LangPacks",
  fn = function()
    scratch.open("nvim-config://lang-packs", M.packs_lines())
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
    lhs = "<leader>tA",
    rhs = "<cmd>LangInstall all<cr>",
    desc = "Install tools for all languages",
    group = "Tools",
  },
  {
    mode = "n",
    lhs = "<leader>tp",
    rhs = "<cmd>LangPacks<cr>",
    desc = "Language packs and aliases",
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
