# scripts/bootstrap.ps1  — clean, compatible, no fragile quoting
# Runs Docker Compose and setup scripts in order, auto-detecting filenames.
# Usage:
#   .\scripts\bootstrap.ps1
#   .\scripts\bootstrap.ps1 -SeedCount 24
#   .\scripts\bootstrap.ps1 -Reset
#   .\scripts\bootstrap.ps1 -SiteUrl "http://localhost:8080" -AdminUser admin -AdminPass admin -AdminEmail admin@example.com -SeedCount 16
#   .\scripts\bootstrap.ps1 -SkipBackfill
#
# Expects (in scripts/):
#   setup.ps1  OR setup.v2.ps1      (required)
#   fix-home.ps1                    (required)
#   seed-posts.ps1 OR seed-posts.v2.ps1   (optional)
#   backfill.sh                     (optional; used unless -SkipBackfill)
#
# What it does:
#   1) (Optional) docker compose down -v when -Reset is passed
#   2) docker compose up -d --build
#   3) Run setup script (installs WP, sets URLs, activates WPGraphQL & your block)
#   4) Run fix-home.ps1 (inserts your block on 'Home' and sets it as the front page)
#   5) Seed demo posts if a seeding script exists and -SeedCount > 0
#   6) Backfill missing featured images by running /scripts/backfill.sh inside wpcli

[CmdletBinding()]
param(
  [string]$SiteUrl    = "http://localhost:8080",
  [string]$AdminUser  = "admin",
  [string]$AdminPass  = "admin",
  [string]$AdminEmail = "admin@example.com",
  [int]$SeedCount     = 12,
  [switch]$Reset,
  [switch]$SkipBackfill
)

$ErrorActionPreference = "Stop"

function Exec([string]$cmd, [string]$errMsg = "Command failed") {
  Write-Host "→ $cmd" -ForegroundColor Cyan
  $p = Start-Process powershell -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-Command",$cmd -NoNewWindow -PassThru -Wait
  if ($p.ExitCode -ne 0) { throw "$errMsg ($($p.ExitCode))`n$cmd" }
}

Write-Host "=== Gutenberg GraphQL Demo Bootstrap ===" -ForegroundColor Green

# Check prerequisites
docker version | Out-Null
docker compose version | Out-Null

# Resolve paths
$RepoRoot  = Get-Location
$ScriptsDir = Join-Path $RepoRoot "scripts"

# Detect setup script
$SetupPath = @("setup.ps1","setup.v2.ps1") | ForEach-Object { Join-Path $ScriptsDir $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $SetupPath) { throw "setup.ps1 (or setup.v2.ps1) not found in $ScriptsDir" }

# fix-home is required
$FixHomePath = Join-Path $ScriptsDir "fix-home.ps1"
if (-not (Test-Path $FixHomePath)) { throw "fix-home.ps1 not found in $ScriptsDir" }

# Seeding script is optional
$SeedPath = @("seed-posts.v2.ps1","seed-posts.ps1") | ForEach-Object { Join-Path $ScriptsDir $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1

# Backfill script is optional (used unless -SkipBackfill)
$BackfillPath = Join-Path $ScriptsDir "backfill.sh"

if ($Reset) {
  Write-Host "Reset requested: tearing down containers & volumes..." -ForegroundColor Yellow
  Exec "docker compose down -v" "docker compose down failed"
}

Write-Host "Starting containers (docker compose up -d --build)..." -ForegroundColor Green
Exec "docker compose up -d --build" "docker compose up failed"

Write-Host "Running $([System.IO.Path]::GetFileName($SetupPath))..." -ForegroundColor Green
& $SetupPath -SiteUrl $SiteUrl -AdminUser $AdminUser -AdminPass $AdminPass -AdminEmail $AdminEmail

Write-Host "Running fix-home.ps1..." -ForegroundColor Green
& $FixHomePath

if ($SeedCount -gt 0 -and $SeedPath) {
  Write-Host "Seeding $SeedCount posts using $([System.IO.Path]::GetFileName($SeedPath))..." -ForegroundColor Green
  & $SeedPath -Count $SeedCount
} elseif ($SeedCount -gt 0) {
  Write-Host "Warning: no seed-posts script found; skipping seeding." -ForegroundColor Yellow
}

if (-not $SkipBackfill) {
  if (Test-Path $BackfillPath) {
    Write-Host "Backfilling missing featured images..." -ForegroundColor Green
    # No fragile '&&' chains; just run the script inside the container
    Exec "docker compose run -T --rm wpcli bash -lc 'bash /scripts/backfill.sh'" "Backfill failed"
  } else {
    Write-Host "Note: backfill.sh not found; skipping image backfill." -ForegroundColor Yellow
  }
}

Write-Host ""
Write-Host "✅ All done. Open: $SiteUrl" -ForegroundColor Green

try { Start-Process $SiteUrl | Out-Null } catch { Write-Host "Open $SiteUrl in your browser." -ForegroundColor Yellow }
