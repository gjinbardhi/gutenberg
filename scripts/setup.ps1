# scripts/setup.ps1  (v2 - robust quoting for Windows/PowerShell)
# Usage:
#   docker compose up -d --build
#   .\scripts\setup.ps1
# Then open: http://localhost:8080

[CmdletBinding()]
param(
  [string]$SiteUrl    = "http://localhost:8080",
  [string]$AdminUser  = "admin",
  [string]$AdminPass  = "admin",
  [string]$AdminEmail = "admin@example.com"
)

function Ensure-Ok($ExitCode, $Msg) {
  if ($ExitCode -ne 0) { throw $Msg }
}

Write-Host "→ Checking Docker CLI..." -ForegroundColor Cyan
docker version     | Out-Null; Ensure-Ok $LASTEXITCODE "Docker is not available."
docker compose version | Out-Null; Ensure-Ok $LASTEXITCODE "Docker Compose is not available."

Write-Host "Waiting for database (mysql) to be healthy..."
$attempts = 0
while ($true) {
  $json = docker compose ps --format json
  Ensure-Ok $LASTEXITCODE "docker compose ps failed"
  $list = $json | ConvertFrom-Json
  $db = $list | Where-Object { $_.Service -eq 'db' }
  $state = $db.Health
  if ($null -ne $state -and $state -eq 'healthy') { break }
  Start-Sleep -Seconds 2
  $attempts++
  if ($attempts -gt 180) { throw 'DB did not become healthy in time.' }
}

# -------- Bash script we will run inside the wpcli container --------
$BashScript = @'
set -euo pipefail

WP="wp --allow-root --path=/var/www/html"

echo "Checking if WordPress is installed…"
if ! $WP core is-installed >/dev/null 2>&1; then
  echo "Installing WordPress core…"
  $WP core install \
    --url="__SITE_URL__" \
    --title="Gutenberg GraphQL Demo" \
    --admin_user="__ADMIN_USER__" \
    --admin_password="__ADMIN_PASS__" \
    --admin_email="__ADMIN_EMAIL__"
else
  echo "WordPress already installed."
fi

# Ensure site/home URL are correct (important when switching ports)
$WP option update siteurl "__SITE_URL__"
$WP option update home "__SITE_URL__"

# Pretty permalinks
$WP rewrite structure "/%postname%/" --hard
$WP rewrite flush --hard

# Activate WPGraphQL (install if missing)
if ! $WP plugin is-installed wp-graphql >/dev/null 2>&1; then
  echo "Installing WPGraphQL…"
  $WP plugin install wp-graphql --activate
else
  $WP plugin activate wp-graphql
fi

# Activate our custom block plugin (will fail silently if not present)
$WP plugin activate latest-posts-grid || true

# Create a few demo posts if there are none
if [ "$($WP post list --post_type=post --field=ID | wc -l | tr -d ' ')" -eq "0" ]; then
  echo "Generating demo posts…"
  $WP post generate --count=6 --post_type=post >/dev/null
fi

# Create (or find) a Home page
home_id="$($WP post list --post_type=page --pagename=home --field=ID)"
if [ -z "$home_id" ]; then
  home_id="$($WP post create --post_type=page --post_status=publish --post_title='Home' --porcelain)"
fi

# Put the block on the Home page (uses /scripts/set-home.php)
php /scripts/set-home.php "$home_id" || true

# Set Home as the front page
$WP option update show_on_front 'page'
$WP option update page_on_front "$home_id"

echo "Done."
'@

# Inject params and normalize line endings
$BashScript = $BashScript.
  Replace("__SITE_URL__",   $SiteUrl).
  Replace("__ADMIN_USER__", $AdminUser).
  Replace("__ADMIN_PASS__", $AdminPass).
  Replace("__ADMIN_EMAIL__", $AdminEmail) -replace "`r`n","`n"

# Base64-encode to avoid PowerShell escaping issues
$bytes  = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "Running WordPress setup inside wpcli…" -ForegroundColor Cyan
# Decode inside container and run
docker compose run -T --rm wpcli bash -lc "set -e; echo $base64 | base64 -d > /tmp/run.sh && chmod +x /tmp/run.sh && bash /tmp/run.sh"
Ensure-Ok $LASTEXITCODE "wpcli script failed"

Write-Host ""
Write-Host "✅ Setup complete. Open: $SiteUrl" -ForegroundColor Green
