#requires -Version 5.1
<#
.SYNOPSIS
  Project setup script: creates a .env file (if missing) and loads it into env vars.
  Optional: install deps (npm/composer).

.PARAMETER Force
  Overwrite an existing .env with default values.

.PARAMETER Persist
  Also write variables to the current user's persistent environment.

.EXAMPLES
  .\scripts\setup.ps1
  .\scripts\setup.ps1 -Force
  .\scripts\setup.ps1 -Persist
  .\scripts\setup.ps1 -Force -Persist
#>

[CmdletBinding()]
param(
  [switch]$Force,
  [switch]$Persist
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Move to repo root (folder containing this script's parent)
$scriptPath = $MyInvocation.MyCommand.Path
$repoRoot   = Split-Path -Parent $scriptPath | Split-Path -Parent
Set-Location $repoRoot

$envFile = Join-Path $repoRoot '.env'

# Default .env content — edit to your needs
$defaultEnv = @"
# auto-created by setup.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# Lines beginning with # are ignored.

APP_ENV=development

# WordPress / App (adjust as needed)
WP_URL=http://localhost:8888
WP_HOME=http://localhost:8888

# Database (adjust as needed)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=wordpress
DB_USER=wp
DB_PASSWORD=wp

# Build
NODE_ENV=development
"@

function New-Or-Overwrite-DotEnv {
  param([string]$Path, [string]$Content, [switch]$Overwrite)

  if ((Test-Path $Path) -and -not $Overwrite) {
    Write-Host ".env already exists at $Path (use -Force to overwrite)."
    return
  }

  $Content | Set-Content -Path $Path -Encoding UTF8
  Write-Host "Created .env with dev defaults at $Path"
}

function Load-DotEnv {
  [OutputType([hashtable])]
  param([string]$Path)

  if (-not (Test-Path $Path)) {
    throw ".env not found at $Path"
  }

  $pairs = @{}
  foreach ($line in [System.IO.File]::ReadLines($Path)) {
    # Skip comments/blank lines
    if ($line -match '^\s*#' -or $line.Trim() -eq '') { continue }

    # KEY=VALUE (VALUE may contain spaces). Keep simple/robust.
    $m = [regex]::Match($line, '^\s*([^=\s#][^=]*)\s*=\s*(.*)\s*$')
    if (-not $m.Success) { continue }

    $key = $m.Groups[1].Value.Trim()
    $val = $m.Groups[2].Value.Trim()

    # Strip surrounding quotes if present
    if (($val.StartsWith('"') -and $val.EndsWith('"')) -or
        ($val.StartsWith("'") -and $val.EndsWith("'"))) {
      $val = $val.Substring(1, $val.Length - 2)
    }

    # Set for current session
    Set-Item -Path ("Env:{0}" -f $key) -Value $val
    $pairs[$key] = $val

    # Optionally persist for future sessions
    if ($Persist) {
      [Environment]::SetEnvironmentVariable($key, $val, 'User')
    }
  }

  return $pairs
}

# 1) Create/overwrite .env if needed
New-Or-Overwrite-DotEnv -Path $envFile -Content $defaultEnv -Overwrite:$Force

# 2) Load .env into environment
$loaded = Load-DotEnv -Path $envFile
Write-Host ("Loaded {0} variable(s) into current session." -f $loaded.Keys.Count)

# 3) Optional: install dependencies if manifests are present
if (Test-Path (Join-Path $repoRoot 'package.json')) {
  Write-Host "Detected package.json — installing Node dependencies..."
  if (Test-Path (Join-Path $repoRoot 'package-lock.json')) {
    npm ci
  } else {
    npm install
  }
}

if (Test-Path (Join-Path $repoRoot 'composer.json')) {
  if (Get-Command composer -ErrorAction SilentlyContinue) {
    Write-Host "Detected composer.json — installing PHP dependencies..."
    composer install
  } else {
    Write-Warning "Composer not found on PATH — skipping PHP deps."
  }
}

Write-Host "Setup complete."
