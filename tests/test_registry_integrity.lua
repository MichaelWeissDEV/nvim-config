-- Registry integrity checks.
--
-- Registry mistakes do not crash Neovim: they produce a language that
-- silently never gets a formatter, or documentation describing a tool that
-- does not exist. The validator turns those into findable errors, and this
-- test proves it actually catches each class -- a validator that reports
-- "OK" for everything is worse than none.
local this_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
local lib = dofile(this_dir .. "/lib.lua")

lib.run("registry integrity: real registry valid, synthetic breakage caught", function()
  local integrity = require("config.integrity")

  ------------------------------------------------------------------
  -- 1. the registry this repository actually ships must be valid
  ------------------------------------------------------------------
  local real = integrity.check_current()
  if #real > 0 then
    error("the real registry has integrity problems:\n" .. table.concat(integrity.format(real), "\n"), 0)
  end

  ------------------------------------------------------------------
  -- Synthetic registries for the failure cases.
  ------------------------------------------------------------------
  local function tools_stub(entries)
    local by_id = {}
    for _, t in ipairs(entries) do
      t.categories = { [t.category] = true }
      for _, extra in ipairs(t.also or {}) do
        t.categories[extra] = true
      end
      by_id[t.id] = t
    end
    return {
      profiles = { "core" },
      all = function()
        return entries
      end,
      get = function(id)
        return by_id[id]
      end,
    }
  end

  local function languages_stub(specs)
    return {
      all = function()
        return specs
      end,
    }
  end

  local base_tools = tools_stub({
    { id = "some_ls", name = "some_ls", category = "lsp", exe = "some_ls", profiles = { "core" } },
    { id = "some_fmt", name = "some_fmt", category = "formatter", exe = "some_fmt", profiles = { "core" } },
    { id = "dual", name = "dual", category = "formatter", also = { "linter" }, exe = "dual", profiles = { "core" } },
  })

  local function messages(problems)
    local out = {}
    for _, p in ipairs(problems) do
      table.insert(out, p.scope .. ": " .. p.message)
    end
    return table.concat(out, "\n")
  end

  ------------------------------------------------------------------
  -- 2. duplicate language id
  ------------------------------------------------------------------
  local problems = integrity.check(
    languages_stub({
      { id = "dup", filetypes = { "a" } },
      { id = "dup", filetypes = { "b" } },
    }),
    base_tools
  )
  lib.assert_true(messages(problems):find("duplicate language id", 1, true) ~= nil, "duplicate language id not caught")

  ------------------------------------------------------------------
  -- 3. unknown tool reference
  ------------------------------------------------------------------
  problems = integrity.check(
    languages_stub({ { id = "x", filetypes = { "x" }, lsp = { tool = "does_not_exist" } } }),
    base_tools
  )
  lib.assert_true(messages(problems):find("unknown tool", 1, true) ~= nil, "unknown tool reference not caught")

  ------------------------------------------------------------------
  -- 4. wrong-category reference (formatter list pointing at an LSP)
  ------------------------------------------------------------------
  problems = integrity.check(languages_stub({ { id = "x", filetypes = { "x" }, formatters = { "some_ls" } } }), base_tools)
  lib.assert_true(messages(problems):find("not a formatter", 1, true) ~= nil, "wrong-category reference not caught")

  -- ...but a genuinely multi-role tool must NOT be flagged
  problems = integrity.check(languages_stub({ { id = "x", filetypes = { "x" }, linters = { "dual" } } }), base_tools)
  lib.assert_eq(#problems, 0, "a tool declaring a secondary role must validate: " .. messages(problems))

  ------------------------------------------------------------------
  -- 5. duplicate filetype across two languages
  ------------------------------------------------------------------
  problems = integrity.check(
    languages_stub({
      { id = "one", filetypes = { "shared" } },
      { id = "two", filetypes = { "shared" } },
    }),
    base_tools
  )
  lib.assert_true(messages(problems):find("already claimed", 1, true) ~= nil, "duplicate filetype not caught")

  ------------------------------------------------------------------
  -- 6. invalid root marker
  ------------------------------------------------------------------
  problems = integrity.check(languages_stub({ { id = "x", filetypes = { "x" }, root_markers = { "" } } }), base_tools)
  lib.assert_true(messages(problems):find("root_markers", 1, true) ~= nil, "invalid root marker not caught")

  ------------------------------------------------------------------
  -- 7. debugger config whose type does not match the adapter key
  ------------------------------------------------------------------
  problems = integrity.check(
    languages_stub({
      {
        id = "x",
        filetypes = { "x" },
        debugger = {
          tool = "some_fmt",
          adapter = function() return {} end,
          configurations = function()
            return { { type = "something_else" } }
          end,
        },
      },
    }),
    base_tools
  )
  lib.assert_true(
    messages(problems):find("adapters are registered under", 1, true) ~= nil,
    "mismatched debugger config type not caught"
  )

  ------------------------------------------------------------------
  -- 8. MULTIPLE problems are reported together, not one at a time
  ------------------------------------------------------------------
  problems = integrity.check(
    languages_stub({
      { id = "dup", filetypes = { "shared" }, lsp = { tool = "nope" } },
      { id = "dup", filetypes = { "shared" }, formatters = { "also_nope" } },
      { id = "third", filetypes = { "" } },
    }),
    base_tools
  )
  lib.assert_true(#problems >= 4, "expected several problems in one run, got " .. #problems .. ":\n" .. messages(problems))

  ------------------------------------------------------------------
  -- 9. output is deterministic -- same input, byte-identical output
  ------------------------------------------------------------------
  local function run_again()
    return messages(integrity.check(
      languages_stub({
        { id = "b", filetypes = { "b" }, lsp = { tool = "nope" } },
        { id = "a", filetypes = { "a" }, formatters = { "nope" } },
      }),
      base_tools
    ))
  end
  lib.assert_eq(run_again(), run_again(), "validator output must be deterministic")

  ------------------------------------------------------------------
  -- 10. a missing language module is reported
  ------------------------------------------------------------------
  problems = integrity.check(languages_stub({ { id = "ghost", filetypes = { "ghost" } } }), base_tools, {
    module_exists = function()
      return false
    end,
  })
  lib.assert_true(messages(problems):find("does not exist", 1, true) ~= nil, "missing language module not caught")
end)
