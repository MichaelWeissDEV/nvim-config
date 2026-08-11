---@type table
return {
  filetypes = { "terraform", "terraform-vars" },
  extensions = { ".tf", ".tfvars" },
  treesitter = { "terraform" },
  root_markers = { ".git" },
  -- terraform-ls requires the "serve" subcommand.
  lsp = { tool = "terraformls", extra = { cmd = { "terraform-ls", "serve" } } },
  linters = { "tflint" },
  notes = "terraform fmt is invoked as a formatter only if the `terraform` CLI itself is "
    .. "present; not modeled as a separate tools.registry entry since it ships with the "
    .. "terraform binary, not standalone.",
}
