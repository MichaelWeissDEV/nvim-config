#Requires -Version 5.1
<#
.SYNOPSIS
  One-time, offline setup after cloning on Windows: verify the Neovim
  version, generate :help tags, and link this repo in as your Neovim
  config. Never touches the network. Safe to re-run.

.DESCRIPTION
  An existing Neovim configuration is NEVER deleted or overwritten.
  Without -Backup the script refuses and explains what to do; with
  -Backup it renames the existing configuration to a timestamped
  directory beside it first. Same destruction-free philosophy as
  scripts/install.sh on POSIX.

  Neovim's data and state directories are never touched in either mode.

.PARAMETER Backup
  Rename an existing configuration to <ConfigDir>.backup-yyyyMMdd-HHmmss
  instead of refusing.

.EXAMPLE
  .\scripts\install.ps1

.EXAMPLE
  .\scripts\install.ps1 -Backup
#>
param(
  [switch]$Backup
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
  Write-Error "nvim not found on PATH (nvim-config requires Neovim >= 0.12.0)"
  exit 1
}

# Let Neovim evaluate its own version against the single contract in
# lua/util/version.lua rather than parsing `nvim --version` text here.
& nvim --headless -u NONE --cmd "set runtimepath^=$RepoRoot" `
  -c 'lua local v = require("util.version") if v.current_is_supported() then vim.cmd("qa") else io.stderr:write(v.unsupported_message() .. "\n") vim.cmd("cquit 1") end'
if ($LASTEXITCODE -ne 0) {
  exit 1
}

Write-Host "==> Generating :help tags"
# -u NONE: do not load any user config while generating tags.
& nvim --headless -u NONE -c "helptags $RepoRoot\doc" -c "qa"

$ConfigDir = Join-Path $env:LOCALAPPDATA "nvim"

function Install-Link {
  # A symbolic link needs Developer Mode or an elevated shell on Windows;
  # a directory junction needs neither and behaves identically for this
  # purpose, so fall back to it rather than failing the whole install.
  try {
    New-Item -ItemType SymbolicLink -Path $ConfigDir -Target $RepoRoot -ErrorAction Stop | Out-Null
    Write-Host "==> Linked $ConfigDir -> $RepoRoot (symlink)"
  } catch {
    Write-Host "==> Symbolic link refused (needs Developer Mode or an elevated shell); using a junction instead."
    New-Item -ItemType Junction -Path $ConfigDir -Target $RepoRoot | Out-Null
    Write-Host "==> Linked $ConfigDir -> $RepoRoot (junction)"
  }
}

if (Test-Path -LiteralPath $ConfigDir) {
  $item = Get-Item -LiteralPath $ConfigDir -Force

  # Covers a plain directory, a symlink and a junction: both reparse-point
  # kinds expose LinkType/Target, a plain directory leaves LinkType empty.
  $existingTarget = $null
  if ($item.LinkType) {
    $existingTarget = @($item.Target)[0]
  }

  $pointsHere = $false
  if ($existingTarget) {
    try {
      $pointsHere = (Resolve-Path -LiteralPath $existingTarget).Path -eq (Resolve-Path -LiteralPath $RepoRoot).Path
    } catch {
      $pointsHere = $false # dangling link: treat as foreign, never delete
    }
  }

  if ($pointsHere) {
    Write-Host "==> $ConfigDir already points here, nothing to do."
  } elseif ($Backup) {
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupLeaf = "nvim.backup-$stamp"
    $backupPath = Join-Path (Split-Path -Parent $ConfigDir) $backupLeaf
    if (Test-Path -LiteralPath $backupPath) {
      Write-Error "Backup target already exists: $backupPath -- refusing to overwrite it."
      exit 1
    }
    # Rename-Item on a reparse point moves the link itself, not the
    # directory it points at, so an existing symlink/junction is relinked
    # rather than its target being copied or destroyed.
    Rename-Item -LiteralPath $ConfigDir -NewName $backupLeaf -ErrorAction Stop
    Write-Host "==> Moved existing configuration to $backupPath"
    Install-Link
  } else {
    Write-Host ""
    Write-Host "Existing Neovim configuration found:"
    Write-Host "  $ConfigDir"
    Write-Host ""
    Write-Host "Refusing to overwrite it."
    Write-Host ""
    Write-Host "Either move it away yourself:"
    Write-Host "  Rename-Item `"$ConfigDir`" `"nvim.backup`""
    Write-Host ""
    Write-Host "or re-run with -Backup to have this script move it for you:"
    Write-Host "  .\scripts\install.ps1 -Backup"
    Write-Host ""
    Write-Host "Your Neovim data and state directories are never touched by this"
    Write-Host "script; for a completely clean slate also move this aside:"
    Write-Host "  $env:LOCALAPPDATA\nvim-data"
    exit 1
  }
} else {
  $parent = Split-Path -Parent $ConfigDir
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }
  Install-Link
}

Write-Host "==> Done. Run 'nvim' to start, then :NvimConfigHealth to see what's missing,"
Write-Host "    and .\scripts\bootstrap.ps1 <profile> to install LSPs/formatters/linters/debuggers."
