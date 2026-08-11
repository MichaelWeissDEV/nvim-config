local km = require("util.keymap_registry")

---@type table
return {
  filetypes = { "rust" },
  extensions = { ".rs" },
  treesitter = { "rust" },
  root_markers = { "Cargo.toml", ".git" },
  lsp = {
    tool = "rust_analyzer",
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        checkOnSave = true,
        check = { command = "clippy" },
      },
    },
  },
  formatters = { "rustfmt" },
  linters = {}, -- clippy runs via checkOnSave through rust-analyzer, not nvim-lint,
  -- so it never fires on every keypress independently of the LSP's own debounce.
  debugger = {
    tool = "codelldb",
    adapter = require("dap.adapters.codelldb").adapter,
    configurations = function()
      return { require("dap.adapters.codelldb").configuration("Debug Cargo binary") }
    end,
  },
  keymaps = function(bufnr)
    km.map({
      mode = "n",
      lhs = "<leader>ci",
      rhs = function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end,
      desc = "Toggle inlay hints",
      group = "Code",
      context = "Rust buffer",
      buffer = bufnr,
    })
  end,
}
