local km = require("util.keymap_registry")

---@type table
return {
  filetypes = { "python" },
  extensions = { ".py", ".pyi" },
  treesitter = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  lsp = {
    tool = "basedpyright",
    -- basedpyright-langserver refuses to start without an explicit
    -- transport flag ("Connection input stream is not set") -- confirmed
    -- by actually running it, not assumed.
    extra = { cmd = { "basedpyright-langserver", "--stdio" } },
    -- .venv/venv/Poetry/uv are picked up by basedpyright's own venv
    -- discovery (pyproject.toml / pyrightconfig.json); we don't hardcode an
    -- interpreter path.
    settings = {
      basedpyright = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true } },
    },
  },
  -- ty runs alongside basedpyright, not instead of it (extra_lsp, see
  -- languages/registry.lua's schema comment): it's Astral's fast
  -- Rust-based type checker/LSP, still pre-1.0, and its diagnostics
  -- complement rather than replace basedpyright's completions/hover/
  -- rename. Both attach automatically once installed (`ty` has its own
  -- `note` in tools.registry pointing back here).
  extra_lsp = {
    { tool = "ty", extra = { cmd = { "ty", "server" } } },
  },
  formatters = { "ruff_format" },
  linters = { "ruff" },
  debugger = {
    tool = "debugpy",
    adapter = function()
      return { type = "executable", command = "debugpy-adapter" }
    end,
    configurations = function()
      return {
        {
          type = "debugpy",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          console = "integratedTerminal",
        },
      }
    end,
  },
  keymaps = function(bufnr)
    km.map({
      mode = "n",
      lhs = "<leader>cr",
      rhs = function()
        -- Resolves $VIRTUAL_ENV first, then platform-appropriate
        -- candidates; passes the path as a real argv element so a
        -- filename with spaces is not split. See lua/util/process.lua.
        require("util.process").run_current_file("python")
      end,
      desc = "Run current file",
      group = "Code",
      context = "Python buffer",
      buffer = bufnr,
    })
  end,
}
