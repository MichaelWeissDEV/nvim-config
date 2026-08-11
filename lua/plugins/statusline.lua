require("lualine").setup({
  options = {
    theme = "catppuccin",
    component_separators = { left = "│", right = "│" },
    section_separators = { left = "", right = "" },
    globalstatus = true,
  },
  sections = {
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "encoding", "filetype" },
  },
})
