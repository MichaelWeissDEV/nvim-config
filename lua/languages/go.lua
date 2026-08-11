---@type table
return {
  filetypes = { "go", "gomod", "gowork", "gosum" },
  extensions = { ".go" },
  treesitter = { "go", "gomod", "gowork", "gosum" },
  root_markers = { "go.mod", "go.work", ".git" },
  lsp = {
    tool = "gopls",
    settings = {
      gopls = { gofumpt = true, staticcheck = true, hints = { assignVariableTypes = true } },
    },
  },
  formatters = { "gofumpt" },
  linters = { "golangci_lint" },
  debugger = {
    tool = "delve",
    adapter = function()
      return { type = "server", port = "${port}", executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } } }
    end,
    configurations = function()
      return {
        { type = "delve", name = "Debug package", request = "launch", program = "${fileDirname}" },
      }
    end,
  },
}
