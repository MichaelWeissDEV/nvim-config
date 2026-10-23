-- Running the current file with an interpreter, portably.
--
-- The previous approach was a keymap containing the literal Ex string
-- `<cmd>terminal python3 %<cr>`. Three problems with that: `python3` does
-- not exist on a default Windows install, an activated virtualenv was
-- ignored entirely, and `%` is expanded into a shell command line, so a
-- path containing a space would be split into two arguments.
--
-- This module resolves an interpreter through the same executable
-- detection the rest of the config uses, and builds an argv list that
-- Neovim's :terminal accepts without any shell quoting of our own.
local exe = require("util.executable")
local platform = require("util.platform")

local M = {}

--- Interpreter candidates per language, in priority order. Plain argv
--- fragments -- no shell strings.
--- @type table<string, string[][]>
local CANDIDATES = {
  python = platform.is_windows and { { "python" }, { "py", "-3" }, { "python3" } } or { { "python3" }, { "python" } },
  ruby = { { "ruby" } },
  node = { { "node" } },
  ts = { { "tsx" }, { "ts-node" }, { "bun" }, { "deno", "run" } },
  lua = { { "lua" }, { "lua5.4" }, { "lua5.1" }, { "luajit" } },
  perl = { { "perl" } },
  php = { { "php" } },
  sh = { { "sh" } },
  bash = { { "bash" } },
  zsh = { { "zsh" } },
  fish = { { "fish" } },
  nu = { { "nu" } },
  pwsh = { { "pwsh" }, { "powershell" } },
  awk = { { "gawk", "-f" }, { "awk", "-f" } },
  tcl = { { "tclsh" } },
  r = { { "Rscript" } },
  julia = { { "julia" } },
  elixir = { { "elixir" } },
  racket = { { "racket" } },
  clojure = { { "clojure", "-M" }, { "bb" } },
  groovy = { { "groovy" } },
  scala = { { "scala-cli", "run" }, { "scala" } },
  swift = { { "swift" } },
  dart = { { "dart", "run" } },
  crystal = { { "crystal", "run" } },
}

--- The Python interpreter for `file` from a virtualenv: $VIRTUAL_ENV, a
--- project-local .venv/venv, or $CONDA_PREFIX (see util/python.lua).
--- Checked before PATH, so a fresh clone with `uv sync` / `python -m venv
--- .venv` runs against the project's own packages without activating
--- anything first.
--- @param file string|nil
--- @return string[]|nil
local function venv_python(file)
  local interpreter = require("util.python").interpreter(file)
  return interpreter and { interpreter } or nil
end

--- Resolve an interpreter to a concrete argv prefix.
--- @param language string key into CANDIDATES, e.g. "python"
--- @param file string|nil the file about to be run; used to find a project venv
--- @return string[]|nil argv prefix, nil when nothing suitable is installed
function M.resolve(language, file)
  if language == "python" then
    local venv = venv_python(file)
    if venv then
      return venv
    end
  end
  for _, candidate in ipairs(CANDIDATES[language] or {}) do
    if exe.exists(candidate[1]) then
      return vim.deepcopy(candidate)
    end
  end
  return nil
end

--- Run `argv` in a terminal split at the bottom. An argv list, never a
--- shell string, so nothing is re-split or re-quoted.
--- @param argv string[]
--- @param opts table|nil { cwd = string }
--- @return boolean started
function M.run(argv, opts)
  opts = opts or {}
  vim.cmd("botright split")
  vim.fn.jobstart(argv, { term = true, cwd = opts.cwd })
  return true
end

--- Run the current buffer's file with `language`'s interpreter in a
--- terminal split. Saves first, so what runs is what is on screen.
---
--- Builds the command as an argv list handed to vim.fn.jobstart via
--- :terminal's list form, so a path with spaces stays one argument -- no
--- manual quoting anywhere.
--- @param language string
--- @param opts table|nil { args = string[] } extra interpreter arguments
--- @return boolean started
function M.run_current_file(language, opts)
  opts = opts or {}
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    require("util.notify").once(
      "process-unnamed-buffer:" .. language,
      "Cannot run an unnamed buffer -- save it to a file first.",
      vim.log.levels.WARN
    )
    return false
  end

  local argv = M.resolve(language, file)
  if not argv then
    -- One message, only when the feature is actually used: the same
    -- contract every other optional dependency in this config follows.
    require("util.notify").once(
      "process-no-interpreter:" .. language,
      ("No %s interpreter found on PATH. Looked for: %s."):format(language, M.describe_candidates(language)),
      vim.log.levels.WARN
    )
    return false
  end

  vim.cmd("update")

  local cmd = vim.deepcopy(argv)
  vim.list_extend(cmd, opts.args or {})
  table.insert(cmd, file)

  return M.run(cmd)
end

--- Human-readable candidate list, for the "not found" message.
--- @param language string
--- @return string
function M.describe_candidates(language)
  local names = {}
  for _, candidate in ipairs(CANDIDATES[language] or {}) do
    table.insert(names, table.concat(candidate, " "))
  end
  if language == "python" then
    table.insert(names, 1, "$VIRTUAL_ENV, ./.venv, ./venv, $CONDA_PREFIX")
  end
  return table.concat(names, ", ")
end

M._candidates = CANDIDATES
M._venv_python = venv_python

return M
