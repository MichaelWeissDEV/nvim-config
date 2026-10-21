-- Copy this file to lua/config/local.lua (gitignored) and uncomment what
-- you want. Loaded by lua/config/local_overrides.lua right after
-- config/options.lua, before any plugin or language module reads a setting.
-- A broken local.lua is reported loudly at startup; a missing one is fine.

-- Python language server: "ty" (default, Astral's fast type checker/LSP),
-- "basedpyright", or "both" (two type checkers = duplicate diagnostics).
-- ruff's own server (lint + quick fixes + organize imports) runs regardless.
-- Can also be switched for the running session with :PythonLsp.
-- vim.g.nvim_config_python_lsp = "ty"

-- Render markdown in the editor as soon as a markdown buffer opens.
-- Default: off -- markdown is shown as plain text; <leader>um toggles.
-- vim.g.nvim_config_markdown_render = true

-- Turn off format-on-save everywhere (per buffer: <leader>uf).
-- vim.g.disable_autoformat = true

-- Highlight other references to the symbol under the cursor (LSP
-- documentHighlight). Default: on.
-- vim.g.nvim_config_reference_highlight = false

-- Any other personal vim.opt tweaks belong here too, e.g.:
-- vim.opt.relativenumber = false
