-- Buffer-local LSP keymaps, applied only once a client actually attaches to
-- a buffer -- never registered globally, so pressing `gd` in a buffer with
-- no LSP just does whatever the fallback/plugin mapping does instead of
-- silently failing against a dead client.
local km = require("util.keymap_registry")

local M = {}

function M.setup()
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local ctx = "LSP attached"

      km.map_many({
        { mode = "n", lhs = "gd", rhs = vim.lsp.buf.definition, desc = "Go to definition", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "gD", rhs = vim.lsp.buf.declaration, desc = "Go to declaration", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "gr", rhs = vim.lsp.buf.references, desc = "Go to references", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "gi", rhs = vim.lsp.buf.implementation, desc = "Go to implementation", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "K", rhs = vim.lsp.buf.hover, desc = "Hover documentation", group = "LSP", context = ctx, buffer = bufnr },
        { mode = { "n", "i" }, lhs = "<C-k>", rhs = vim.lsp.buf.signature_help, desc = "Signature help", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "<leader>lr", rhs = vim.lsp.buf.rename, desc = "Rename symbol", group = "LSP", context = ctx, buffer = bufnr },
        { mode = { "n", "v" }, lhs = "<leader>la", rhs = vim.lsp.buf.code_action, desc = "Code action", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "<leader>ls", rhs = vim.lsp.buf.document_symbol, desc = "Document symbols", group = "LSP", context = ctx, buffer = bufnr },
        { mode = "n", lhs = "<leader>li", rhs = "<cmd>LspStatus<cr>", desc = "LSP status", group = "LSP", context = ctx, buffer = bufnr },
      })

      if client and client:supports_method("textDocument/inlayHint") then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
    end,
  })
end

return M
