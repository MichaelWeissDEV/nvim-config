local km = require("util.keymap_registry")

---@type table
return {
  filetypes = { "python" },
  extensions = { ".py", ".pyi" },
  treesitter = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  lsp = {
    tool = "basedpyright",
    -- .venv/venv/Poetry/uv are picked up by basedpyright's own venv
    -- discovery (pyproject.toml / pyrightconfig.json); we don't hardcode an
    -- interpreter path.
    settings = {
      basedpyright = { analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true } },
    },
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
      rhs = "<cmd>update<cr><cmd>split | terminal python3 %<cr>",
      desc = "Run current file",
      group = "Code",
      context = "Python buffer",
      buffer = bufnr,
    })
  end,
}
