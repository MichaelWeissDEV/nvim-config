-- <leader>cr: run the current file, for languages where "run this file"
-- has an obvious meaning. Python has a richer buffer-local version in
-- languages/python.lua (same key, .venv aware); this is the generic one.
local km = require("util.keymap_registry")
local process = require("util.process")
local exe = require("util.executable")
local notify = require("util.notify")
local path = require("util.path")

local M = {}

--- filetype -> interpreter key in util/process.lua's candidate table.
local INTERPRETED = {
  python = "python",
  ruby = "ruby",
  javascript = "node",
  typescript = "ts",
  lua = "lua",
  perl = "perl",
  php = "php",
  sh = "sh",
  bash = "bash",
  zsh = "zsh",
  fish = "fish",
  nu = "nu",
  ps1 = "pwsh",
  awk = "awk",
  tcl = "tcl",
  r = "r",
  julia = "julia",
  elixir = "elixir",
  racket = "racket",
  scheme = "racket",
  clojure = "clojure",
  groovy = "groovy",
  scala = "scala",
  swift = "swift",
  dart = "dart",
  crystal = "crystal",
}

--- filetype -> function(file) returning argv and cwd for compiled languages
--- whose toolchain has a "build and run" command.
local TOOLCHAIN = {
  go = function(file)
    return { "go", "run", file }, vim.fs.dirname(file)
  end,
  rust = function(file)
    local root = path.find_root(vim.fs.dirname(file), { "Cargo.toml" })
    if root then
      return { "cargo", "run" }, root
    end
    return nil
  end,
  zig = function(file)
    return { "zig", "run", file }, vim.fs.dirname(file)
  end,
  odin = function(file)
    return { "odin", "run", file, "-file" }, vim.fs.dirname(file)
  end,
  nim = function(file)
    return { "nim", "r", file }, vim.fs.dirname(file)
  end,
  d = function(file)
    return { "rdmd", file }, vim.fs.dirname(file)
  end,
  v = function(file)
    return { "v", "run", file }, vim.fs.dirname(file)
  end,
  gleam = function(file)
    local root = path.find_root(vim.fs.dirname(file), { "gleam.toml" })
    if root then
      return { "gleam", "run" }, root
    end
    return nil
  end,
}

function M.run_current()
  local ft = vim.bo.filetype
  if INTERPRETED[ft] then
    process.run_current_file(INTERPRETED[ft])
    return
  end
  local file = vim.api.nvim_buf_get_name(0)
  local build = TOOLCHAIN[ft]
  local argv, cwd
  if build and file ~= "" then
    argv, cwd = build(file)
  end
  if not argv then
    notify.once("run-unsupported:" .. ft, "No 'run current file' for filetype '" .. ft .. "'.", vim.log.levels.WARN)
    return
  end
  if not exe.exists(argv[1]) then
    notify.missing_dependency("Running " .. ft, argv[1])
    return
  end
  vim.cmd("update")
  process.run(argv, { cwd = cwd })
end

km.map({ mode = "n", lhs = "<leader>cr", rhs = M.run_current, desc = "Run current file", group = "Code" })

return M
