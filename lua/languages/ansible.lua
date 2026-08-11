---@type table
return {
  filetypes = { "yaml.ansible" },
  extensions = { ".yml", ".yaml" },
  treesitter = { "yaml" },
  root_markers = { "ansible.cfg", "site.yml", ".git" },
  lsp = { tool = "ansible_ls", extra = { cmd = { "ansible-language-server", "--stdio" } } },
  linters = { "ansible_lint" },
  notes = "Ansible detection is heuristic (see the vim.filetype.add() call in "
    .. "config/autocmds.lua): roles/*/tasks|handlers|meta paths, playbooks/ directories, "
    .. "and top-level site.yml/playbook.yml match; a lone task file with no such path "
    .. "context falls through to plain `yaml` (languages/yaml.lua) instead -- there's no "
    .. 'way to detect "this YAML is Ansible" from content alone in general.',
}
