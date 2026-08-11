-- OS-specific *editor* settings. Raw OS facts live in util/platform.lua;
-- this module is the only place allowed to branch on them to change vim.opt.
local platform = require("util.platform")

if platform.is_windows then
  -- PowerShell as the internal shell gives sane :! and job-control behavior
  -- on Windows; only set it if the user hasn't already customized $SHELL-ish
  -- config (vim.o.shell defaults to cmd.exe otherwise).
  vim.o.shell = "powershell"
  vim.o.shellcmdflag =
    "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.o.shellredir = "-RedirectStandardOutput %s -NewWindow -Wait"
  vim.o.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

-- python3_host_prog / node_host_prog are intentionally left unset: pinning
-- them to a path would hardcode a machine-specific location. Providers are
-- optional and Neovim degrades silently (:checkhealth reports it) when a
-- host isn't found -- no plugin in this config depends on the Python or
-- Node RPC hosts.

return platform
