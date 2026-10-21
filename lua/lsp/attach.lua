-- Buffer-local LSP keymaps, applied only once a client actually attaches to
-- a buffer -- never registered globally, so pressing `gd` in a buffer with
-- no LSP just does whatever the fallback/plugin mapping does instead of
-- silently failing against a dead client.
--
-- Navigation that can return many results (references, implementations,
-- symbols) goes through Telescope, loaded on first use; single-target jumps
-- (definition, declaration, type definition) use the native functions and
-- jump straight there. <C-o> / <C-i> jump back and forward again, and
-- because the LSP client sets 'tagfunc', <C-]> and <C-w>] (definition in a
-- split) work too.
local km = require("util.keymap_registry")

local M = {}

local function pick(name)
  return function()
    require("plugins.telescope").pick(name)
  end
end

--- Highlight other occurrences of the symbol under the cursor while the
--- cursor rests (CursorHold, i.e. 'updatetime'), cleared as soon as it
--- moves. Off with vim.g.nvim_config_reference_highlight = false.
--- @param client vim.lsp.Client
--- @param bufnr integer
local function reference_highlight(client, bufnr)
  if vim.g.nvim_config_reference_highlight == false then
    return
  end
  if not client:supports_method("textDocument/documentHighlight") then
    return
  end
  local group = vim.api.nvim_create_augroup("nvim_config_lsp_highlight_" .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = group,
    buffer = bufnr,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
    group = group,
    buffer = bufnr,
    callback = vim.lsp.buf.clear_references,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    buffer = bufnr,
    callback = function(args)
      -- Only tear down when the last highlight-capable client leaves.
      for _, other in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if other.id ~= args.data.client_id and other:supports_method("textDocument/documentHighlight") then
          return
        end
      end
      vim.lsp.buf.clear_references()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

function M.setup()
  -- Only mapped when the attached server supports inlay hints (below), so
  -- it is documented up front instead of depending on which server
  -- happened to attach first.
  km.document({
    mode = "n",
    lhs = "<leader>ci",
    desc = "Toggle inlay hints (servers that support them)",
    group = "Code",
    context = "LSP attached",
  })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      local ctx = "LSP attached"

      km.map_many({
        {
          mode = "n",
          lhs = "gd",
          rhs = function()
            vim.lsp.buf.definition({ reuse_win = true })
          end,
          desc = "Go to definition",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "gD",
          rhs = vim.lsp.buf.declaration,
          desc = "Go to declaration",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "gy",
          rhs = function()
            vim.lsp.buf.type_definition({ reuse_win = true })
          end,
          desc = "Go to type definition",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          -- nowait: Neovim's own grr/grn/gra/gri/grt defaults share the
          -- `gr` prefix, so without it every `gr` would pause for
          -- 'timeoutlen' to see whether another key follows. Their
          -- functions all have a key of their own here.
          mode = "n",
          lhs = "gr",
          rhs = pick("lsp_references"),
          desc = "Go to references",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
          nowait = true,
        },
        {
          mode = "n",
          lhs = "gi",
          rhs = pick("lsp_implementations"),
          desc = "Go to implementation",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "K",
          rhs = vim.lsp.buf.hover,
          desc = "Hover documentation",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          -- Insert mode only: in normal mode <C-k> is "window up" and a
          -- buffer-local mapping here used to shadow it in every LSP buffer.
          mode = "i",
          lhs = "<C-k>",
          rhs = vim.lsp.buf.signature_help,
          desc = "Signature help",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "gK",
          rhs = vim.lsp.buf.signature_help,
          desc = "Signature help",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>lr",
          rhs = vim.lsp.buf.rename,
          desc = "Rename symbol",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = { "n", "v" },
          lhs = "<leader>la",
          rhs = vim.lsp.buf.code_action,
          desc = "Code action",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>ls",
          rhs = pick("lsp_document_symbols"),
          desc = "Document symbols",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>lS",
          rhs = pick("lsp_dynamic_workspace_symbols"),
          desc = "Workspace symbols",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>lI",
          rhs = pick("lsp_incoming_calls"),
          desc = "Incoming calls (who calls this)",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>lO",
          rhs = pick("lsp_outgoing_calls"),
          desc = "Outgoing calls (what this calls)",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>lR",
          rhs = "<cmd>lsp restart<cr>",
          desc = "Restart language server(s)",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
        {
          mode = "n",
          lhs = "<leader>li",
          rhs = "<cmd>LspStatus<cr>",
          desc = "LSP status",
          group = "LSP",
          context = ctx,
          buffer = bufnr,
        },
      })

      -- Inlay hints are opt-in via this toggle, not auto-enabled on attach.
      -- Neovim's built-in inlay_hint module re-requests hints from every
      -- capable client on every textDocument/didChange (see
      -- vim/lsp/inlay_hint.lua's LspNotify autocmd) -- i.e. on every
      -- debounced keystroke while typing. Auto-enabling it made typing feel
      -- laggy on large files/projects, and for at least one real case
      -- produced clangd's "invalid AST" error (-32001) -- clangd throws
      -- that when a request outruns its ability to keep the AST in sync,
      -- which frequent hint requests on a large translation unit does
      -- exactly that.
      if client and client:supports_method("textDocument/inlayHint") then
        km.map({
          mode = "n",
          lhs = "<leader>ci",
          rhs = function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
          end,
          desc = "Toggle inlay hints",
          group = "Code",
          context = ctx,
          buffer = bufnr,
        })
      end

      if client then
        reference_highlight(client, bufnr)
      end
    end,
  })
end

return M
