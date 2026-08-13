-- Entry point. Deliberately thin: every concern lives in lua/ and gets
-- required here in dependency order. See docs/architecture.rst for the
-- full picture, or :NvimDocs / :help nvim-config from inside Neovim.

-- Bootstrap for `nvim -u /path/to/init.lua`, which is how CI and the test
-- suite start Neovim. Only stdpath("config") is on 'runtimepath'/'packpath'
-- by default, and on a fresh runner that directory does not exist -- so
-- without this, require("config.*") fails, and even with 'runtimepath'
-- fixed, require() of a vendored plugin under pack/vendor/start/ still
-- fails because package loading keys off 'packpath', not 'runtimepath'.
-- Both were observed failing in CI; both are needed.
--
-- The root is derived from this file's own path via debug.getinfo rather
-- than MYVIMRC or a relative "init.lua": MYVIMRC is nil under `-u <file>`
-- (verified), and a relative path would resolve against the current
-- working directory, making startup depend on where nvim was invoked from.
--
-- No-op for a normal install where the repo already is stdpath("config"),
-- since prepending a path that is already present just reorders it.
local config_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
if vim.fn.isdirectory(config_root .. "/lua") == 1 then
  vim.opt.runtimepath:prepend(config_root)
  vim.opt.packpath:prepend(config_root)
end

require("config.options") -- vim.opt, leader keys -- must come first
require("config.platform") -- OS-specific vim.opt overrides
require("config.diagnostics") -- vim.diagnostic.config + nav keymaps
require("config.keymaps") -- general keymaps
require("config.autocmds") -- autocommands, incl. large-file handling
require("config.commands") -- :NvimConfigHealth / :NvimCommands / :NvimKeymaps / :NvimDocs

require("tools") -- :ToolsStatus / :ToolsInstall / :ToolsUpdate
require("plugins") -- core plugin configuration + optional-plugin triggers
require("lsp") -- native LSP config, gated per-language by tools.registry
require("debugger") -- DAP core (adapters + UI load lazily on first debug action); named
-- "debugger", not "dap", because the vendored nvim-dap plugin itself is require("dap") --
-- reusing that name would let whichever module loads first shadow the other in package.loaded.
require("languages") -- FileType-driven per-language activation
