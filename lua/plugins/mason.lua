-- mason.nvim itself: just the installer UI/commands (:Mason, :MasonInstall,
-- :MasonUpdate). Loading and calling setup() does NOT contact the network
-- or refresh the registry -- that only happens when :Mason, :MasonInstall,
-- or :ToolsInstall/:ToolsUpdate (tools/install.lua) are run explicitly.
--
-- mason-lspconfig is intentionally NOT vendored: its `automatic_enable`
-- defaults to on in 2.x, which would start LSP servers based on whatever
-- Mason happens to have installed -- duplicating and fighting
-- lsp/registry.lua, which is the single source of truth for "which server
-- starts for which filetype" in this config.
require("mason").setup({
  ui = { border = "rounded" },
})

local cmdreg = require("util.command_registry")
cmdreg.external({ name = "Mason", desc = "Open the Mason installer UI", category = "Tools", example = ":Mason" })
cmdreg.external({
  name = "MasonInstall",
  desc = "Install a specific Mason package (network; explicit action only)",
  category = "Tools",
  args = "<package>...",
  example = ":MasonInstall rust-analyzer",
})
cmdreg.external({
  name = "MasonUpdate",
  desc = "Refresh the Mason registry (network; explicit action only)",
  category = "Tools",
  example = ":MasonUpdate",
})
