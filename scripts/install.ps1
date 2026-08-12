#Requires -Version 5.1
<#
.SYNOPSIS
  One-time, offline setup after cloning on Windows: generate :help tags and
  (if no Neovim config exists yet) link this repo into place as %LOCALAPPDATA%\nvim.
  Never touches the network. Safe to re-run.
#>
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
  Write-Error "nvim not found on PATH (need Neovim 0.11+, 0.12+ recommended)"
  exit 1
}

Write-Host "==> Generating :help tags"
# -u NONE: do not load any user config while generating tags.
& nvim --headless -u NONE -c "helptags $RepoRoot\doc" -c "qa"

$ConfigDir = Join-Path $env:LOCALAPPDATA "nvim"

if (Test-Path $ConfigDir) {
  $item = Get-Item $ConfigDir
  if ($item.LinkType -eq "SymbolicLink" -and $item.Target -eq $RepoRoot) {
    Write-Host "==> $ConfigDir already points here."
  } else {
    Write-Host "==> $ConfigDir already exists and is NOT this repo -- leaving it alone."
    Write-Host "    To use this config instead, move it aside and re-run this script, e.g.:"
    Write-Host "      Rename-Item `"$ConfigDir`" `"$ConfigDir.bak`""
  }
} else {
  New-Item -ItemType SymbolicLink -Path $ConfigDir -Target $RepoRoot | Out-Null
  Write-Host "==> Linked $ConfigDir -> $RepoRoot"
}

Write-Host "==> Done. Run 'nvim' to start, then :NvimConfigHealth to see what's missing,"
Write-Host "    and .\scripts\bootstrap.ps1 <profile> to install LSPs/formatters/linters/debuggers."
