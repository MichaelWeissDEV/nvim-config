-- Global diagnostic presentation + navigation. Independent of which LSP (if
-- any) produced the diagnostics, so these keymaps work even for buffers with
-- no language server attached (e.g. linter-only diagnostics via nvim-lint).
local km = require("util.keymap_registry")

local M = {}

-- Nerd Font glyphs, written as \u{...} escapes rather than pasted literals:
-- the literal characters get silently stripped by some editors and tooling
-- (they were empty strings in this file for a while, which is exactly the
-- failure this avoids). Codepoints are the classic Font Awesome set present
-- in every Nerd Font build: times-circle, exclamation-triangle, lightbulb,
-- info-circle. Without a Nerd Font installed these render as boxes -- see
-- the Requirements section of the README.
local SIGNS = {
  [vim.diagnostic.severity.ERROR] = "\u{f057} ",
  [vim.diagnostic.severity.WARN] = "\u{f071} ",
  [vim.diagnostic.severity.HINT] = "\u{f0eb} ",
  [vim.diagnostic.severity.INFO] = "\u{f05a} ",
}

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  -- Not while typing: re-rendering diagnostics on every keystroke is the
  -- same class of problem that made inlay hints feel laggy (see docs/lsp).
  update_in_insert = false,
  virtual_text = {
    spacing = 2,
    source = "if_many",
    prefix = "\u{25cf}", -- ● U+25CF, plain Unicode, no Nerd Font needed
  },
  -- Off by default. virtual_lines renders the full message as extra screen
  -- lines beneath the code, so the buffer visibly reflows as the cursor
  -- moves -- the line you are reading shifts down and back up again. That
  -- is a lot of motion for information you did not ask for.
  --
  -- Nothing is lost by having it off: the underline, the sign and the
  -- end-of-line virtual_text above all still mark the problem. The full
  -- text is one keypress away in a floating window (<leader>xl), and
  -- <leader>xv turns this back on when a particular buffer warrants it.
  virtual_lines = false,
  signs = { text = SIGNS },
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

--- Turn the inline multi-line detail (`virtual_lines`) on or off for the
--- whole session, and report which it now is.
---
--- Written as a plain if/else rather than the usual `cond and a or b`: with
--- `false` as the middle operand that idiom silently collapses -- `x and
--- false or y` is always `y` -- so the previous one-liner could only ever
--- switch this *on* while announcing that it had switched it off.
--- @return boolean enabled the state it is in now
function M.toggle_virtual_lines()
  local enabled = vim.diagnostic.config().virtual_lines ~= false
  if enabled then
    vim.diagnostic.config({ virtual_lines = false })
  else
    vim.diagnostic.config({ virtual_lines = { current_line = true } })
  end
  vim.notify("Inline diagnostic details: " .. (enabled and "off" or "on"))
  return not enabled
end

--- Enable or disable diagnostics in the current buffer.
--- @return boolean enabled the state it is in now
function M.toggle_buffer()
  local enabled = vim.diagnostic.is_enabled({ bufnr = 0 })
  vim.diagnostic.enable(not enabled, { bufnr = 0 })
  vim.notify("Diagnostics in this buffer: " .. (enabled and "off" or "on"))
  return not enabled
end

km.map_many({
  {
    mode = "n",
    lhs = "[d",
    rhs = function()
      vim.diagnostic.jump({ count = -1, float = true })
    end,
    desc = "Previous diagnostic",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "]d",
    rhs = function()
      vim.diagnostic.jump({ count = 1, float = true })
    end,
    desc = "Next diagnostic",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xl",
    rhs = vim.diagnostic.open_float,
    desc = "Line diagnostics (float)",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xq",
    rhs = function()
      vim.diagnostic.setqflist({ open = true })
    end,
    desc = "Diagnostics to quickfix",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xv",
    rhs = M.toggle_virtual_lines,
    desc = "Toggle inline diagnostic details (virtual_lines, off by default)",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xt",
    rhs = M.toggle_buffer,
    desc = "Toggle diagnostics in this buffer",
    group = "Diagnostics",
  },
})

return M
