-- LSP registry semantics.
--
-- Two defects this locks down:
--   1. root_markers went through a set + table.sort, so a language's
--      declared priority (pyproject.toml before .git) was replaced by
--      alphabetical order -- ".git" would win over "pyproject.toml".
--   2. a server shared by several languages had its settings/extra
--      silently deep-extended together, so the winner depended on
--      language load order.
--
-- Synthetic language specs are injected by replacing the registry modules
-- in package.loaded, so this tests the aggregation logic itself without
-- needing any language server installed.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("lsp registry: marker order, filetype union, shared-server conflicts", function()
  ------------------------------------------------------------------
  -- Pure validator first: no stubbing needed.
  ------------------------------------------------------------------
  local registry = require("lsp.registry")

  lib.assert_eq(registry.validate_root_marker("pyproject.toml"), true, "plain string is valid")
  lib.assert_eq(registry.validate_root_marker(""), false, "empty string is invalid")
  lib.assert_eq(registry.validate_root_marker({ "a", "b" }), true, "group of strings is valid")
  lib.assert_eq(registry.validate_root_marker({}), false, "empty group is invalid")
  lib.assert_eq(registry.validate_root_marker({ "a", "" }), false, "group with empty string is invalid")
  lib.assert_eq(registry.validate_root_marker({ "a", 5 }), false, "group with non-string is invalid")
  lib.assert_eq(registry.validate_root_marker(42), false, "number is invalid")
  lib.assert_eq(registry.validate_root_marker(nil), false, "nil is invalid")

  ------------------------------------------------------------------
  -- Stub the modules collect() reads, then re-require lsp.registry so it
  -- binds to the stubs.
  ------------------------------------------------------------------
  local saved = {}
  for _, mod in ipairs({ "languages.registry", "tools.registry", "tools.detection", "lsp.registry" }) do
    saved[mod] = package.loaded[mod]
  end
  local function restore()
    for mod, value in pairs(saved) do
      package.loaded[mod] = value
    end
  end

  local languages_stub = {
    all = function()
      return {}
    end,
  }
  package.loaded["languages.registry"] = languages_stub
  package.loaded["tools.registry"] = {
    get = function(id)
      return { id = id, name = id, exe = id, category = "lsp", profiles = { "core" } }
    end,
  }
  -- Pretend every tool is installed, so collect() does not filter our
  -- synthetic languages out.
  package.loaded["tools.detection"] = {
    installed = function()
      return true
    end,
  }
  package.loaded["lsp.registry"] = nil
  local reg = require("lsp.registry")

  local ok, err = pcall(function()
    ----------------------------------------------------------------
    -- 1. root-marker order is preserved exactly as declared
    ----------------------------------------------------------------
    local declared = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" }
    languages_stub.all = function()
      return { { id = "python", filetypes = { "python" }, root_markers = declared, lsp = { tool = "pyright" } } }
    end
    local by_tool, conflicts = reg._collect()
    lib.assert_eq(#conflicts, 0, "no conflicts expected for a single language")
    lib.assert_eq(
      table.concat(by_tool.pyright.root_markers, ","),
      table.concat(declared, ","),
      "root marker order must survive unchanged (alphabetical sorting would put .git first)"
    )
    -- and it must reach the actual vim.lsp.config payload, not just the entry
    local config = reg._build_config(by_tool.pyright)
    lib.assert_eq(
      table.concat(config.root_markers, ","),
      table.concat(declared, ","),
      "root marker order must survive into the built config"
    )

    ----------------------------------------------------------------
    -- 2. nested marker groups keep their structure
    ----------------------------------------------------------------
    languages_stub.all = function()
      return {
        {
          id = "nested",
          filetypes = { "nested" },
          root_markers = { { "pyproject.toml", "setup.py" }, ".git" },
          lsp = { tool = "nestedls" },
        },
      }
    end
    by_tool = reg._collect()
    local markers = by_tool.nestedls.root_markers
    lib.assert_eq(type(markers[1]), "table", "first entry must remain a group, not be flattened")
    lib.assert_eq(markers[1][1], "pyproject.toml", "group contents preserved")
    lib.assert_eq(markers[1][2], "setup.py", "group contents preserved")
    lib.assert_eq(markers[2], ".git", "second tier preserved")

    ----------------------------------------------------------------
    -- 3. filetypes of several languages sharing a server are unioned
    --    deterministically, in declaration order, without duplicates
    ----------------------------------------------------------------
    languages_stub.all = function()
      return {
        { id = "c", filetypes = { "c" }, root_markers = { ".git" }, lsp = { tool = "clangd" } },
        { id = "cpp", filetypes = { "cpp", "objcpp", "c" }, root_markers = { ".git" }, lsp = { tool = "clangd" } },
      }
    end
    by_tool, conflicts = reg._collect()
    lib.assert_eq(#conflicts, 0, "identical shared config must not conflict")
    lib.assert_eq(
      table.concat(by_tool.clangd.filetypes, ","),
      "c,cpp,objcpp",
      "filetypes must union in declaration order with duplicates removed"
    )

    ----------------------------------------------------------------
    -- 4. identical settings on a shared server are allowed
    ----------------------------------------------------------------
    local shared_settings = { clangd = { fallbackFlags = { "-std=c++20" } } }
    languages_stub.all = function()
      return {
        {
          id = "c",
          filetypes = { "c" },
          root_markers = { ".git" },
          lsp = { tool = "clangd", settings = vim.deepcopy(shared_settings) },
        },
        {
          id = "cpp",
          filetypes = { "cpp" },
          root_markers = { ".git" },
          lsp = { tool = "clangd", settings = vim.deepcopy(shared_settings) },
        },
      }
    end
    by_tool, conflicts = reg._collect()
    lib.assert_eq(#conflicts, 0, "byte-identical settings must be accepted")

    ----------------------------------------------------------------
    -- 5. CONFLICTING settings on a shared server are reported, not merged
    ----------------------------------------------------------------
    languages_stub.all = function()
      return {
        {
          id = "c",
          filetypes = { "c" },
          root_markers = { ".git" },
          lsp = { tool = "clangd", settings = { clangd = { fallbackFlags = { "-std=c11" } } } },
        },
        {
          id = "cpp",
          filetypes = { "cpp" },
          root_markers = { ".git" },
          lsp = { tool = "clangd", settings = { clangd = { fallbackFlags = { "-std=c++20" } } } },
        },
      }
    end
    by_tool, conflicts = reg._collect()
    lib.assert_true(#conflicts > 0, "differing settings on a shared server must be reported")
    lib.assert_true(
      table.concat(conflicts, " "):find("settings", 1, true) ~= nil,
      "the conflict message must name the offending field"
    )
    -- The first language's value must survive verbatim rather than being
    -- deep-extended into an order-dependent hybrid.
    lib.assert_eq(
      by_tool.clangd.settings.clangd.fallbackFlags[1],
      "-std=c11",
      "conflicting settings must not be merged together"
    )

    ----------------------------------------------------------------
    -- 6. CONFLICTING root markers on a shared server are reported too
    ----------------------------------------------------------------
    languages_stub.all = function()
      return {
        {
          id = "c",
          filetypes = { "c" },
          root_markers = { "compile_commands.json", ".git" },
          lsp = { tool = "clangd" },
        },
        { id = "cpp", filetypes = { "cpp" }, root_markers = { ".git" }, lsp = { tool = "clangd" } },
      }
    end
    by_tool, conflicts = reg._collect()
    lib.assert_true(#conflicts > 0, "differing root_markers on a shared server must be reported")
    lib.assert_eq(
      table.concat(by_tool.clangd.root_markers, ","),
      "compile_commands.json,.git",
      "the first language's markers must survive verbatim, not be silently replaced"
    )

    ----------------------------------------------------------------
    -- 7. an invalid root marker is reported rather than passed through
    ----------------------------------------------------------------
    languages_stub.all = function()
      return { { id = "bad", filetypes = { "bad" }, root_markers = { "", ".git" }, lsp = { tool = "badls" } } }
    end
    local _, bad_conflicts = reg._collect()
    lib.assert_true(#bad_conflicts > 0, "an empty-string root marker must be reported")
  end)

  restore()
  if not ok then
    error(err, 0)
  end
end)
