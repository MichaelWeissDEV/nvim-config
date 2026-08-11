-- Small always-on dependencies. plenary.nvim is a library other start
-- plugins (telescope) require() at load time; nvim-web-devicons is used by
-- lualine/telescope/oil for filetype icons. Neither needs packadd -- both
-- live in pack/vendor/start and Neovim sources them automatically.
require("nvim-web-devicons").setup({})
