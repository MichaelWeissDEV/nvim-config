---@type table
return {
  filetypes = { "java" },
  extensions = { ".java" },
  treesitter = { "java" },
  root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
  lsp = { tool = "jdtls" },
  formatters = { "google_java_format" },
  debugger = {
    tool = "java_debug",
    -- Placeholder: real wiring goes through jdtls's own DAP bridge, not a
    -- standalone adapter binary. lsp/dap/java.lua (Phase 6/7) replaces this.
    adapter = function()
      return {}
    end,
    configurations = function()
      return {}
    end,
  },
  notes = "jdtls needs a project-local workspace dir (a shared global one corrupts "
    .. "state across unrelated projects), computed as vim.fn.stdpath('cache') .. "
    .. "'/jdtls-workspace/' .. vim.fn.fnamemodify(root, ':t'); lsp/registry.lua "
    .. "currently merges lsp.extra directly into the vim.lsp.config() call, so that "
    .. "formula isn't encoded here as data -- it needs a jdtls-specific code path, "
    .. "left for lsp/dap/java.lua (Phase 6/7). Debugger is likewise driven through "
    .. "jdtls's own DAP integration rather than a standalone adapter; "
    .. "adapter()/configurations() are placeholders until then.",
}
