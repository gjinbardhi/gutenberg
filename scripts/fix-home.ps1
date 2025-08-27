# scripts/fix-home.ps1
# Ensures the Home page contains your custom grid block and is set as the static front page.
# Usage:
#   .\scripts\fix-home.ps1

function Ensure-Ok($ExitCode, $Msg) {
  if ($ExitCode -ne 0) { throw $Msg }
}

Write-Host "→ Checking Docker CLI..." -ForegroundColor Cyan
docker version | Out-Null; Ensure-Ok $LASTEXITCODE "Docker is not available."
docker compose version | Out-Null; Ensure-Ok $LASTEXITCODE "Docker Compose is not available."

$BashScript = @'
set -euo pipefail
WP="wp --allow-root --path=/var/www/html"

# Find/create Home page
home_id="$($WP post list --post_type=page --pagename=home --field=ID)"
if [ -z "$home_id" ]; then
  home_id="$($WP post create --post_type=page --post_status=publish --post_title='Home' --porcelain)"
fi

# Insert the block using our helper (auto-detects slug)
php /scripts/set-home.php "$home_id" || true

# Make it the front page
$WP option update show_on_front 'page'
$WP option update page_on_front "$home_id"

echo "Front page set to Home (ID=$home_id) and block inserted."
'@

$BashScript = $BashScript -replace "`r`n","`n"
$bytes  = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "→ Updating Home page inside wpcli…" -ForegroundColor Cyan
docker compose run -T --rm wpcli bash -lc "set -e; echo $base64 | base64 -d > /tmp/fix-home.sh && chmod +x /tmp/fix-home.sh && bash /tmp/fix-home.sh"
Ensure-Ok $LASTEXITCODE "Fixing Home failed"

Write-Host "✅ Home page updated. Refresh your site." -ForegroundColor Green
