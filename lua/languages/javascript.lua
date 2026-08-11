---@type table
return {
  filetypes = { "javascript", "javascriptreact" },
  extensions = { ".js", ".jsx", ".mjs", ".cjs" },
  treesitter = { "javascript" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  lsp = { tool = "vtsls", extra = { cmd = { "vtsls", "--stdio" } } },
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
        {
          type = "js_debug_adapter",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
        },
      }
    end,
  },
  notes = "Config type is 'js_debug_adapter', not vscode-js-debug's usual 'pwa-node': "
    .. "dap/registry.lua registers dap.adapters keyed by debugger.tool, and nvim-dap "
    .. "resolves dap.adapters[config.type] at run time, so the two must match exactly.",
}
