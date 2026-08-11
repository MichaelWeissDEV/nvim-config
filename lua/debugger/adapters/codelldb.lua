-- Shared CodeLLDB adapter/config builder, used by every language that
-- debugs through it (C, C++, Rust, Assembly) so the server-launch
-- boilerplate exists exactly once.
local M = {}

function M.adapter()
  return {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = { command = "codelldb", args = { "--port", "${port}" } },
  }
end

--- @param name? string configuration display name
function M.configuration(name)
  return {
    name = name or "Debug binary",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Path to binary: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  }
end

return M
