-- One persistent terminal at the bottom of the screen, toggled with
-- <C-/> (or <leader>tt). Hiding it keeps the shell running, so the next
-- toggle comes back to the same session, scrollback and all. Native
-- :terminal only -- no plugin.
local km = require("util.keymap_registry")
local cmdreg = require("util.command_registry")

local M = {}

local state = { buf = nil, height = 15 }

--- @return integer|nil window currently showing the terminal
local function visible_win()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == state.buf then
      return win
    end
  end
  return nil
end

--- Show the terminal (creating it on first use) or hide it if visible.
function M.toggle()
  local win = visible_win()
  if win then
    state.height = vim.api.nvim_win_get_height(win)
    vim.api.nvim_win_hide(win)
    return
  end
  vim.cmd("botright " .. state.height .. "split")
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_win_set_buf(0, state.buf)
  else
    vim.cmd.enew()
    vim.fn.jobstart(vim.o.shell, {
      term = true,
      on_exit = function()
        -- `exit` in the shell: forget the buffer so the next toggle starts
        -- a fresh shell instead of showing a dead one.
        state.buf = nil
      end,
    })
    state.buf = vim.api.nvim_get_current_buf()
    vim.bo[state.buf].buflisted = false
  end
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.cmd.startinsert()
end

km.map_many({
  { mode = { "n", "t" }, lhs = "<C-/>", rhs = M.toggle, desc = "Toggle terminal", group = "Terminal" },
  -- Most terminals send <C-/> as <C-_>; map both so the key works everywhere.
  {
    mode = { "n", "t" },
    lhs = "<C-_>",
    rhs = M.toggle,
    desc = "Toggle terminal (<C-/> as sent by most terminals)",
    group = "Terminal",
  },
  { mode = "n", lhs = "<leader>tt", rhs = M.toggle, desc = "Toggle terminal", group = "Terminal" },
  -- <Esc> itself stays with the shell (vi-mode, fzf, ...); a double press
  -- leaves terminal mode so you can scroll, search and yank output.
  { mode = "t", lhs = "<Esc><Esc>", rhs = "<C-\\><C-n>", desc = "Leave terminal mode", group = "Terminal" },
})

cmdreg.command({
  name = "TermToggle",
  desc = "Toggle the persistent terminal split at the bottom of the screen",
  category = "Terminal",
  example = ":TermToggle",
  fn = M.toggle,
})

return M
