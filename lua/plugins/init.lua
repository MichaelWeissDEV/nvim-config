-- Requires every plugins/*.lua module. Files for `start` plugins configure
-- them immediately (safe: start packages are already on &runtimepath by
-- the time init.lua runs, even though their own plugin/ scripts haven't
-- sourced yet -- see comment in lsp/registry.lua for why that distinction
-- matters). Files for `opt` plugins only register a lazy-load trigger here;
-- the actual packadd + setup happens on first use.
require("plugins.core")
require("plugins.theme")
require("plugins.treesitter")
require("plugins.completion")
require("plugins.mason")
require("plugins.formatting")
require("plugins.linting")
require("plugins.git")
require("plugins.statusline")
require("plugins.whichkey")
require("plugins.editing")

require("plugins.telescope")
require("plugins.tree")
require("plugins.files")
require("plugins.diagnostics")
require("plugins.markdown")
require("plugins.latex")
require("plugins.csv")
