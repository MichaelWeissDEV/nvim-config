---@type table
return {
  filetypes = { "ps1" },
  extensions = { ".ps1", ".psm1", ".psd1" },
  treesitter = { "powershell" },
  root_markers = { ".git" },
  lsp = {
    tool = "powershell_es",
    extra = { cmd = { "pwsh", "-NoLogo", "-NoProfile", "-Command", "PowerShellEditorServices.Start.ps1" } },
  },
  notes = "PSScriptAnalyzer runs through the LSP's own diagnostics, not nvim-lint; "
    .. "the launch cmd is best-effort and may need adjusting to Mason's bundled bootstrap script path.",
}
