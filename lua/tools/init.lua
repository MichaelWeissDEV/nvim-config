-- Registers :ToolsStatus / :ToolsInstall / :ToolsUpdate. Pulled in from
-- init.lua so tool commands exist even before any language buffer is
-- opened (relevant for a fresh `git clone && nvim` where the first thing
-- a user reasonably does is check what's missing).
require("tools.status")
require("tools.install")
