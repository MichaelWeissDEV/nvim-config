-- Shared helper for the small read-only report buffers used by
-- :NvimCommands, :NvimKeymaps, :ToolsStatus, etc. Deliberately not a
-- floating-window framework -- just a split with sane, closeable defaults.
local M = {}

--- @param title string used as the buffer name and window title
--- @param lines string[]
--- @param filetype? string defaults to "markdown" for basic highlighting
function M.open(title, lines, filetype)
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = filetype or "markdown"
  pcall(vim.api.nvim_buf_set_name, buf, title)
  vim.api.nvim_win_set_height(win, math.min(#lines + 1, math.floor(vim.o.lines * 0.5)))

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close" })
end

return M
