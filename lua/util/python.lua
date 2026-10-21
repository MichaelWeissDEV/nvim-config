-- Python-specific facts shared by the language spec (languages/python.lua),
-- the runner (util/process.lua), the debugger configuration and the
-- :Python* commands, so "which interpreter" and "which language server"
-- are each answered in exactly one place.
local platform = require("util.platform")
local path = require("util.path")

local M = {}

M.LSP_CHOICES = { "ty", "basedpyright", "both" }
M.DEFAULT_LSP = "ty"

--- Project-local virtualenv directory names, in the order they are tried.
--- `.venv` first: it is what `uv`, `poetry` (in-project mode) and
--- `python -m venv .venv` produce.
M.VENV_DIRS = { ".venv", "venv" }

--- Files/dirs that mark a Python project root. Order is priority (see
--- lsp/registry.lua): a pyproject.toml must outrank an enclosing .git.
M.ROOT_MARKERS = {
  "pyproject.toml",
  "uv.lock",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "ty.toml",
  "ruff.toml",
  ".ruff.toml",
  "pyrightconfig.json",
  ".git",
}

--- @param venv string virtualenv (or conda env) root
--- @return string|nil the interpreter inside it, nil if there is none
function M.venv_interpreter(venv)
  if not venv or venv == "" then
    return nil
  end
  local candidate = platform.is_windows and vim.fs.joinpath(venv, "Scripts", "python.exe")
    or vim.fs.joinpath(venv, "bin", "python")
  if vim.uv.fs_stat(candidate) then
    return candidate
  end
  return nil
end

--- The project root for a file (or the cwd when there is no file).
--- @param file string|nil
--- @return string
function M.root(file)
  local start = (file and file ~= "") and vim.fs.dirname(file) or vim.uv.cwd()
  return path.find_root(start, M.ROOT_MARKERS) or start
end

--- Find a project-local virtualenv for `file`: the nearest `.venv`/`venv`
--- directory between the file and its project root that actually contains
--- an interpreter. Never searches above the project root, so a stray
--- ~/venv cannot hijack an unrelated project.
--- @param file string|nil
--- @return string|nil venv directory
function M.project_venv(file)
  local root = M.root(file)
  local dir = (file and file ~= "") and vim.fs.dirname(file) or root
  while dir do
    for _, name in ipairs(M.VENV_DIRS) do
      local venv = vim.fs.joinpath(dir, name)
      if M.venv_interpreter(venv) then
        return venv
      end
    end
    if dir == root then
      break
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return nil
end

--- Resolve the interpreter that should run/debug/test `file`.
---
--- Order: an activated virtualenv ($VIRTUAL_ENV), then a project-local
--- `.venv`/`venv`, then an activated conda env ($CONDA_PREFIX). PATH is the
--- caller's fallback (util/process.lua), not this function's, because PATH
--- lookups go through util.executable's cache.
--- @param file string|nil
--- @return string|nil interpreter path, string|nil where it came from
function M.interpreter(file)
  local active = M.venv_interpreter(vim.env.VIRTUAL_ENV)
  if active then
    return active, "$VIRTUAL_ENV"
  end
  local venv = M.project_venv(file)
  if venv then
    return M.venv_interpreter(venv), venv
  end
  local conda = M.venv_interpreter(vim.env.CONDA_PREFIX)
  if conda then
    return conda, "$CONDA_PREFIX"
  end
  return nil, nil
end

--- The configured Python language-server choice, validated.
--- @return string one of M.LSP_CHOICES
function M.lsp_choice()
  local choice = vim.g.nvim_config_python_lsp
  if choice == nil then
    return M.DEFAULT_LSP
  end
  if not vim.tbl_contains(M.LSP_CHOICES, choice) then
    require("util.notify").once(
      "python-lsp-choice:" .. tostring(choice),
      ("vim.g.nvim_config_python_lsp = %s is not one of %s; using '%s'."):format(
        vim.inspect(choice),
        table.concat(M.LSP_CHOICES, ", "),
        M.DEFAULT_LSP
      ),
      vim.log.levels.ERROR
    )
    return M.DEFAULT_LSP
  end
  return choice
end

--- Which of ty / basedpyright should run, given the choice and what is
--- installed. The default ("ty") falls back to basedpyright when ty is not
--- installed but basedpyright is, so an older install keeps working
--- instead of silently losing go-to-definition.
--- @return table<string, boolean> e.g. { ty = true }
function M.type_servers()
  local choice = M.lsp_choice()
  if choice == "both" then
    return { ty = true, basedpyright = true }
  end
  if choice == "basedpyright" then
    return { basedpyright = true }
  end
  local detection = require("tools.detection")
  if not detection.is_installed("ty") and detection.is_installed("basedpyright") then
    return { basedpyright = true }
  end
  return { ty = true }
end

--- The dotted pytest node id for the test under the cursor:
--- `path::Class::test_name` or `path::test_name`. Uses Tree-sitter when a
--- python parser is available and falls back to a backwards text search
--- for `def test...` otherwise.
--- @param bufnr integer
--- @param row integer 1-based cursor line
--- @param opts table|nil { treesitter: boolean? } false forces the text fallback (tests)
--- @return string|nil node id, nil when the cursor is not inside a test
function M.test_node_id(bufnr, row, opts)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    return nil
  end

  local names = {}
  local ok, parser = false, nil
  if not (opts and opts.treesitter == false) then
    ok, parser = pcall(vim.treesitter.get_parser, bufnr, "python")
  end
  if ok and parser then
    local tree = parser:parse()[1]
    local node = tree:root():named_descendant_for_range(row - 1, 0, row - 1, 0)
    while node do
      local kind = node:type()
      if kind == "function_definition" or kind == "class_definition" then
        local name_node = node:field("name")[1]
        if name_node then
          table.insert(names, 1, vim.treesitter.get_node_text(name_node, bufnr))
        end
      end
      node = node:parent()
    end
  else
    -- No parser: walk upwards by indentation. The nearest `def test*` above
    -- the cursor is the test; a `class Test*` further up at a smaller
    -- indent is its class.
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)
    local fn_indent = nil
    for i = #lines, 1, -1 do
      local indent, name = lines[i]:match("^(%s*)async%s+def%s+(test[%w_]*)")
      if not name then
        indent, name = lines[i]:match("^(%s*)def%s+(test[%w_]*)")
      end
      if not fn_indent and name then
        names = { name }
        fn_indent = #indent
      elseif fn_indent then
        local cindent, cname = lines[i]:match("^(%s*)class%s+([%w_]+)")
        if cname and #cindent < fn_indent then
          table.insert(names, 1, cname)
          fn_indent = #cindent
        end
      end
    end
  end

  -- Keep only the part pytest can address: classes, then one function.
  local id_parts = {}
  for _, name in ipairs(names) do
    table.insert(id_parts, name)
    if not name:match("^[A-Z]") then
      break -- a function; anything nested inside it is not a test item
    end
  end
  if #id_parts == 0 then
    return nil
  end
  return file .. "::" .. table.concat(id_parts, "::")
end

return M
