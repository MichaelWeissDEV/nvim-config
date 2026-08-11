-- Detect large files / files with extremely long lines and drop expensive
-- per-buffer features so logs, CSV dumps and SQL exports still open at
-- normal speed instead of freezing the editor.
local M = {}

M.size_limit = 5 * 1024 * 1024 -- 5 MiB
M.line_length_limit = 20000

--- @param bufnr integer
--- @return boolean
function M.is_large(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end
  local ok, stat = pcall(vim.uv.fs_stat, name)
  if ok and stat and stat.size > M.size_limit then
    return true
  end
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count > 0 then
    -- Sample first/middle/last line lengths rather than scanning the whole
    -- buffer, which would itself be slow on a huge file.
    for _, lnum in ipairs({ 0, math.floor(line_count / 2), line_count - 1 }) do
      local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1]
      if line and #line > M.line_length_limit then
        return true
      end
    end
  end
  return false
end

--- @param bufnr integer
function M.apply(bufnr)
  vim.b[bufnr].large_file = true
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undofile = false
  vim.wo.foldmethod = "manual"
  vim.wo.spell = false

  vim.b[bufnr].ts_highlight_disabled = true
  pcall(vim.treesitter.stop, bufnr)

  vim.diagnostic.enable(false, { bufnr = bufnr })

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    vim.lsp.buf_detach_client(bufnr, client.id)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufReadPre" }, {
    group = vim.api.nvim_create_augroup("large_files", { clear = true }),
    callback = function(args)
      if M.is_large(args.buf) then
        M.apply(args.buf)
      end
    end,
  })
end

return M
