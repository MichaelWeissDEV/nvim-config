-- DAP entry point. Nothing here loads nvim-dap (an `opt` package) until the
-- user presses one of these keymaps -- an empty `nvim` never pays for it,
-- and even a debugging session never loads nvim-dap-ui until a session is
-- actually started (dap.continue(), not just setting a breakpoint).
local km = require("util.keymap_registry")
local cmdreg = require("util.command_registry")
local lazyload = require("config.lazyload")
local scratch = require("util.scratch")

local dapui_ready = false

local function ensure_core()
  lazyload.packadd("nvim-dap")
  return require("dap")
end

local function ensure_ui()
  if dapui_ready then
    return
  end
  lazyload.packadd("nvim-nio")
  lazyload.packadd("nvim-dap-ui")
  local dap = ensure_core()
  local dapui = require("dapui")
  dapui.setup()
  dap.listeners.after.event_initialized["nvim-config-dapui"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["nvim-config-dapui"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["nvim-config-dapui"] = function()
    dapui.close()
  end
  dapui_ready = true
end

local function start_or_continue()
  local registry = require("debugger.registry")
  local ft = vim.bo.filetype
  if not registry.ensure_for_filetype(ft) then
    return
  end
  ensure_ui()
  ensure_core().continue()
end

km.map_many({
  {
    mode = "n",
    lhs = "<leader>db",
    rhs = function()
      ensure_core().toggle_breakpoint()
    end,
    desc = "Toggle breakpoint",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>dB",
    rhs = function()
      ensure_core().set_breakpoint(vim.fn.input("Condition: "))
    end,
    desc = "Conditional breakpoint",
    group = "Debug",
  },
  { mode = "n", lhs = "<leader>dc", rhs = start_or_continue, desc = "Start / Continue", group = "Debug" },
  {
    mode = "n",
    lhs = "<leader>di",
    rhs = function()
      ensure_core().step_into()
    end,
    desc = "Step into",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>do",
    rhs = function()
      ensure_core().step_over()
    end,
    desc = "Step over",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>dO",
    rhs = function()
      ensure_core().step_out()
    end,
    desc = "Step out",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>dr",
    rhs = function()
      ensure_core().repl.toggle()
    end,
    desc = "Toggle REPL",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>du",
    rhs = function()
      ensure_ui()
      require("dapui").toggle()
    end,
    desc = "Toggle debug UI",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>dt",
    rhs = function()
      ensure_core().terminate()
    end,
    desc = "Terminate session",
    group = "Debug",
  },
  {
    mode = "n",
    lhs = "<leader>dl",
    rhs = function()
      ensure_core().run_last()
    end,
    desc = "Run last configuration",
    group = "Debug",
  },
})

cmdreg.command({
  name = "DebuggerStatus",
  desc = "Show which languages have a debugger configured and whether its adapter binary is installed",
  category = "Debugging",
  example = ":DebuggerStatus",
  fn = function()
    local lines = { "# Debugger Status", "" }
    for _, row in ipairs(require("debugger.registry").all()) do
      table.insert(
        lines,
        string.format("- [%s] %-14s -> %s", row.installed and "OK" or "MISSING", row.language, row.tool)
      )
    end
    scratch.open("nvim-config://debugger-status", lines)
  end,
})
