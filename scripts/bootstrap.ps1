#Requires -Version 5.1
<#
.SYNOPSIS
  Install a tool profile (LSPs/formatters/linters/debuggers via Mason, plus
  a default Tree-sitter parser set) on Windows. Mirrors scripts/bootstrap.sh.
.EXAMPLE
  .\scripts\bootstrap.ps1 core
.EXAMPLE
  .\scripts\bootstrap.ps1 systems
#>
param(
  [Parameter(Position = 0)]
  [string]$Profile
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not $Profile) {
  Write-Host "Usage: .\scripts\bootstrap.ps1 <profile>"
  Write-Host "Profiles: core systems python scripting web jvm dotnet functional devops docs all"
  exit 1
}

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
  Write-Error "nvim not found on PATH"
  exit 1
}

Write-Host "==> Bootstrapping tool profile '$Profile' (this needs network access)"
& nvim --headless -u "$RepoRoot\init.lua" -l "$RepoRoot\scripts\bootstrap.lua" $Profile
exit $LASTEXITCODE
