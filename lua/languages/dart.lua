---@type table
return {
  filetypes = { "dart" },
  extensions = { ".dart" },
  treesitter = { "dart" },
  root_markers = { "pubspec.yaml", ".git" },
  lsp = { tool = "dartls", extra = { cmd = { "dart", "language-server", "--protocol=lsp" } } },
  formatters = { "dart_format" },
  notes = "`dart language-server` and `dart format` ship with the Dart / Flutter SDK.",
}
