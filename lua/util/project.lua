-- Project root detection, shared by LSP client roots and language modules
-- so "what is the project root" is answered the same way everywhere.
local path = require("util.path")

local M = {}

--- @param bufnr integer
--- @param markers string[]
--- @return string root directory, falling back to the buffer's own directory
function M.root(bufnr, markers)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local start = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
  return path.find_root(start, markers) or start
end

return M
