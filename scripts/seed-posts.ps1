# scripts/seed-posts.v2.ps1
# Adds <Count> demo posts with featured images.
# Uses a robust downloader (curl/wget/PHP) + fallback provider to avoid remote import issues.
# Usage:
#   .\scripts\seed-posts.v2.ps1 -Count 16
#   .\scripts\seed-posts.v2.ps1            # defaults to 12

param([int]$Count = 12)

function Ensure-Ok($ExitCode, $Msg) {
  if ($ExitCode -ne 0) { throw $Msg }
}

Write-Host "→ Checking Docker CLI..." -ForegroundColor Cyan
docker version | Out-Null; Ensure-Ok $LASTEXITCODE "Docker is not available."
docker compose version | Out-Null; Ensure-Ok $LASTEXITCODE "Docker Compose is not available."

$BashScript = @'
set -euo pipefail
WP="wp --allow-root --path=/var/www/html"

COUNT=__COUNT__

download_file() {
  url="$1"; out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out" && return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url" && return 0
  fi
  # Fallback to PHP
  php -r '$u=$argv[1];$o=$argv[2];$d=@file_get_contents($u); if($d===false){fwrite(STDERR,\"DL fail\\n\"); exit(1);} file_put_contents($o,$d);' "$url" "$out" && return 0
  return 1
}

echo "Creating $COUNT demo posts with featured images..."
for i in $(seq 1 "$COUNT"); do
  title="Demo Post $i"
  content="This is demo post number $i. It has a featured image for your grid."
  post_id="$($WP post create --post_type=post --post_status=publish --post_title="$title" --post_content="$content" --porcelain)"
  img="/tmp/demo-$i.jpg"

  # Try Picsum first (may redirect). Use curl/wget with -L via curl; wget already follows.
  if ! download_file "https://picsum.photos/seed/demo-$i/1200/800" "$img"; then
    # Fallback to a stable placeholder provider with 200 responses
    download_file "https://placehold.co/1200x800/png?text=Demo+$i" "$img"
  fi

  if [ ! -s "$img" ]; then
    echo "Warning: could not download an image for post $post_id. Skipping featured image."
  else
    $WP media import "$img" --post_id="$post_id" --title="Demo Image $i" --alt="Demo Image $i" --featured_image --porcelain >/dev/null || true
  fi

  echo "Created post $post_id"
done
echo "Done."
'@

$BashScript = $BashScript.Replace("__COUNT__", [string]$Count) -replace "`r`n","`n"
$bytes  = [System.Text.Encoding]::UTF8.GetBytes($BashScript)
$base64 = [Convert]::ToBase64String($bytes)

Write-Host "→ Seeding posts inside wpcli…" -ForegroundColor Cyan
docker compose run -T --rm wpcli bash -lc "set -e; echo $base64 | base64 -d > /tmp/seed.sh && chmod +x /tmp/seed.sh && bash /tmp/seed.sh"
Ensure-Ok $LASTEXITCODE "Seeding failed"

Write-Host "✅ Seeding complete." -ForegroundColor Green
