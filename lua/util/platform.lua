-- Cross-platform facts. Every other module asks this one instead of
-- checking jit.os / vim.fn.has directly, so platform quirks live in one place.
local M = {}

M.is_mac = vim.uv.os_uname().sysname == "Darwin"
M.is_linux = vim.uv.os_uname().sysname == "Linux"
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
M.is_wsl = vim.fn.has("wsl") == 1

--- Executable suffix for the current OS ("" on unix, ".exe" on Windows).
M.exe_suffix = M.is_windows and ".exe" or ""

--- Path separator for display purposes (Neovim accepts "/" everywhere internally).
M.path_sep = M.is_windows and "\\" or "/"

function M.shell()
  if M.is_windows then
    return vim.o.shell ~= "" and vim.o.shell or "powershell"
  end
  return vim.env.SHELL or "/bin/sh"
end

--- Standard directories, always via stdpath (never hardcoded).
M.config_dir = vim.fn.stdpath("config")
M.data_dir = vim.fn.stdpath("data")
M.cache_dir = vim.fn.stdpath("cache")
M.state_dir = vim.fn.stdpath("state")

function M.describe()
  local uname = vim.uv.os_uname()
  local os_name = M.is_mac and "macOS" or M.is_linux and "Linux" or M.is_windows and "Windows" or uname.sysname
  return string.format("%s %s", os_name, uname.machine)
end

return M
