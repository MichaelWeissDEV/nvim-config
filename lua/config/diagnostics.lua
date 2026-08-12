-- Global diagnostic presentation + navigation. Independent of which LSP (if
-- any) produced the diagnostics, so these keymaps work even for buffers with
-- no language server attached (e.g. linter-only diagnostics via nvim-lint).
local km = require("util.keymap_registry")

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
  -- Full multi-line message for the diagnostic under the cursor only.
  -- Restricting to current_line keeps long messages readable without
  -- pushing the whole buffer around, which `virtual_lines = true` does.
  -- Toggle it off/on with <leader>xv.
  virtual_lines = { current_line = true },
  signs = { text = SIGNS },
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

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
    rhs = function()
      local current = vim.diagnostic.config().virtual_lines
      vim.diagnostic.config({ virtual_lines = current and false or { current_line = true } })
      vim.notify("Inline diagnostic details: " .. (current and "off" or "on"))
    end,
    desc = "Toggle inline diagnostic details (virtual_lines)",
    group = "Diagnostics",
  },
  {
    mode = "n",
    lhs = "<leader>xt",
    rhs = function()
      local enabled = vim.diagnostic.is_enabled({ bufnr = 0 })
      vim.diagnostic.enable(not enabled, { bufnr = 0 })
      vim.notify("Diagnostics in this buffer: " .. (enabled and "off" or "on"))
    end,
    desc = "Toggle diagnostics in this buffer",
    group = "Diagnostics",
  },
})
