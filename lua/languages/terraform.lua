---@type table
return {
  filetypes = { "terraform", "terraform-vars" },
  extensions = { ".tf", ".tfvars" },
  treesitter = { "terraform" },
  root_markers = { ".git" },
  lsp = { tool = "terraformls" },
  linters = { "tflint" },
  notes = "terraform fmt is invoked as a formatter only if the `terraform` CLI itself is "
    .. "present; not modeled as a separate tools.registry entry since it ships with the "
    .. "terraform binary, not standalone.",
}
