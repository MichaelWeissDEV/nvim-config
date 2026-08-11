-- Single source of truth for every keymap this config defines. Call
-- registry.map() instead of vim.keymap.set() directly and the mapping is
-- simultaneously: applied, shown by which-key, listed by :NvimKeymaps and
-- Telescope, and exported to KEYMAPS.md / Sphinx by scripts/docs-build.
--
-- Buffer-local mappings (LSP, DAP-attach-only, filetype-specific) are still
-- recorded once as a *template* entry (buffer = "context") the first time
-- they're registered, so they show up in docs without one row per buffer.
local M = {}

--- @class KeymapSpec
--- @field mode string|string[]
--- @field lhs string
--- @field rhs string|function
--- @field desc string
--- @field group string short group name, e.g. "LSP", "Search", "Debug"
--- @field context? string when this mapping is active, e.g. "LSP attached", "Global"
--- @field buffer? integer|boolean pass through to vim.keymap.set opts.buffer
--- @field remap? boolean

local entries = {}
local seen_templates = {}

--- @param spec KeymapSpec
function M.map(spec)
  assert(spec.lhs, "keymap spec needs lhs")
  assert(spec.rhs, "keymap spec needs rhs")
  assert(spec.desc, "keymap spec for " .. spec.lhs .. " needs desc")
  assert(spec.group, "keymap spec for " .. spec.lhs .. " needs group")

  local opts = {
    desc = spec.desc,
    silent = spec.silent ~= false,
    remap = spec.remap or false,
  }
  if spec.buffer ~= nil then
    opts.buffer = spec.buffer
  end

  vim.keymap.set(spec.mode, spec.lhs, spec.rhs, opts)

  -- Dedupe buffer-local templates: record "gd -> LSP Definition" once, not
  -- once per buffer the LSP attaches to.
  local template_key = table.concat({
    type(spec.mode) == "table" and table.concat(spec.mode, ",") or spec.mode,
    spec.lhs,
    spec.context or "Global",
  }, "\0")

  if spec.buffer ~= nil then
    if seen_templates[template_key] then
      return
    end
    seen_templates[template_key] = true
  end

  table.insert(entries, {
    mode = spec.mode,
    lhs = spec.lhs,
    desc = spec.desc,
    group = spec.group,
    context = spec.context or "Global",
  })
end

--- Document a mapping that was already applied elsewhere (e.g. by
--- config.lazyload.on_key, which sets the real vim.keymap.set call itself
--- so it can delete/replace the stub on load). Records metadata only.
--- @param spec KeymapSpec
function M.document(spec)
  table.insert(entries, {
    mode = spec.mode,
    lhs = spec.lhs,
    desc = spec.desc,
    group = spec.group,
    context = spec.context or "Global",
  })
end

--- Register several mappings that share mode/group/context.
--- @param specs KeymapSpec[]
function M.map_many(specs)
  for _, spec in ipairs(specs) do
    M.map(spec)
  end
end

--- @return table[] sorted by group then lhs
function M.all()
  local out = vim.deepcopy(entries)
  table.sort(out, function(a, b)
    if a.group ~= b.group then
      return a.group < b.group
    end
    return a.lhs < b.lhs
  end)
  return out
end

return M
