local km = require("util.keymap_registry")
local python = require("util.python")

--- Apply exactly one ruff code action of `kind` (e.g. source.organizeImports.ruff).
--- Filtering on the ruff-specific kind keeps ty/basedpyright's own actions
--- out of it, so there is never a picker to answer.
--- @param kind string
local function ruff_action(kind)
  vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = true })
end

---@type table
return {
  filetypes = { "python" },
  extensions = { ".py", ".pyi" },
  treesitter = { "python" },
  root_markers = python.ROOT_MARKERS,
  -- Default: ty -- Astral's Rust-based type checker and language server.
  -- It discovers the project's .venv / $VIRTUAL_ENV / $CONDA_PREFIX by
  -- itself, so nothing interpreter-specific is configured here.
  -- `enabled` is re-evaluated on every registry refresh (startup, tool
  -- install, :PythonLsp), so switching servers needs no restart.
  lsp = {
    tool = "ty",
    extra = { cmd = { "ty", "server" } },
    enabled = function()
      return python.type_servers().ty == true
    end,
  },
  extra_lsp = {
    -- ruff's own server: lint diagnostics, quick fixes, fix-all and
    -- organize imports. Always on when installed; its config comes from
    -- the project's pyproject.toml / ruff.toml.
    {
      tool = "ruff",
      extra = {
        cmd = { "ruff", "server" },
        on_attach = function(client)
          -- ruff's hover only explains `# noqa` codes; leaving it on
          -- puts a second, mostly empty section into every K popup.
          client.server_capabilities.hoverProvider = false
        end,
      },
    },
    -- basedpyright: the alternative type checker (vim.g.nvim_config_python_lsp
    -- = "basedpyright" or "both"), and the automatic fallback when only it is
    -- installed.
    {
      tool = "basedpyright",
      -- basedpyright-langserver refuses to start without an explicit
      -- transport flag ("Connection input stream is not set") -- confirmed
      -- by actually running it, not assumed.
      extra = {
        cmd = { "basedpyright-langserver", "--stdio" },
        before_init = function(_, config)
          -- Point basedpyright at the project's virtualenv when there is
          -- one; otherwise leave its own discovery alone.
          local interpreter = python.interpreter(config.root_dir and (config.root_dir .. "/__init__.py") or nil)
          if interpreter then
            config.settings = config.settings or {}
            config.settings.python = vim.tbl_extend("force", config.settings.python or {}, {
              pythonPath = interpreter,
            })
          end
        end,
      },
      settings = {
        basedpyright = {
          -- ruff owns import sorting; two organize-imports actions would
          -- fight over the same lines.
          disableOrganizeImports = true,
          analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true },
        },
      },
      enabled = function()
        return python.type_servers().basedpyright == true
      end,
    },
  },
  formatters = { "ruff_format" },
  -- Intentionally empty: ruff's diagnostics come from its language server
  -- (extra_lsp above). Listing it here as well would report every problem
  -- twice.
  linters = {},
  debugger = {
    tool = "debugpy",
    adapter = function()
      return { type = "executable", command = "debugpy-adapter" }
    end,
    configurations = function()
      -- Resolved at launch time (nvim-dap calls function-valued fields), so
      -- the program runs under the project's .venv -- not under the
      -- interpreter Mason installed debugpy into, which cannot import the
      -- project's dependencies.
      local function interpreter()
        local file = vim.api.nvim_buf_get_name(0)
        local argv = require("util.process").resolve("python", file)
        return argv and argv[1] or "python3"
      end
      return {
        {
          type = "debugpy",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          python = interpreter,
          console = "integratedTerminal",
          justMyCode = true,
        },
        {
          type = "debugpy",
          request = "launch",
          name = "Launch file with arguments",
          program = "${file}",
          python = interpreter,
          args = function()
            return vim.split(vim.fn.input("Arguments: "), " ", { trimempty = true })
          end,
          console = "integratedTerminal",
        },
        {
          type = "debugpy",
          request = "launch",
          name = "pytest: current file",
          module = "pytest",
          python = interpreter,
          args = { "${file}", "-q" },
          console = "integratedTerminal",
          justMyCode = false,
        },
      }
    end,
  },
  keymaps = function(bufnr)
    local ctx = "Python buffer"
    km.map_many({
      {
        mode = "n",
        lhs = "<leader>cr",
        rhs = function()
          -- Resolves $VIRTUAL_ENV, then the project's .venv, then PATH;
          -- passes the path as a real argv element so a filename with
          -- spaces is not split. See lua/util/process.lua.
          require("util.process").run_current_file("python")
        end,
        desc = "Run current file",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>ct",
        rhs = "<cmd>Pytest file<cr>",
        desc = "pytest: current file",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>cT",
        rhs = "<cmd>Pytest nearest<cr>",
        desc = "pytest: test under cursor",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>cA",
        rhs = "<cmd>Pytest all<cr>",
        desc = "pytest: whole project",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>co",
        rhs = function()
          ruff_action("source.organizeImports.ruff")
        end,
        desc = "Organize imports (ruff)",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>cF",
        rhs = function()
          ruff_action("source.fixAll.ruff")
        end,
        desc = "Fix all auto-fixable problems (ruff)",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
      {
        mode = "n",
        lhs = "<leader>cv",
        rhs = "<cmd>PythonInfo<cr>",
        desc = "Python: interpreter, venv, language servers",
        group = "Code",
        context = ctx,
        buffer = bufnr,
      },
    })
  end,
  notes = "Language server: ty by default, basedpyright as alternative (:PythonLsp / "
    .. "vim.g.nvim_config_python_lsp); ruff's server always runs alongside for lint + fixes. "
    .. "Run/test/debug use $VIRTUAL_ENV, then the project's .venv/venv, then $CONDA_PREFIX, then PATH.",
}
