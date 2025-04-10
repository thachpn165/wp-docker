#!/bin/bash

# ===============================
# 🧠 wordpress_wp_cli_logic – Execute wp-cli in container
# ===============================
wordpress_wp_cli_logic() {
    local domain="$1"
    shift
    local wp_command="$*"

    if [[ -z "$domain" ]]; then
        print_and_debug error "❌ Missing domain in wordpress_wp_cli_logic"
        return 1
    fi

    local php_container
    php_container=$(json_get_site_value "$domain" "CONTAINER_PHP")

    if [[ -z "$php_container" ]]; then
        print_and_debug error "$ERROR_DOCKER_PHP_CONTAINER_NOT_FOUND: $domain"
        return 1
    fi

    local user="${PHP_USER:-nobody}"

    if ! docker ps --format '{{.Names}}' | grep -q "^$php_container$"; then
        echo -e "${RED}${CROSSMARK} PHP container '$php_container' is not running.${NC}"
        return 1
    fi

    docker exec \
        -e WP_CLI_CACHE_DIR=/tmp/wp-cli-cache \
        -u "$user" \
        "$php_container" \
        wp $wp_command --path=/var/www/html
}