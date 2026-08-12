#Requires -Version 5.1
<#
.SYNOPSIS
  Regenerate the registry-derived docs, then build the full local Sphinx
  site, on Windows. Mirrors scripts/docs-build.sh.
#>
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

Write-Host "==> Regenerating docs/_generated/*.md and doc/nvim-config.txt from the registries"
& nvim --headless -u init.lua -l scripts/generate-docs.lua

Write-Host "==> Refreshing :help tags"
& nvim --headless -c "helptags $RepoRoot\doc" -c "qa"

$VenvPython = "docs\.venv\Scripts\python.exe"
if (-not (Test-Path $VenvPython)) {
  Write-Host "==> Creating docs\.venv and installing Sphinx (one-time, needs network)"
  python -m venv docs\.venv
  & $VenvPython -m pip install -q --upgrade pip
  & $VenvPython -m pip install -q -r docs\requirements.txt
}

Write-Host "==> Building Sphinx HTML (docs\_build\html)"
Push-Location docs
try {
  & $VenvPython -m sphinx -b html . _build\html -W
} finally {
  Pop-Location
}

Write-Host "==> Done: docs\_build\html\index.html"
