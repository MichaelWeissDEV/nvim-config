---@type table
return {
  filetypes = { "solidity" },
  extensions = { ".sol" },
  treesitter = { "solidity" },
  root_markers = { "foundry.toml", "hardhat.config.js", "hardhat.config.ts", "truffle-config.js", "package.json", ".git" },
  lsp = { tool = "solidity_ls", extra = { cmd = { "nomicfoundation-solidity-language-server", "--stdio" } } },
  formatters = { "forge_fmt" },
  linters = { "solhint" },
}
