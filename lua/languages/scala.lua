---@type table
return {
  filetypes = { "scala", "sbt" },
  extensions = { ".scala", ".sc", ".sbt" },
  treesitter = { "scala" },
  root_markers = { "build.sbt", "build.sc", "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
  lsp = { tool = "metals" },
  formatters = { "scalafmt" },
  notes = "Metals and scalafmt are typically installed via Coursier (`cs install metals scalafmt`).",
}
