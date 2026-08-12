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
    adapter = require("debugger.adapters.codelldb").adapter,
    configurations = function()
      return { require("debugger.adapters.codelldb").configuration("Debug Cargo binary") }
    end,
  },
  -- Inlay-hint toggle is a global LSP keymap now (lsp/attach.lua,
  -- <leader>ci) available for every capable server, not just this one.
}
