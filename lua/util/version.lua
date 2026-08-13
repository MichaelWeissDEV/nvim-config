-- The Neovim version contract, in one place and deliberately testable.
--
-- 0.12.0 is a hard minimum, not a preference: this config vendors
-- nvim-treesitter's `main` branch, whose own README states it requires
-- Neovim 0.12+ (the frozen `master` branch is what supports 0.11). Rather
-- than migrate back to the legacy branch, the config requires 0.12.
--
-- The decision lives in `supports()`, a pure function over a version
-- table, so it can be tested against versions this machine isn't running
-- instead of only against whatever Neovim happens to be installed.
local M = {}

--- @class NvimVersion
--- @field major integer
--- @field minor integer
--- @field patch integer

M.MINIMUM = { major = 0, minor = 12, patch = 0 }

--- Format a version table as "x.y.z".
--- @param v NvimVersion
--- @return string
function M.tostring(v)
  return string.format("%d.%d.%d", v.major or 0, v.minor or 0, v.patch or 0)
end

--- Is `v` at least the minimum this config supports?
--- Pure: no globals, no vim API, so tests can pass arbitrary versions.
--- @param v NvimVersion|nil
--- @param minimum NvimVersion|nil defaults to M.MINIMUM
--- @return boolean
function M.supports(v, minimum)
  if type(v) ~= "table" then
    return false
  end
  local min = minimum or M.MINIMUM
  local have = { v.major or 0, v.minor or 0, v.patch or 0 }
  local want = { min.major or 0, min.minor or 0, min.patch or 0 }
  for i = 1, 3 do
    if have[i] > want[i] then
      return true
    end
    if have[i] < want[i] then
      return false
    end
  end
  return true -- exactly equal
end

--- The running Neovim's version.
--- @return NvimVersion
function M.current()
  return vim.version()
end

--- @return boolean
function M.current_is_supported()
  return M.supports(M.current())
end

--- The message shown when the running Neovim is too old. Shared by the
--- health check and the installers so the wording cannot drift.
--- @param v NvimVersion|nil defaults to the running version
--- @return string
function M.unsupported_message(v)
  return table.concat({
    "nvim-config requires Neovim >= " .. M.tostring(M.MINIMUM) .. ".",
    "Detected: " .. M.tostring(v or M.current()),
    "Please upgrade Neovim before continuing.",
  }, "\n")
end

return M
