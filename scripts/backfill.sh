#!/usr/bin/env bash
set -euo pipefail
WP="wp --allow-root --path=/var/www/html"

for id in $($WP post list --post_type=post --field=ID); do
  if ! $WP post meta get "$id" _thumbnail_id >/dev/null 2>&1; then
    img="/tmp/backfill-$id.jpg"
    # Try Picsum, fall back to placehold.co
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "https://picsum.photos/seed/backfill-$id/1200/800" -o "$img" \
      || curl -fsSL "https://placehold.co/1200x800/png?text=Post+$id" -o "$img" || true
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "$img" "https://picsum.photos/seed/backfill-$id/1200/800" \
      || wget -qO "$img" "https://placehold.co/1200x800/png?text=Post+$id" || true
    else
      php -r '$u=$argv[1];$o=$argv[2];$d=@file_get_contents($u); if($d===false){exit(1);} file_put_contents($o,$d);' \
        "https://picsum.photos/seed/backfill-$id/1200/800" "$img" \
      || php -r '$u=$argv[1];$o=$argv[2];$d=@file_get_contents($u); if($d===false){exit(1);} file_put_contents($o,$d);' \
        "https://placehold.co/1200x800/png?text=Post+$id" "$img" || true
    fi
    if [ -s "$img" ]; then
      $WP media import "$img" --post_id="$id" --featured_image --porcelain >/dev/null || true
      echo "Set image for post $id"
    fi
  fi
done
