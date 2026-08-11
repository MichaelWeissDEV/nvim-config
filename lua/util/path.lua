-- Path helpers built on vim.fs so behavior is identical on macOS/Linux/Windows.
local M = {}

--- @param ... string path segments
--- @return string
function M.join(...)
  return vim.fs.joinpath(...)
end

--- @param path string
--- @return boolean
function M.exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

--- @param path string
--- @return boolean
function M.is_dir(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == "directory"
end

--- Walk upward from `start` looking for any of `markers` (files or dirs).
--- @param start string a file or directory path
--- @param markers string[]
--- @return string|nil the directory containing the first marker found
function M.find_root(start, markers)
  local found = vim.fs.find(markers, {
    path = start,
    upward = true,
    stop = vim.uv.os_homedir(),
  })[1]
  if not found then
    return nil
  end
  return vim.fs.dirname(found)
end

return M
