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
  # Version range kept in sync with pyproject.toml's [project.optional-dependencies].docs
  & $VenvPython -m pip install -q "sphinx>=8.0,<9" "myst-parser>=4.0,<5" "sphinx-rtd-theme>=3.0,<4"
}

Write-Host "==> Building Sphinx HTML (docs\_build\html)"
Push-Location docs
try {
  & $VenvPython -m sphinx -b html . _build\html -W
} finally {
  Pop-Location
}

Write-Host "==> Done: docs\_build\html\index.html"
