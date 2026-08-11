-- Thin shim so `:checkhealth nvim-config` finds us: Neovim's :checkhealth
-- looks for a module named "<name>.health" with a check() function. The
-- actual implementation lives in config/health.lua alongside the rest of
-- config/*.lua.
return require("config.health")
