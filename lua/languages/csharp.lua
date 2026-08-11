---@type table
return {
  filetypes = { "cs" },
  extensions = { ".cs" },
  treesitter = { "c_sharp" },
  root_markers = { ".sln", ".csproj", ".git" },
  -- OmniSharp needs an explicit flag to speak the LSP protocol over stdio
  -- (its default is its own older HTTP/stdio protocol).
  lsp = { tool = "omnisharp", extra = { cmd = { "OmniSharp", "--languageserver" } } },
  formatters = { "dotnet_format" },
  debugger = {
    tool = "netcoredbg",
    adapter = function()
      return { type = "executable", command = "netcoredbg", args = { "--interpreter=vscode" } }
    end,
    configurations = function()
      return {
        {
          type = "netcoredbg",
          request = "launch",
          name = "Launch",
          program = function()
            return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
          end,
        },
      }
    end,
  },
  notes = "root_markers here are literal names, not globs (`.sln`/`.csproj` match a file "
    .. "with exactly that name); vim.fs.find has no glob support, so project-root "
    .. "detection is approximate until a glob-aware root_markers mechanism exists.",
}
