-- Headless installer, invoked by scripts/bootstrap.sh / bootstrap.ps1 as:
--   nvim --headless -u init.lua -l scripts/bootstrap.lua <profile>
-- This is explicit, maintainer-triggered, online-by-design code -- the
-- opposite of everything else in this config. It waits for Mason's async
-- install jobs to actually finish before quitting, so it's safe to run
-- non-interactively in CI or a fresh-machine setup script.
-- `nvim -l script.lua <args>` exposes trailing args via the global `arg`
-- table, not via `...` (that's only for chunks loaded through `require`/`dofile`).
local profile = arg and arg[1]

local registry = require("tools.registry")
local known_profiles = vim.list_extend(vim.deepcopy(registry.profiles), { "all" })

if not profile or not vim.tbl_contains(known_profiles, profile) then
  io.stderr:write("Usage: bootstrap.lua <profile>\nKnown profiles: " .. table.concat(known_profiles, ", ") .. "\n")
  os.exit(1)
end

vim.cmd("packadd mason.nvim")
require("mason").setup()
local mr = require("mason-registry")

local specs = profile == "all" and registry.all() or registry.by_profile(profile)
local pkgs, seen, manual = {}, {}, {}
for _, s in ipairs(specs) do
  if s.mason then
    if not seen[s.mason] then
      seen[s.mason] = true
      table.insert(pkgs, s.mason)
    end
  elseif s.exe then
    table.insert(manual, s)
  end
end

print(string.format("==> Profile '%s': %d Mason package(s) to install", profile, #pkgs))

-- Tree-sitter parsers are not Mason packages; install a sane default set
-- per profile too (still 100% explicit -- only runs inside bootstrap.lua).
local PROFILE_PARSERS = {
  core = { "lua", "vim", "vimdoc", "query", "bash", "markdown", "markdown_inline" },
  systems = { "c", "cpp", "rust", "go", "asm", "cmake" },
  python = { "python" },
  scripting = { "ruby", "perl" },
  web = { "javascript", "typescript", "tsx", "html", "css", "scss", "vue", "svelte", "json", "graphql" },
  jvm = { "java", "kotlin" },
  dotnet = { "c_sharp" },
  functional = { "haskell", "ocaml", "elixir", "erlang" },
  devops = { "yaml", "toml", "hcl", "terraform", "dockerfile", "nix", "sql" },
  docs = { "markdown", "markdown_inline", "latex", "rst" },
}
if profile == "all" then
  local all_parsers, seen_p = {}, {}
  for _, list in pairs(PROFILE_PARSERS) do
    for _, p in ipairs(list) do
      if not seen_p[p] then
        seen_p[p] = true
        table.insert(all_parsers, p)
      end
    end
  end
  PROFILE_PARSERS.all = all_parsers
end
local parsers = PROFILE_PARSERS[profile]
if parsers and #parsers > 0 then
  print("==> Installing Tree-sitter parsers: " .. table.concat(parsers, ", "))
  local ok, err = pcall(function()
    require("nvim-treesitter").install(parsers):wait(300000)
  end)
  if not ok then
    io.stderr:write("Tree-sitter parser install failed: " .. tostring(err) .. "\n")
  end
end

-- `nvim -l script.lua` exits as soon as the script's synchronous portion
-- returns -- it does NOT keep the process alive for pending async callbacks
-- (mr.refresh, package:install() are both async). So the actual blocking
-- primitive here is vim.wait() at the bottom, polling a `done` flag that
-- the async callbacks flip; nothing above may rely on the event loop
-- "just still running" on its own.
local done = false
local exit_code = 0

local function finish()
  if #manual > 0 then
    print("\n==> Not installable via Mason (install manually):")
    for _, s in ipairs(manual) do
      print(string.format("  - %s%s", s.name, s.note and (" -- " .. s.note) or ""))
    end
  end
  print("\n==> bootstrap.lua done.")
  done = true
end

if #pkgs == 0 then
  finish()
else
  mr.refresh(function()
    local pending = #pkgs

    local function step(name, ok)
      print(string.format("[%s] %s", ok and "OK" or "FAIL", name))
      pending = pending - 1
      if pending == 0 then
        vim.schedule(finish)
      end
    end

    for _, name in ipairs(pkgs) do
      local has, pkg = pcall(mr.get_package, name)
      if not has then
        step(name .. " (unknown Mason package)", false)
      elseif pkg:is_installed() then
        step(name .. " (already installed)", true)
      else
        pkg:install():once("closed", function()
          vim.schedule(function()
            step(name, pkg:is_installed())
          end)
        end)
      end
    end
  end)
end

local waited_ok = vim.wait(20 * 60 * 1000, function()
  return done
end, 200)

if not waited_ok then
  io.stderr:write("bootstrap.lua: timed out after 20 minutes.\n")
  exit_code = 1
end

os.exit(exit_code)
