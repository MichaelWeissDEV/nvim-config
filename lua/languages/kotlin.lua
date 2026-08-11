---@type table
return {
  filetypes = { "kotlin" },
  extensions = { ".kt", ".kts" },
  treesitter = { "kotlin" },
  root_markers = { "build.gradle.kts", "settings.gradle.kts", "pom.xml", ".git" },
  lsp = { tool = "kotlin_language_server" },
  formatters = { "ktlint" },
  linters = { "ktlint" },
  notes = 'ktlint is registered in tools.registry with category = "formatter" only; '
    .. "it's reused here as a linter too since it's the same binary in --check mode, "
    .. "and consumers key off lang.formatters/lang.linters, not the tool's category.",
}
