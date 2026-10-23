local bash = require("languages.bash")

---@type table
return {
  filetypes = { "zsh" },
  extensions = { ".zsh", ".zshrc", ".zshenv" },
  treesitter = { "zsh" },
  root_markers = bash.root_markers,
  lsp = bash.lsp,
  formatters = { "shfmt" },
  linters = { "zsh" },
  notes = "Shares bash-language-server and shfmt with bash; syntax-checked via `zsh -n`.",
}
