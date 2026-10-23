---@type table
return {
  filetypes = { "gdscript" },
  extensions = { ".gd" },
  treesitter = { "gdscript", "godot_resource", "gdshader" },
  root_markers = { "project.godot", ".git" },
  formatters = { "gdformat" },
  linters = { "gdlint" },
  notes = "Godot's built-in LSP runs inside the running Godot editor over TCP (port 6005); "
    .. "formatting and linting work standalone via gdtoolkit.",
}
