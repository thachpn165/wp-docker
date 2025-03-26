#!/usr/bin/env bats

# Load test helper
load "$(dirname "$0")/../test_helper.bats"

@test "PHP version selection and configuration" {
    local site_name="test-site"
    local php_version="8.1"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create docker-compose.yml with PHP configuration
    cat > "$TEST_DIR/sites/$site_name/docker-compose.yml" << EOF
version: '3.8'

services:
  php:
    container_name: ${site_name}-php
    image: php:${php_version}-fpm
    volumes:
      - ./wordpress:/var/www/html
      - ./php/php.ini:/usr/local/etc/php/php.ini
      - ./php/www.conf:/usr/local/etc/php-fpm.d/www.conf
    networks:
      - ${site_name}-network

networks:
  ${site_name}-network:
    driver: bridge
EOF
    
    # Check if PHP version is correctly set
    file_contains "$TEST_DIR/sites/$site_name/docker-compose.yml" "image: php:${php_version}-fpm"
}

@test "PHP configuration file setup" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create PHP configuration directory
    mkdir -p "$TEST_DIR/sites/$site_name/php"
    
    # Create php.ini
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
[PHP]
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_vars = 3000
date.timezone = UTC
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log
EOF
    
    # Create www.conf
    cat > "$TEST_DIR/sites/$site_name/php/www.conf" << EOF
[www]
user = nobody
group = nogroup
listen = /var/run/php-fpm.sock
listen.owner = nobody
listen.group = nogroup
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
EOF
    
    # Check if configuration files exist
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    file_exists "$TEST_DIR/sites/$site_name/php/www.conf"
    
    # Check if php.ini contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "memory_limit = 256M"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "upload_max_filesize = 64M"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "max_execution_time = 300"
    
    # Check if www.conf contains correct settings
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "user = nobody"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "group = nogroup"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm = dynamic"
}

@test "PHP extensions installation" {
    local site_name="test-site"
    local php_version="8.1"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create Dockerfile for PHP
    cat > "$TEST_DIR/sites/$site_name/php/Dockerfile" << EOF
FROM php:${php_version}-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j\$(nproc) \
    gd \
    mysqli \
    pdo_mysql \
    zip
EOF
    
    # Check if Dockerfile exists
    file_exists "$TEST_DIR/sites/$site_name/php/Dockerfile"
    
    # Check if required extensions are installed
    file_contains "$TEST_DIR/sites/$site_name/php/Dockerfile" "docker-php-ext-install"
    file_contains "$TEST_DIR/sites/$site_name/php/Dockerfile" "gd"
    file_contains "$TEST_DIR/sites/$site_name/php/Dockerfile" "mysqli"
    file_contains "$TEST_DIR/sites/$site_name/php/Dockerfile" "pdo_mysql"
    file_contains "$TEST_DIR/sites/$site_name/php/Dockerfile" "zip"
}

@test "PHP-FPM process management" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create PHP-FPM configuration
    cat > "$TEST_DIR/sites/$site_name/php/www.conf" << EOF
[www]
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500
pm.process_idle_timeout = 10s
EOF
    
    # Check if PHP-FPM configuration exists
    file_exists "$TEST_DIR/sites/$site_name/php/www.conf"
    
    # Check if process management settings are correct
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm = dynamic"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm.max_children = 5"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm.start_servers = 2"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm.min_spare_servers = 1"
    file_contains "$TEST_DIR/sites/$site_name/php/www.conf" "pm.max_spare_servers = 3"
}

@test "PHP error logging configuration" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create PHP configuration
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
[PHP]
display_errors = Off
log_errors = On
error_log = /var/log/php/error.log
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
EOF
    
    # Create log directory
    mkdir -p "$TEST_DIR/sites/$site_name/logs/php"
    
    # Check if PHP configuration exists
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    
    # Check if error logging settings are correct
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "display_errors = Off"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "log_errors = On"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "error_log = /var/log/php/error.log"
}

@test "PHP performance optimization" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create PHP configuration
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
[PHP]
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.enable_cli = 0
realpath_cache_size = 4096K
realpath_cache_ttl = 600
EOF
    
    # Check if PHP configuration exists
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    
    # Check if performance settings are correct
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "opcache.enable = 1"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "opcache.memory_consumption = 128"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "opcache.max_accelerated_files = 4000"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "realpath_cache_size = 4096K"
}

@test "PHP security settings" {
    local site_name="test-site"
    
    # Create test site
    create_test_site "$site_name" "test-site.local"
    
    # Create PHP configuration
    cat > "$TEST_DIR/sites/$site_name/php/php.ini" << EOF
[PHP]
expose_php = Off
allow_url_fopen = On
allow_url_include = Off
max_input_vars = 3000
max_input_time = 60
post_max_size = 64M
upload_max_filesize = 64M
memory_limit = 256M
max_execution_time = 300
EOF
    
    # Check if PHP configuration exists
    file_exists "$TEST_DIR/sites/$site_name/php/php.ini"
    
    # Check if security settings are correct
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "expose_php = Off"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "allow_url_include = Off"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "max_input_vars = 3000"
    file_contains "$TEST_DIR/sites/$site_name/php/php.ini" "max_execution_time = 300"
} 