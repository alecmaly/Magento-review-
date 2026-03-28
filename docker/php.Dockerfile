FROM php:8.3-fpm-bookworm

RUN apt-get update && apt-get install -y \
    git curl unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libxml2-dev libxslt-dev libicu-dev libsodium-dev libonig-dev \
    libssl-dev libcurl4-openssl-dev default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) \
        bcmath ctype curl dom ftp gd iconv mbstring \
        opcache pcntl pdo_mysql simplexml soap xsl zip sockets \
 && docker-php-ext-install intl \
 && docker-php-ext-install sodium

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Xdebug — off by default, enabled via XDEBUG_MODE env var
RUN pecl install xdebug && docker-php-ext-enable xdebug

RUN { \
    echo "memory_limit = 2G"; \
    echo "max_execution_time = 1800"; \
    echo "upload_max_filesize = 64M"; \
    echo "post_max_size = 64M"; \
    echo "display_errors = On"; \
    echo "display_startup_errors = On"; \
    echo "error_reporting = E_ALL"; \
    echo "log_errors = On"; \
    echo "error_log = /var/www/html/var/log/php-errors.log"; \
    echo "opcache.enable = 1"; \
    echo "opcache.validate_timestamps = 1"; \
    echo "opcache.revalidate_freq = 0"; \
    echo "opcache.save_comments = 1"; \
    echo "xdebug.mode = \${XDEBUG_MODE}"; \
    echo "xdebug.start_with_request = yes"; \
    echo "xdebug.log_level = 0"; \
} > /usr/local/etc/php/conf.d/magento.ini

WORKDIR /var/www/html
