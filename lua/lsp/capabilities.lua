-- Client capabilities advertised to every language server. Extends Neovim's
-- own defaults with the completion plugin's additions when that plugin is
-- available, without hard-depending on it (LSP must work with completion
-- disabled/uninstalled too).
local M = {}

function M.default()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
  end
  capabilities.textDocument.completion.completionItem.snippetSupport = true
  return capabilities
end

return M
