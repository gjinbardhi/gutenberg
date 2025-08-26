<?php
/**
 * Plugin Name: Latest Posts Grid (Gutenberg + GraphQL + Tailwind)
 * Description: A Gutenberg block that fetches latest posts via WPGraphQL and renders a responsive grid.
 * Version: 1.0.0
 * Author: You
 */

if ( ! defined( 'ABSPATH' ) ) exit;

add_action( 'init', function () {

    // IMPORTANT: Point to the plugin root where block.json lives.
    register_block_type( __DIR__, [
        'render_callback' => function( $attrs, $content, $block ) {

            $postsToShow = isset( $attrs['postsToShow'] ) ? (int) $attrs['postsToShow'] : 6;
            $columns     = isset( $attrs['columns'] )     ? (int) $attrs['columns']     : 3;
            $showExcerpt = ! empty( $attrs['showExcerpt'] );
            $showDate    = ! empty( $attrs['showDate'] );

            // Hard caps and sane defaults
            $props = [
                'postsToShow' => max( 1, min( 12, $postsToShow ) ),
                'columns'     => max( 1, min( 6,  $columns ) ),
                'showExcerpt' => (bool) $showExcerpt,
                'showDate'    => (bool) $showDate,
                'endpoint'    => esc_url_raw( home_url( '/graphql' ) ),
            ];

            $data = esc_attr( wp_json_encode( $props ) );

            // Server-side wrapper so HTML is always in the page.
            $html  = '<div class="wp-block-lpg-latest-posts-grid" data-props="' . $data . '">';
            $html .= '  <div class="lpg-grid" aria-busy="true" aria-live="polite"></div>';
            $html .= '</div>';
            return $html;
        },
    ] );
} );

// Expose GraphQL endpoint to both editor + view scripts.
add_action( 'enqueue_block_assets', function () {
    $endpoint = esc_url( home_url( '/graphql' ) );
    foreach ( [ 'lpg-latest-posts-grid-editor-script', 'lpg-latest-posts-grid-view-script' ] as $h ) {
        if ( wp_script_is( $h, 'registered' ) ) {
            wp_localize_script( $h, 'GBLatestPostsGrid', [ 'graphqlEndpoint' => $endpoint ] );
        }
    }
} );
