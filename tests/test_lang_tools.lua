-- :LangInstall / :LangInfo planning, and keymap uniqueness.
--
-- Only M.plan() is exercised -- it decides what an install WOULD fetch and
-- never touches Mason or the network. PATH is emptied so every tool counts
-- as missing, whatever this machine has installed.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("lang tools: install plan per language, info report, unique keymaps", function()
  local exe = require("util.executable")
  local lang_tools = require("ide.lang")
  local languages = require("languages.registry")

  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")
  local saved_path = vim.env.PATH
  local saved_choice = vim.g.nvim_config_python_lsp

  local ok, err = pcall(function()
    vim.env.PATH = tmp
    vim.g.nvim_config_python_lsp = nil
    exe.reset()

    ------------------------------------------------------------------
    -- 1. python: active tools only, Mason packages deduplicated
    --    (ruff + ruff format are one package)
    ------------------------------------------------------------------
    local python = languages.get("python")
    local plan = lang_tools.plan(python)
    lib.assert_eq(table.concat(plan.mason, ","), "ty,ruff,debugpy", "python install plan")
    lib.assert_eq(#plan.manual, 0, "python needs nothing outside Mason")
    lib.assert_eq(plan.needs_ts_cli, #plan.parsers > 0, "parsers to build => tree-sitter CLI needed (none on PATH)")

    local full = lang_tools.plan(python, { all = true })
    lib.assert_eq(table.concat(full.mason, ","), "ty,ruff,basedpyright,debugpy", ":LangInstall! includes alternatives")

    vim.g.nvim_config_python_lsp = "basedpyright"
    lib.assert_eq(
      table.concat(lang_tools.plan(python).mason, ","),
      "ruff,basedpyright,debugpy",
      "the plan follows the chosen type checker"
    )
    vim.g.nvim_config_python_lsp = nil

    ------------------------------------------------------------------
    -- 2. tools Mason cannot install are reported, not attempted
    ------------------------------------------------------------------
    local ocaml = lang_tools.plan(languages.get("ocaml"))
    local manual = {}
    for _, t in ipairs(ocaml.manual) do
      table.insert(manual, t.id)
    end
    lib.assert_true(vim.tbl_contains(manual, "ocamllsp"), "ocamllsp is a manual install")
    lib.assert_true(not vim.tbl_contains(ocaml.mason, "ocamllsp"), "a manual tool never becomes a Mason package")

    ------------------------------------------------------------------
    -- 3. every language plans without error, and every Mason package
    --    in a plan comes from the tool registry
    ------------------------------------------------------------------
    local known = {}
    for _, t in ipairs(require("tools.registry").all()) do
      if t.mason then
        known[t.mason] = true
      end
    end
    for _, lang in ipairs(languages.all()) do
      local p = lang_tools.plan(lang, { all = true })
      for _, pkg in ipairs(p.mason) do
        lib.assert_true(known[pkg], lang.id .. ": plan contains unregistered package " .. pkg)
      end
      local lines = lang_tools.info_lines(lang, nil)
      lib.assert_eq(lines[1], "# " .. lang.id, lang.id .. ": info report header")
    end

    ------------------------------------------------------------------
    -- 4. install ORDER: Mason first (with tree-sitter-cli added when the
    --    CLI is missing), parsers only once Mason reports done -- Mason may
    --    be what puts `tree-sitter` on PATH. Installer and nvim-treesitter
    --    are stubbed: no network, nothing is actually installed.
    ------------------------------------------------------------------
    local installer = require("tools.install")
    local real_install, real_manual = installer.install_packages, installer.report_manual
    local real_parser_installed = lang_tools.parser_installed
    local real_ts = package.loaded["nvim-treesitter"]
    local events, pending_done = {}, nil
    installer.install_packages = function(pkgs, opts)
      table.insert(events, "mason:" .. table.concat(pkgs, ","))
      pending_done = opts.on_done
    end
    installer.report_manual = function() end
    lang_tools.parser_installed = function()
      return false
    end
    package.loaded["nvim-treesitter"] = {
      install = function(parsers)
        table.insert(events, "parsers:" .. table.concat(parsers, ","))
        return {
          await = function(_, cb)
            cb(nil)
          end,
        }
      end,
    }
    local _, restore_notify = lib.notify_spy()
    local order_ok, order_err = pcall(function()
      lang_tools.install(python)
      lib.assert_eq(#events, 1, "only Mason may start before it has finished: " .. vim.inspect(events))
      lib.assert_eq(events[1], "mason:ty,ruff,debugpy,tree-sitter-cli", "tree-sitter-cli joins the Mason batch")
      lib.assert_true(pending_done ~= nil, "the installer must be given a completion callback")
      pending_done({}, {})
      lib.assert_eq(events[2], "parsers:python", "parsers are built after Mason is done")
    end)
    installer.install_packages, installer.report_manual = real_install, real_manual
    lang_tools.parser_installed = real_parser_installed
    package.loaded["nvim-treesitter"] = real_ts
    restore_notify()
    if not order_ok then
      error(order_err, 0)
    end

    ------------------------------------------------------------------
    -- 5. no two keymaps claim the same mode + key in the same context
    ------------------------------------------------------------------
    local seen = {}
    for _, k in ipairs(require("util.keymap_registry").all()) do
      local modes = type(k.mode) == "table" and k.mode or { k.mode }
      for _, mode in ipairs(modes) do
        local key = mode .. " " .. k.lhs .. " @" .. k.context
        lib.assert_true(
          seen[key] == nil,
          ("duplicate keymap %s: '%s' and '%s'"):format(key, tostring(seen[key]), k.desc)
        )
        seen[key] = k.desc
      end
    end
  end)

  vim.env.PATH = saved_path
  vim.g.nvim_config_python_lsp = saved_choice
  exe.reset()
  pcall(vim.fn.delete, tmp, "rf")
  if not ok then
    error(err, 0)
  end
end)
