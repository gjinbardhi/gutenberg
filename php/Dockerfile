# Build args with safe defaults
ARG WORDPRESS_VERSION=6.6
ARG PHP_TAG=php8.2-fpm

FROM wordpress:${WORDPRESS_VERSION}-${PHP_TAG}

# Install helpful extensions & tools
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        less vim unzip git libzip-dev libicu-dev libc-client-dev libkrb5-dev; \
    docker-php-ext-install zip intl; \
    rm -rf /var/lib/apt/lists/*

# Composer (from official image)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# PHP ini tweaks & xdebug (on demand via XDEBUG_MODE)
RUN printf "%s\n" \
  "memory_limit=256M" \
  "upload_max_filesize=64M" \
  "post_max_size=64M" \
  "max_execution_time=300" \
  > /usr/local/etc/php/conf.d/z-custom.ini

# Xdebug config (extension already present in base image)
COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
