---@type table
return {
  filetypes = { "ruby" },
  extensions = { ".rb" },
  treesitter = { "ruby" },
  root_markers = { "Gemfile", ".git" },
  lsp = { tool = "ruby_lsp" },
  formatters = { "rubocop" },
  linters = { "rubocop_lint" },
  debugger = {
    tool = "rdbg",
    adapter = function()
      return {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = { command = "rdbg", args = { "--open", "--port", "${port}", "--", "ruby", "${file}" } },
      }
    end,
    configurations = function()
      return {
        { type = "rdbg", request = "attach", name = "Debug current file" },
      }
    end,
  },
  notes = "rdbg wiring is best-effort; debug.gem's launch protocol has shifted across versions.",
}
