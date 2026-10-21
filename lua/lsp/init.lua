local cmdreg = require("util.command_registry")
local scratch = require("util.scratch")
local registry = require("lsp.registry")

require("lsp.attach").setup()
registry.setup()

-- Pick up servers installed during this session. registry.refresh() is
-- idempotent: vim.lsp.config() replaces a name's config rather than
-- accumulating, and re-enabling an attached server reuses its client, so
-- nothing is duplicated. Since Neovim 0.12, vim.lsp.enable() also re-runs
-- its FileType hook over every open buffer, so a server installed (or
-- switched on with :PythonLsp) attaches to already-open buffers as well --
-- no :e needed. Verified by tests/test_python_stack.lua.
require("tools.refresh").on_tools_changed("lsp", function()
  registry.refresh()
end)

cmdreg.command({
  name = "LspStatus",
  desc = "Show configured LSP servers (installed) and clients attached to the current buffer",
  category = "LSP",
  example = ":LspStatus",
  fn = function()
    local lines = { "# LSP Status", "", "## Configured servers (binary found on PATH)", "" }
    for _, s in ipairs(registry.configured()) do
      table.insert(lines, string.format("- %s -- %s", s.name, table.concat(s.filetypes, ", ")))
    end
    table.insert(lines, "")
    table.insert(lines, "## Clients attached to current buffer")
    table.insert(lines, "")
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      table.insert(lines, "- (none)")
    else
      for _, c in ipairs(clients) do
        table.insert(lines, string.format("- %s (id=%d, root=%s)", c.name, c.id, c.root_dir or "?"))
      end
    end
    scratch.open("nvim-config://lsp-status", lines)
  end,
})
