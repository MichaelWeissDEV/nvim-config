local augroup = vim.api.nvim_create_augroup

require("config.large_files").setup()

-- Neovim's builtin ftdetect maps .env files to filetype "sh"; our language
-- registry (lua/languages/dotenv.lua) targets "dotenv" so dotenv-linter
-- actually activates instead of silently never matching.
vim.filetype.add({
  filename = { [".env"] = "dotenv" },
  pattern = { ["%.env%.[%w_.-]+"] = "dotenv" },
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits", { clear = true }),
  command = "wincmd =",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "notify" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true, desc = "Close window" })
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("mkdir_on_save", { clear = true }),
  callback = function(args)
    local file = args.match
    if file:match("^%w+://") then
      return -- not a local path (e.g. oil://, fugitive://)
    end
    local dir = vim.fs.dirname(file)
    if dir and not (vim.uv.fs_stat(dir)) then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime", { clear = true }),
  command = "checktime",
})
