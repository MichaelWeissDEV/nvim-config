-- IDE workflows built on top of the registries: per-language tooling
-- (:LangInstall / :LangInfo), Python commands, running files, a terminal,
-- and everyday editing keymaps. Everything here is loaded at startup but
-- does no work until a key or command is used -- no plugin is loaded, no
-- tool is probed and nothing touches the network.
require("ide.keymaps")
require("ide.lang")
require("ide.python")
require("ide.run")
require("ide.terminal")
