$ErrorActionPreference = "Stop"

function Run-WP([string]$args) {
  docker compose run -T --rm --user 33:33 wpcli $args
}

Write-Host "Waiting for DB to be ready..."
for ($i=0; $i -lt 30; $i++) {
  docker compose exec -T db mysqladmin ping -h localhost -p$env:DB_PASSWORD --silent 2>$null
  if ($LASTEXITCODE -eq 0) { break }
  Start-Sleep -Seconds 2
}

# 1) wp-config.php
try {
  Run-WP "config path" | Out-Null
  Write-Host "wp-config.php already exists."
} catch {
  Write-Host "Generating wp-config.php..."
  Run-WP "config create --dbname=$env:DB_NAME --dbuser=$env:DB_USER --dbpass=$env:DB_PASSWORD --dbhost=$env:DB_HOST --skip-check --force"
}

# 2) Core install
$siteUrl = $env:WP_SITE_URL
try {
  Run-WP "core is-installed" | Out-Null
  Write-Host "WordPress already installed."
} catch {
  Write-Host "Installing WordPress..."
  Run-WP "core install --url='$siteUrl' --title='WP Dev' --admin_user='$env:ADMIN_USER' --admin_password='$env:ADMIN_PASS' --admin_email='$env:ADMIN_EMAIL'"
}

# 3) Permalinks
Run-WP "rewrite structure '/%postname%/'"
Run-WP "rewrite flush --hard"

# 4) Ensure WPGraphQL + our block plugin are active
Run-WP "plugin install wp-graphql --activate"
Run-WP "plugin activate latest-posts-grid" | Out-Null

# 5) Create 'Home' page with our block (idempotent)
$block = '<!-- wp:lpg/latest-posts-grid {"postsToShow":6,"columns":3,"showExcerpt":true,"showDate":true} /-->'
$homeId = (Run-WP "post list --post_type=page --name='home' --field=ID").Trim()
if (-not $homeId) {
  $homeId = (Run-WP "post create --post_type=page --post_status=publish --post_title='Home' --porcelain --post_content='$block'").Trim()
} else {
  Run-WP "post update $homeId --post_content='$block'" | Out-Null
}

# 6) Set as static front page
Run-WP "option update show_on_front page" | Out-Null
Run-WP "option update page_on_front $homeId" | Out-Null
Run-WP "rewrite flush" | Out-Null

Write-Host ""
Write-Host "Setup complete."
Write-Host "Site:  $siteUrl"
Write-Host "Admin: $siteUrl/wp-admin  ($($env:ADMIN_USER) / $($env:ADMIN_PASS))"
Write-Host "GraphQL endpoint: POST $siteUrl/graphql"
