--- Names of the language servers attached to the current buffer, so it is
--- always visible whether ty/ruff/clangd/... is actually running here.
--- Empty when none is attached, which lualine renders as nothing.
local function lsp_clients()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    table.insert(names, client.name)
  end
  if #names == 0 then
    return ""
  end
  table.sort(names)
  return "\u{f0ad} " .. table.concat(names, ",") -- wrench, Font Awesome set
end

--- The virtualenv a Python buffer runs/tests/debugs with (util/python.lua),
--- by directory name -- e.g. ".venv" or "myproject-env". Looking it up
--- walks the filesystem, and lualine redraws often, so the answer is cached
--- per buffer for a few seconds (long enough to be free, short enough that
--- a freshly created .venv shows up without doing anything).
local env_cache = {} --- @type table<integer, { at: integer, text: string }>
local ENV_TTL_MS = 5000

local function python_env()
  if vim.bo.filetype ~= "python" then
    return ""
  end
  local buf = vim.api.nvim_get_current_buf()
  local now = vim.uv.now()
  local cached = env_cache[buf]
  if cached and now - cached.at < ENV_TTL_MS then
    return cached.text
  end
  local file = vim.api.nvim_buf_get_name(buf)
  local interpreter = require("util.python").interpreter(file ~= "" and file or nil)
  local text = ""
  if interpreter then
    -- <venv>/bin/python -> <venv>
    text = "(" .. vim.fs.basename(vim.fs.dirname(vim.fs.dirname(interpreter))) .. ")"
  end
  env_cache[buf] = { at = now, text = text }
  return text
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("nvim_config_statusline_env", { clear = true }),
  callback = function(args)
    env_cache[args.buf] = nil
  end,
})

require("lualine").setup({
  options = {
    -- catppuccin ships its lualine theme as "catppuccin-<flavour>", not
    -- plain "catppuccin" -- using the wrong name doesn't error, it just
    -- makes lualine silently fall back to "auto" and emit a one-time
    -- ":LualineNotices" warning at startup. Keep this in sync with the
    -- flavour set in plugins/theme.lua.
    theme = "catppuccin-mocha",
    component_separators = { left = "│", right = "│" },
    section_separators = { left = "", right = "" },
    globalstatus = true,
  },
  sections = {
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", lsp_clients, python_env, "encoding", "filetype" },
  },
})
