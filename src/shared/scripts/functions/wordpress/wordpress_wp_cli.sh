#!/bin/bash

# ===============================
# 🧠 wordpress_wp_cli_logic – Execute wp-cli in container
# ===============================
wordpress_wp_cli_logic() {
    local domain="$1"
    shift
    local wp_command="$*"

    local php_container="${domain}-php"

    if ! docker ps --format '{{.Names}}' | grep -q "^$php_container$"; then
        echo -e "${RED}${CROSSMARK} PHP container '$php_container' is not running.${NC}"
        return 1
    fi

    docker exec \
        -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache \
        -u "$PHP_USER" \
        "$php_container" \
        wp $wp_command --allow-root --path=/var/www/html
}