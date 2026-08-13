local cmdreg = require("util.command_registry")
local scratch = require("util.scratch")
local registry = require("lsp.registry")

require("lsp.attach").setup()
registry.setup()

-- Pick up servers installed during this session. registry.refresh() is
-- idempotent: vim.lsp.config() replaces a name's config rather than
-- accumulating, and vim.lsp.enable() on an already-enabled name is a
-- no-op, so nothing is duplicated and attached clients are not restarted.
-- Buffers opened afterwards get the newly available server; already-open
-- buffers still need :e or a restart, which is what {doc}`troubleshooting`
-- documents.
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
