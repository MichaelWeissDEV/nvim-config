-- Single source of truth for every user command this config defines. Same
-- rationale as keymap_registry: register once, get :NvimCommands, Telescope,
-- docs/_generated/commands.md and Sphinx for free.
local M = {}

--- @class CommandSpec
--- @field name string command name without leading colon, e.g. "ToolsStatus"
--- @field desc string
--- @field category string e.g. "Tools", "LSP", "Formatting", "Debugging"
--- @field args? string human-readable argument description, e.g. "[profile]"
--- @field example? string full example invocation
--- @field fn function|string
--- @field opts? table extra opts passed to nvim_create_user_command (nargs, complete, ...)

local entries = {}

--- @param spec CommandSpec
function M.command(spec)
  assert(spec.name, "command spec needs name")
  assert(spec.desc, "command spec for " .. tostring(spec.name) .. " needs desc")
  assert(spec.category, "command spec for " .. spec.name .. " needs category")

  local opts = vim.tbl_extend("force", { desc = spec.desc }, spec.opts or {})
  vim.api.nvim_create_user_command(spec.name, spec.fn, opts)

  table.insert(entries, {
    name = spec.name,
    desc = spec.desc,
    category = spec.category,
    args = spec.args,
    example = spec.example,
  })
end

--- Document a command owned by a vendored plugin (:Telescope, :TSInstall,
--- :Mason, :Gitsigns, ...) without redefining it -- redefining it would
--- shadow the plugin's real implementation.
--- @param spec CommandSpec
function M.external(spec)
  assert(spec.name, "command spec needs name")
  assert(spec.desc, "command spec for " .. tostring(spec.name) .. " needs desc")
  assert(spec.category, "command spec for " .. spec.name .. " needs category")
  table.insert(entries, {
    name = spec.name,
    desc = spec.desc,
    category = spec.category,
    args = spec.args,
    example = spec.example,
  })
end

--- @return table[] sorted by category then name
function M.all()
  local out = vim.deepcopy(entries)
  table.sort(out, function(a, b)
    if a.category ~= b.category then
      return a.category < b.category
    end
    return a.name < b.name
  end)
  return out
end

return M
