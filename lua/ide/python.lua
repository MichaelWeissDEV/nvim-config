-- Python workflow commands. The language data lives in languages/python.lua
-- and the shared facts (venv, server choice, test ids) in util/python.lua;
-- this file only turns them into commands.
local python = require("util.python")
local process = require("util.process")
local cmdreg = require("util.command_registry")
local scratch = require("util.scratch")
local detection = require("tools.detection")

local M = {}

--- @type { argv: string[], cwd: string }|nil
local last_pytest = nil

--- Build the pytest invocation for `mode`, without running it.
--- @param mode "file"|"nearest"|"all"
--- @param bufnr integer
--- @param extra string[] extra pytest arguments
--- @return { argv: string[], cwd: string }|nil, string|nil error
function M.pytest_command(mode, bufnr, extra)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local interpreter = process.resolve("python", file ~= "" and file or nil)
  if not interpreter then
    return nil, "No Python interpreter found (" .. process.describe_candidates("python") .. ")."
  end
  local argv = vim.deepcopy(interpreter)
  vim.list_extend(argv, { "-m", "pytest" })
  if mode == "file" then
    if file == "" then
      return nil, "Save the buffer to a file first."
    end
    table.insert(argv, file)
  elseif mode == "nearest" then
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local id = python.test_node_id(bufnr, row)
    if not id then
      return nil, "The cursor is not inside a test function or class."
    end
    table.insert(argv, id)
  elseif mode ~= "all" then
    return nil, "Unknown mode '" .. tostring(mode) .. "' (expected file, nearest, all or last)."
  end
  vim.list_extend(argv, extra or {})
  return { argv = argv, cwd = python.root(file ~= "" and file or nil) }
end

cmdreg.command({
  name = "Pytest",
  desc = "Run pytest in a terminal split with the project's interpreter (.venv aware): file, nearest, all, or last",
  category = "Python",
  args = "[file|nearest|all|last] [pytest args...]",
  example = ":Pytest nearest -x",
  opts = {
    nargs = "*",
    complete = function(arglead, cmdline)
      if #vim.split(cmdline, "%s+", { trimempty = true }) > (arglead == "" and 1 or 2) then
        return {}
      end
      return vim.tbl_filter(function(m)
        return vim.startswith(m, arglead)
      end, { "file", "nearest", "all", "last" })
    end,
  },
  fn = function(opts)
    local mode = opts.fargs[1] or "file"
    local extra = vim.list_slice(opts.fargs, 2)
    local cmd, err
    if mode == "last" then
      cmd = last_pytest
      err = cmd == nil and "No previous :Pytest run in this session." or nil
    else
      vim.cmd("silent! update")
      cmd, err = M.pytest_command(mode, vim.api.nvim_get_current_buf(), extra)
    end
    if not cmd then
      vim.notify("Pytest: " .. err, vim.log.levels.WARN)
      return
    end
    last_pytest = cmd
    process.run(cmd.argv, { cwd = cmd.cwd })
  end,
})

cmdreg.command({
  name = "PythonLsp",
  desc = "Choose the Python type checker for this session: ty (default), basedpyright or both; no arg shows the current choice",
  category = "Python",
  args = "[ty|basedpyright|both]",
  example = ":PythonLsp basedpyright",
  opts = {
    nargs = "?",
    complete = function()
      return python.LSP_CHOICES
    end,
  },
  fn = function(opts)
    if opts.args == "" then
      local active = vim.tbl_keys(python.type_servers())
      table.sort(active)
      vim.notify(
        ("Python LSP choice: %s (active: %s, plus ruff). Set it with :PythonLsp ty|basedpyright|both."):format(
          python.lsp_choice(),
          table.concat(active, ", ")
        )
      )
      return
    end
    if not vim.tbl_contains(python.LSP_CHOICES, opts.args) then
      vim.notify("PythonLsp: expected one of " .. table.concat(python.LSP_CHOICES, ", "), vim.log.levels.ERROR)
      return
    end
    vim.g.nvim_config_python_lsp = opts.args
    require("lsp.registry").refresh()
    local missing = {}
    for server in pairs(python.type_servers()) do
      if not detection.is_installed(server) then
        table.insert(missing, server)
      end
    end
    local msg = "Python LSP: " .. opts.args
    if #missing > 0 then
      table.sort(missing)
      msg = msg .. " -- not installed: " .. table.concat(missing, ", ") .. " (:LangInstall python)"
    end
    vim.notify(msg, #missing > 0 and vim.log.levels.WARN or vim.log.levels.INFO)
  end,
})

--- Report lines for :PythonInfo.
--- @param bufnr integer
--- @return string[]
function M.info_lines(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  file = file ~= "" and file or nil
  local interpreter, source = python.interpreter(file)
  local argv = process.resolve("python", file)
  local lines = { "# Python", "" }
  table.insert(lines, "Project root:   " .. python.root(file))
  table.insert(
    lines,
    "Interpreter:    "
      .. (argv and table.concat(argv, " ") or "(none found)")
      .. (interpreter and (" (from " .. source .. ")") or (argv and " (from PATH)" or ""))
  )
  table.insert(lines, "$VIRTUAL_ENV:   " .. (vim.env.VIRTUAL_ENV or "(not set)"))
  table.insert(
    lines,
    "Project venv:   " .. (python.project_venv(file) or "(none -- e.g. `uv venv` or `python -m venv .venv`)")
  )
  table.insert(lines, "")
  local active = vim.tbl_keys(python.type_servers())
  table.sort(active)
  table.insert(lines, "Type checker:   " .. python.lsp_choice() .. " (running: " .. table.concat(active, ", ") .. ")")
  table.insert(lines, "")
  table.insert(lines, "## Tools")
  table.insert(lines, "")
  for _, id in ipairs({ "ty", "ruff", "basedpyright", "debugpy" }) do
    table.insert(lines, string.format("- [%s] %s", detection.is_installed(id) and "OK" or "MISSING", id))
  end
  table.insert(lines, "")
  table.insert(lines, "## Attached to this buffer")
  table.insert(lines, "")
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    table.insert(lines, "- (none)")
  end
  for _, c in ipairs(clients) do
    table.insert(lines, string.format("- %s (root: %s)", c.name, c.root_dir or "single file"))
  end
  table.insert(lines, "")
  table.insert(lines, "Missing something? :LangInstall python")
  return lines
end

cmdreg.command({
  name = "PythonInfo",
  desc = "Show the Python interpreter/venv in use, the type checker choice and the attached servers",
  category = "Python",
  example = ":PythonInfo",
  fn = function()
    scratch.open("nvim-config://python-info", M.info_lines(vim.api.nvim_get_current_buf()))
  end,
})

return M
