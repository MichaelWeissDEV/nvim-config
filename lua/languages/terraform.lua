---@type table
return {
  filetypes = { "terraform", "terraform-vars" },
  extensions = { ".tf", ".tfvars" },
  treesitter = { "terraform", "hcl" },
  root_markers = { ".git" },
  -- terraform-ls requires the "serve" subcommand.
  lsp = { tool = "terraformls", extra = { cmd = { "terraform-ls", "serve" } } },
  formatters = { "terraform_fmt" },
  linters = { "tflint" },
  notes = "terraform fmt ships with the `terraform` CLI binary.",
}
