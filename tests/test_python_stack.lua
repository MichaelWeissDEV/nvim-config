-- The Python stack: ty by default, ruff's server always alongside,
-- basedpyright as an opt-in alternative (and automatic fallback), switched
-- at runtime without a restart; interpreter resolution that finds a
-- project's .venv without activating it; pytest node ids.
--
-- No Mason, no network, no real language servers: availability is simulated
-- with fake executables on a PATH that contains nothing else, which is what
-- util.executable actually probes.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("python stack: server choice, fallback, runtime switch, venv, test ids", function()
  local exe = require("util.executable")
  local platform = require("util.platform")
  local python = require("util.python")
  local lsp_registry = require("lsp.registry")
  local notify = require("util.notify")

  local tmp = vim.fn.tempname()
  local bin = tmp .. "/bin"
  vim.fn.mkdir(bin, "p")
  local saved = {
    PATH = vim.env.PATH,
    VIRTUAL_ENV = vim.env.VIRTUAL_ENV,
    CONDA_PREFIX = vim.env.CONDA_PREFIX,
    choice = vim.g.nvim_config_python_lsp,
  }

  local function fake_tool(name)
    local p = bin .. "/" .. name .. (platform.is_windows and ".cmd" or "")
    local f = assert(io.open(p, "w"))
    f:write(platform.is_windows and "@echo off\r\nexit /b 0\r\n" or "#!/bin/sh\nexit 0\n")
    f:close()
    if not platform.is_windows then
      -- libuv, not `chmod`: PATH holds nothing but this directory here.
      vim.uv.fs_chmod(p, tonumber("755", 8))
    end
  end
  local function remove_tool(name)
    os.remove(bin .. "/" .. name .. (platform.is_windows and ".cmd" or ""))
  end

  --- A fake interpreter at <venv>/bin/python (Scripts\python.exe on Windows).
  local function fake_venv(dir)
    local sub = platform.is_windows and "/Scripts" or "/bin"
    local name = platform.is_windows and "python.exe" or "python"
    vim.fn.mkdir(dir .. sub, "p")
    local f = assert(io.open(dir .. sub .. "/" .. name, "w"))
    f:write("")
    f:close()
    return dir .. sub .. "/" .. name
  end

  local function servers()
    exe.reset()
    local by_tool = lsp_registry._collect()
    local ids = vim.tbl_keys(by_tool)
    table.sort(ids)
    return table.concat(ids, ",")
  end

  local ok, err = pcall(function()
    vim.env.VIRTUAL_ENV = nil
    vim.env.CONDA_PREFIX = nil

    ------------------------------------------------------------------
    -- 1. registry shape: ruff is a language server, not an nvim-lint
    --    linter (that would report every problem twice)
    ------------------------------------------------------------------
    local lang = require("languages.registry").get("python")
    lib.assert_eq(lang.lsp.tool, "ty", "ty must be the primary Python server")
    lib.assert_eq(#lang.linters, 0, "python must not also lint through nvim-lint")
    lib.assert_eq(require("tools.registry").get("ruff").category, "lsp", "ruff must be registered as an LSP")
    lib.assert_eq(lang.formatters[1], "ruff_format", "ruff format stays the formatter")

    ------------------------------------------------------------------
    -- 2. test ids -- buffers are named BEFORE PATH is emptied, because
    --    naming a buffer runs gitsigns, which needs git
    ------------------------------------------------------------------
    local test_file = tmp .. "/proj/tests/test_thing.py"
    vim.fn.mkdir(vim.fs.dirname(test_file), "p")
    local tf = assert(io.open(test_file, "w"))
    tf:write(table.concat({
      "import pytest",
      "",
      "class TestThing:",
      "    def test_one(self):",
      "        assert 1",
      "",
      "def test_two():",
      "    x = 1",
      "    assert x",
      "",
      "def helper():",
      "    pass",
    }, "\n") .. "\n")
    tf:close()
    vim.cmd.edit(test_file)
    local buf = vim.api.nvim_get_current_buf()
    -- Neovim stores the resolved path (macOS: /var -> /private/var), and
    -- node ids are built from the buffer name, so compare against that.
    local bufname = vim.api.nvim_buf_get_name(buf)
    for _, use_ts in ipairs({ false, true }) do
      local o = { treesitter = use_ts }
      local label = use_ts and " (tree-sitter)" or " (text fallback)"
      lib.assert_eq(python.test_node_id(buf, 5, o), bufname .. "::TestThing::test_one", "method in class" .. label)
      lib.assert_eq(python.test_node_id(buf, 9, o), bufname .. "::test_two", "plain test function" .. label)
      lib.assert_eq(python.test_node_id(buf, 1, o), nil, "outside any test" .. label)
    end
    vim.api.nvim_win_set_cursor(0, { 9, 0 })
    local cmd, why = require("ide.python").pytest_command("nearest", buf, { "-x" })
    lib.assert_true(cmd ~= nil, "nearest inside a test must build a command: " .. tostring(why))
    lib.assert_eq(cmd.argv[#cmd.argv - 1], bufname .. "::test_two", "nearest targets the node id")
    lib.assert_eq(cmd.argv[#cmd.argv], "-x", "extra pytest args are passed through")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    cmd, why = require("ide.python").pytest_command("nearest", buf, {})
    lib.assert_true(cmd == nil and why ~= nil, "nearest outside a test must refuse with a reason")

    -- Done with the buffer. Wiped before any server is enabled below:
    -- vim.lsp.enable() attaches to already-open buffers, and the fake
    -- executables are not language servers.
    vim.cmd("bwipeout! " .. buf)

    ------------------------------------------------------------------
    -- 3. which servers run, from what is installed and the choice
    ------------------------------------------------------------------
    vim.env.PATH = bin
    vim.g.nvim_config_python_lsp = nil
    lib.assert_eq(servers(), "", "nothing installed -> nothing configured")

    fake_tool("ty")
    fake_tool("ruff")
    lib.assert_eq(servers(), "ruff,ty", "default: ty + ruff")

    vim.g.nvim_config_python_lsp = "basedpyright"
    lib.assert_eq(servers(), "ruff", "basedpyright chosen but not installed: never silently ty instead")

    fake_tool("basedpyright-langserver")
    lib.assert_eq(servers(), "basedpyright,ruff", "basedpyright chosen and installed")

    vim.g.nvim_config_python_lsp = "both"
    lib.assert_eq(servers(), "basedpyright,ruff,ty", "both")

    vim.g.nvim_config_python_lsp = nil
    remove_tool("ty")
    lib.assert_eq(servers(), "basedpyright,ruff", "default falls back to basedpyright when only it is installed")
    fake_tool("ty")

    local errors = {}
    local real_once = notify.once
    local seen_keys = {}
    notify.once = function(key, msg, level)
      -- Same per-key dedup as the real notify.once: the choice is read once
      -- per server spec, the message must still appear only once.
      if not seen_keys[key] then
        seen_keys[key] = true
        table.insert(errors, { msg = msg, level = level })
      end
    end
    vim.g.nvim_config_python_lsp = "pyright"
    local chosen = servers()
    notify.once = real_once
    lib.assert_eq(chosen, "ruff,ty", "an invalid choice falls back to the default")
    lib.assert_eq(#errors, 1, "an invalid choice is reported")
    lib.assert_eq(errors[1].level, vim.log.levels.ERROR, "an invalid choice is a configuration error")

    ------------------------------------------------------------------
    -- 4. switching at runtime enables and DISABLES servers
    ------------------------------------------------------------------
    vim.g.nvim_config_python_lsp = "both"
    exe.reset()
    lsp_registry.setup()
    lib.assert_true(vim.lsp.is_enabled("ty") and vim.lsp.is_enabled("basedpyright"), "both enabled")
    vim.g.nvim_config_python_lsp = "basedpyright"
    exe.reset()
    lsp_registry.setup()
    lib.assert_true(not vim.lsp.is_enabled("ty"), "switching away from ty must disable it")
    lib.assert_true(vim.lsp.is_enabled("basedpyright"), "basedpyright stays enabled")
    lib.assert_true(vim.lsp.is_enabled("ruff"), "ruff is independent of the choice")

    ------------------------------------------------------------------
    -- 5. the built configs carry the Python-specific hooks
    ------------------------------------------------------------------
    vim.g.nvim_config_python_lsp = "both"
    exe.reset()
    local by_tool = lsp_registry._collect()
    local ruff_cfg = lsp_registry._build_config(by_tool.ruff)
    lib.assert_eq(ruff_cfg.cmd[2], "server", "ruff runs as `ruff server`")
    lib.assert_eq(type(ruff_cfg.on_attach), "function", "ruff's hover is switched off on attach")
    local bp_cfg = lsp_registry._build_config(by_tool.basedpyright)
    lib.assert_eq(type(bp_cfg.before_init), "function", "basedpyright gets the project venv")
    lib.assert_eq(bp_cfg.settings.basedpyright.disableOrganizeImports, true, "ruff owns organize imports")

    ------------------------------------------------------------------
    -- 6. interpreter resolution: $VIRTUAL_ENV > project .venv > PATH,
    --    and never a venv above the project root
    ------------------------------------------------------------------
    vim.env.PATH = saved.PATH
    exe.reset()
    local proj = tmp .. "/proj"
    local pf = assert(io.open(proj .. "/pyproject.toml", "w"))
    pf:write("[project]\nname = 'x'\n")
    pf:close()
    local project_python = fake_venv(proj .. "/.venv")
    lib.assert_same_path(python.interpreter(test_file), project_python, "project .venv found from a nested file")
    lib.assert_same_path(
      require("util.process").resolve("python", test_file)[1],
      project_python,
      "the runner uses the project .venv"
    )

    -- The debugger launches under the same interpreter, not under the one
    -- Mason installed debugpy into (which cannot import the project).
    vim.cmd.edit(test_file)
    for i, config in ipairs(lang.debugger.configurations()) do
      lib.assert_eq(type(config.python), "function", ("debug config %d resolves python at launch"):format(i))
      lib.assert_eq(
        vim.uv.fs_realpath(config.python()),
        vim.uv.fs_realpath(project_python),
        ("debug config %d runs under the project .venv"):format(i)
      )
    end
    vim.cmd("bwipeout!")

    local active_python = fake_venv(tmp .. "/active-venv")
    vim.env.VIRTUAL_ENV = tmp .. "/active-venv"
    lib.assert_same_path(python.interpreter(test_file), active_python, "$VIRTUAL_ENV wins over the project venv")
    vim.env.VIRTUAL_ENV = nil

    local outer = tmp .. "/outer"
    fake_venv(outer .. "/venv")
    vim.fn.mkdir(outer .. "/inner", "p")
    local inner_toml = assert(io.open(outer .. "/inner/pyproject.toml", "w"))
    inner_toml:write("")
    inner_toml:close()
    lib.assert_eq(python.project_venv(outer .. "/inner/main.py"), nil, "a venv above the project root is ignored")
  end)

  vim.env.PATH = saved.PATH
  vim.env.VIRTUAL_ENV = saved.VIRTUAL_ENV
  vim.env.CONDA_PREFIX = saved.CONDA_PREFIX
  vim.g.nvim_config_python_lsp = saved.choice
  exe.reset()
  pcall(vim.fn.delete, tmp, "rf")

  if not ok then
    error(err, 0)
  end
end)
