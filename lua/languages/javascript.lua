---@type table
return {
  filetypes = { "javascript", "javascriptreact" },
  extensions = { ".js", ".jsx", ".mjs", ".cjs" },
  treesitter = { "javascript" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  lsp = { tool = "vtsls" },
  formatters = { "prettier" },
  linters = { "eslint" },
  debugger = {
    tool = "js_debug_adapter",
    adapter = function()
      return {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = { command = "js-debug-adapter", args = { "${port}" } },
      }
    end,
    configurations = function()
      return {
        { type = "js_debug_adapter", request = "launch", name = "Launch file", program = "${file}", cwd = "${workspaceFolder}" },
      }
    end,
  },
}
