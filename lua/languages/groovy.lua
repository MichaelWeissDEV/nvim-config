---@type table
return {
  filetypes = { "groovy" },
  extensions = { ".groovy", ".gradle" },
  treesitter = { "groovy" },
  root_markers = { "build.gradle", "settings.gradle", "Jenkinsfile", ".git" },
  lsp = { tool = "groovyls" },
  formatters = { "npm_groovy_lint" },
  linters = { "npm_groovy_lint" },
}
