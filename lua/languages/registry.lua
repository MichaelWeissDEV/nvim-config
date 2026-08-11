-- The central language registry. Every per-language file under
-- lua/languages/*.lua (except this one and init.lua) returns exactly one
-- LanguageSpec table; this module discovers, validates and indexes them.
--
-- Nothing in this file talks to LSP clients, conform, nvim-lint or DAP
-- directly -- lsp/init.lua, plugins/formatting.lua, plugins/linting.lua and
-- dap/registry.lua each read this registry and drive their own plugin.
-- That keeps "which language has which tool" in exactly one place.
--
-- @class LanguageSpec
--   id            string                unique id, matches the filename
--   filetypes     string[]              vim filetypes this spec applies to
--   extensions    string[]?             file extensions, documentation only
--   treesitter    string[]?             nvim-treesitter parser names
--   root_markers  string[]?             files/dirs that mark a project root
--   lsp           { tool: string, settings: table?, extra: table? }?
--   extra_lsp     { tool: string, settings: table?, extra: table? }[]?
--                 additional LSP clients attached alongside `lsp` for the same
--                 filetypes/root_markers (Neovim allows multiple clients per
--                 buffer natively). Use sparingly -- two servers both producing
--                 diagnostics/completions for the same buffer can be noisy;
--                 this exists for cases like Python's "ty" (a fast supplementary
--                 type checker most people run next to, not instead of, their
--                 main LSP), not as the default way to add a language server.
--   formatters    string[]?             tool ids from tools.registry, in order
--   linters       string[]?             tool ids from tools.registry
--   debugger      { tool: string, adapter: fun():table, configurations: fun():table[] }?
--   indent        { shiftwidth: integer, expandtab: boolean? }?  documentation;
--                 applied for real via after/ftplugin/<filetype>.lua
--   keymaps       fun(bufnr: integer)?  buffer-local, filetype-scoped keymaps
--   notes         string?

local LANGUAGE_IDS = {
  "lua",
  "python",
  "ruby",
  "go",
  "rust",
  "c",
  "cpp",
  "java",
  "kotlin",
  "bash",
  "fish",
  "powershell",
  "asm",
  "javascript",
  "typescript",
  "html",
  "css", -- also handles scss/sass/less
  "vue",
  "svelte",
  "json",
  "yaml",
  "toml",
  "xml",
  "sql",
  "csv",
  "dotenv",
  "ini",
  "dockerfile",
  "terraform",
  "nix",
  "ansible",
  "markdown",
  "rst",
  "latex",
  "asciidoc",
  "csharp",
  "fsharp",
  "haskell",
  "ocaml",
  "elixir",
  "erlang",
  "php",
  "perl",
  "zig",
  "cmake",
  "make",
  "graphql",
  "proto",
}

local M = {}

local by_id = {}
local by_filetype = {}

local function validate(id, spec)
  assert(type(spec) == "table", id .. ": language spec must return a table")
  assert(type(spec.filetypes) == "table" and #spec.filetypes > 0, id .. ": filetypes required")
  if spec.lsp then
    assert(spec.lsp.tool, id .. ": lsp.tool required when lsp is set")
  end
  if spec.extra_lsp then
    for i, lsp_spec in ipairs(spec.extra_lsp) do
      assert(lsp_spec.tool, id .. ": extra_lsp[" .. i .. "].tool required")
    end
  end
  if spec.debugger then
    assert(spec.debugger.tool, id .. ": debugger.tool required when debugger is set")
  end
end

local function load_all()
  if next(by_id) ~= nil then
    return -- already loaded
  end
  for _, id in ipairs(LANGUAGE_IDS) do
    local ok, spec = pcall(require, "languages." .. id)
    if not ok then
      require("util.notify").config_error("languages." .. id, tostring(spec))
    else
      validate(id, spec)
      spec.id = id
      by_id[id] = spec
      for _, ft in ipairs(spec.filetypes) do
        by_filetype[ft] = spec
      end
    end
  end
end

--- @return LanguageSpec[]
function M.all()
  load_all()
  local out = {}
  for _, id in ipairs(LANGUAGE_IDS) do
    if by_id[id] then
      table.insert(out, by_id[id])
    end
  end
  return out
end

--- @param id string
--- @return LanguageSpec|nil
function M.get(id)
  load_all()
  return by_id[id]
end

--- @param filetype string
--- @return LanguageSpec|nil
function M.by_filetype(filetype)
  load_all()
  return by_filetype[filetype]
end

M.ids = LANGUAGE_IDS

return M
