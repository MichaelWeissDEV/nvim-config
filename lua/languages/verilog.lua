---@type table
return {
  filetypes = { "verilog", "systemverilog" },
  extensions = { ".v", ".sv", ".svh", ".vh" },
  treesitter = { "systemverilog" },
  root_markers = { ".git" },
  lsp = { tool = "verible_ls" },
  formatters = { "verible" },
  linters = { "verilator" },
}
