---@type table
return {
  filetypes = { "bash", "sh" },
  extensions = { ".sh", ".bash" },
  treesitter = { "bash" },
  root_markers = { ".git" },
  -- bash-language-server's CLI requires the "start" subcommand (it prints
  -- usage and exits without it, defaulting to stdio only once started).
  lsp = { tool = "bashls", extra = { cmd = { "bash-language-server", "start" } } },
  formatters = { "shfmt" },
  linters = { "shellcheck" },
  debugger = {
    tool = "bashdb",
    adapter = function()
      return { type = "executable", command = "bashdb", args = { "${file}" } }
    end,
    configurations = function()
      return {
        { type = "bashdb", request = "launch", name = "Debug script", program = "${file}" },
      }
    end,
  },
  notes = "bashdb wiring is best-effort and optional.",
}
