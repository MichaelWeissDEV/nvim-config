---@type table
return {
  filetypes = { "asciidoc" },
  extensions = { ".adoc", ".asciidoc" },
  root_markers = { ".git" },
  linters = { "vale" },
  notes = "Uses Vale for prose linting when installed.",
}
