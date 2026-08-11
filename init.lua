-- Entry point. Deliberately thin: every concern lives in lua/ and gets
-- required here in dependency order. See docs/architecture.rst for the
-- full picture, or :NvimDocs / :help nvim-config from inside Neovim.

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
