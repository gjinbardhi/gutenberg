<?php
// /scripts/set-home.php
// Usage: php /scripts/set-home.php <page_id>
// Inserts the custom block on the given page. Tries to detect the block slug from plugin block.json.

if ($argc < 2) {
    fwrite(STDERR, "Usage: php set-home.php <page_id>\n");
    exit(1);
}
$home_id = intval($argv[1]);

require_once '/var/www/html/wp-load.php';

function detect_block_slug() {
    $candidates = [
        '/var/www/html/wp-content/plugins/latest-posts-grid/block.json',
        '/var/www/html/wp-content/plugins/latest-posts-grid/build/block.json',
        '/var/www/html/wp-content/plugins/latest-posts-grid/src/block.json',
    ];
    foreach ($candidates as $file) {
        if (file_exists($file)) {
            $json = json_decode(file_get_contents($file), true);
            if (isset($json['name']) && is_string($json['name'])) {
                return $json['name'];
            }
        }
    }
    // Fallback to create-block default
    return 'create-block/latest-posts-grid';
}

$slug = detect_block_slug();
// Minimal block with an attribute example; adjust as your block expects
$content = sprintf('<!-- wp:%s {"postsToShow":6} /-->', esc_html($slug));

$postarr = [
    'ID'           => $home_id,
    'post_content' => $content,
];
wp_update_post($postarr);
echo "Inserted block ($slug) on page ID $home_id\n";
