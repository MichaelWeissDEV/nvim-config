---@type table
return {
  filetypes = { "yaml.ansible" },
  extensions = { ".yml", ".yaml" },
  treesitter = { "yaml" },
  root_markers = { "ansible.cfg", "site.yml", ".git" },
  lsp = { tool = "ansible_ls" },
  linters = { "ansible_lint" },
  notes = "Ansible detection is heuristic: the filetype `yaml.ansible` must be set by a "
    .. "separate ftdetect pattern (e.g. playbooks/roles paths); plain `yaml` buffers "
    .. "never match this spec, so unpatterned playbooks fall through to languages/yaml.lua.",
}
