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
    lualine_x = { "diagnostics", "encoding", "filetype" },
  },
})
