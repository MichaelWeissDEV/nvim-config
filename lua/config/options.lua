local platform = require("util.platform")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitbelow = true
opt.splitright = true
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.pumheight = 12
opt.cmdheight = 1
opt.laststatus = 3
opt.winborder = "rounded"

-- Editing
opt.mouse = "a"
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"
opt.completeopt = { "menu", "menuone", "noselect", "popup" }
opt.virtualedit = "block"

-- Files / persistence
opt.undofile = true
opt.undodir = vim.fs.joinpath(platform.state_dir, "undo")
opt.swapfile = false
opt.autoread = true
opt.confirm = true
opt.backup = false
opt.writebackup = false

-- Clipboard: Neovim only probes for a provider (pbcopy/xclip/wl-copy/
-- win32yank) lazily on first yank/paste to the unnamed register, so setting
-- this unconditionally never produces a startup warning when one is missing.
opt.clipboard = "unnamedplus"

-- Performance
opt.updatetime = 250
opt.timeoutlen = 400
opt.redrawtime = 1500

-- Windows-specific shell handling lives in config/platform.lua.
