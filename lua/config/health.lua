-- Backing implementation for `:checkhealth nvim-config` (and the
-- `:NvimConfigHealth` command, which is just `:checkhealth nvim-config`
-- under a friendlier name -- see config/commands.lua). This is a report
-- only: it never installs anything, it only says what's missing and how to
-- fix it, mirroring how core Neovim's own :checkhealth works.
local platform = require("util.platform")
local exe = require("util.executable")

local M = {}

local function ok(msg)
  vim.health.ok(msg)
end
local function warn(msg, advice)
  vim.health.warn(msg, advice)
end
local function report_tool(name, hint)
  if exe.exists(name) then
    ok(name)
  else
    warn(name .. " not found on PATH", hint)
  end
end

function M.check()
  vim.health.start("Neovim")
  if vim.fn.has("nvim-0.11") == 1 then
    ok("Neovim " .. tostring(vim.version()))
  else
    vim.health.error("Neovim 0.11+ required, found " .. tostring(vim.version()))
  end

  vim.health.start("Platform")
  ok(platform.describe())
  ok("config dir: " .. platform.config_dir)
  ok("data dir: " .. platform.data_dir)

  vim.health.start("Core tools")
  report_tool("git", "Required for plugin vendoring and version metadata.")
  report_tool(
    "rg",
    "Improves Telescope live_grep/grep_string speed and accuracy.\nmacOS: brew install ripgrep | Debian/Ubuntu: apt install ripgrep | Arch: pacman -S ripgrep"
  )
  report_tool(
    "fd",
    "Improves Telescope find_files speed; falls back to Neovim's own globbing otherwise.\nmacOS: brew install fd | Debian/Ubuntu: apt install fd-find | Arch: pacman -S fd"
  )

  vim.health.start("Documentation")
  local docs_dir = vim.fs.joinpath(platform.config_dir, "docs", "_build", "html", "index.html")
  if vim.uv.fs_stat(docs_dir) then
    ok("Local Sphinx docs built (docs/_build/html)")
  else
    warn("Local Sphinx docs not built", "Run ./scripts/docs-build.sh")
  end
  local help_tags = vim.fs.joinpath(platform.config_dir, "doc", "tags")
  if vim.uv.fs_stat(help_tags) then
    ok("Native :help tags generated")
  else
    warn(":help nvim-config tags missing", "Run :helptags " .. vim.fs.joinpath(platform.config_dir, "doc"))
  end

  local plugins_ok, plugins_health = pcall(require, "plugins.health")
  if plugins_ok then
    plugins_health.check()
  end

  local tools_ok, tools_status = pcall(require, "tools.status")
  if tools_ok then
    tools_status.health_report()
  end
end

return M
