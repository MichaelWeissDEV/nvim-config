-- :ToolsInstall / :ToolsUpdate -- the ONLY code paths in this config allowed
-- to touch the network at runtime, and only when the user explicitly runs
-- one of these commands. Both delegate the actual download/install work to
-- mason.nvim; this module's job is just "which packages does this profile
-- need" (from tools.registry) and "print what mason can't install for you".
local registry = require("tools.registry")
local cmdreg = require("util.command_registry")
local lazyload = require("config.lazyload")

local M = {}

--- @param profile string one of tools.registry.M.profiles, or "all"
--- @return string[] mason_packages, table[] manual_tools
local function resolve(profile)
  local specs
  if profile == "all" then
    specs = registry.all()
  else
    specs = registry.by_profile(profile)
  end

  local seen, mason_packages, manual = {}, {}, {}
  for _, spec in ipairs(specs) do
    if spec.mason then
      if not seen[spec.mason] then
        seen[spec.mason] = true
        table.insert(mason_packages, spec.mason)
      end
    elseif spec.exe then
      table.insert(manual, spec)
    end
  end
  return mason_packages, manual
end

local function ensure_mason()
  lazyload.packadd("mason.nvim")
  local ok, mason = pcall(require, "mason")
  if ok and not package.loaded["mason.settings"] then
    -- plugins/mason.lua already calls setup() when the package loads via
    -- its own plugin/ script; this is just a safety net for headless use.
    pcall(mason.setup)
  end
  return ok
end

local function report_manual(manual)
  if #manual == 0 then
    return
  end
  local lines = { "The following tools are not installable via Mason and must be installed manually:" }
  for _, spec in ipairs(manual) do
    table.insert(lines, string.format("  - %s%s", spec.name, spec.note and (" (" .. spec.note .. ")") or ""))
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "nvim-config: ToolsInstall" })
end

local function complete_profiles()
  return vim.list_extend(vim.deepcopy(registry.profiles), { "all" })
end

--- Install/update `mason_packages` via mason-registry directly (not the
--- `:MasonInstall` command) so we get a real per-package completion
--- callback -- needed to reset util.executable's cache once installs
--- finish, otherwise a tool installed this session keeps reporting as
--- "not installed" to LSP/formatter/linter/debugger detection until
--- Neovim restarts (see docs/troubleshooting.md).
--- @param mason_packages string[]
--- @param force boolean? when true, reinstall/upgrade even if already installed (used by :ToolsUpdate)
local function install_packages(mason_packages, force)
  if #mason_packages == 0 then
    return
  end
  local mr = require("mason-registry")
  mr.refresh(function()
    local pending = #mason_packages
    local function done_one()
      pending = pending - 1
      if pending == 0 then
        vim.schedule(function()
          require("util.executable").reset()
          vim.notify(
            (force and "Tools updated: " or "Tools installed: ")
              .. table.concat(mason_packages, ", ")
              .. "\nRun :NvimConfigHealth to confirm.",
            vim.log.levels.INFO,
            { title = "nvim-config: " .. (force and "ToolsUpdate" or "ToolsInstall") }
          )
        end)
      end
    end
    for _, name in ipairs(mason_packages) do
      local has, pkg = pcall(mr.get_package, name)
      if not has then
        done_one()
      elseif pkg:is_installed() and not force then
        done_one()
      else
        pkg:install():once("closed", done_one)
      end
    end
  end)
end

cmdreg.command({
  name = "ToolsInstall",
  desc = "Install every Mason-installable tool for a profile (core, systems, python, web, jvm, dotnet, functional, devops, docs, scripting, all)",
  category = "Tools",
  args = "<profile>",
  example = ":ToolsInstall systems",
  opts = {
    nargs = 1,
    complete = function()
      return complete_profiles()
    end,
  },
  fn = function(opts)
    local profile = opts.args
    if not vim.tbl_contains(complete_profiles(), profile) then
      vim.notify(
        "Unknown profile: " .. profile .. ". Known: " .. table.concat(complete_profiles(), ", "),
        vim.log.levels.ERROR
      )
      return
    end
    if not ensure_mason() then
      vim.notify("mason.nvim failed to load; cannot install tools.", vim.log.levels.ERROR)
      return
    end
    local mason_packages, manual = resolve(profile)
    install_packages(mason_packages)
    report_manual(manual)
  end,
})

cmdreg.command({
  name = "ToolsUpdate",
  desc = "Update every Mason-installed tool for a profile (or 'all')",
  category = "Tools",
  args = "<profile>",
  example = ":ToolsUpdate all",
  opts = {
    nargs = 1,
    complete = function()
      return complete_profiles()
    end,
  },
  fn = function(opts)
    local profile = opts.args
    if not ensure_mason() then
      vim.notify("mason.nvim failed to load; cannot update tools.", vim.log.levels.ERROR)
      return
    end
    local mason_packages = resolve(profile)
    install_packages(mason_packages, true)
  end,
})

return M
